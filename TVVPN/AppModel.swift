//
//  AppModel.swift
//  TVVPN
//
//  Created by kasima on 2/7/23.
//

import Foundation
import Alamofire

final class AppModel: ObservableObject {
    let routerURL = "https://192.168.1.1/"
    let statusPath = "vpnstatus.cgi"
    let shellPath = "shell.cgi"
    let nvramUpdatePath = "tomato.cgi"
    let togglePath = "service.cgi"

    // TODO – pull this session ID from the source in the script section: nvram["_http_id"]
    let httpID = "TIDedd63e08e80c7be2"

    let countryId = 209  // Switzerland

    let username = "admin"
    var password = ""

    @Published var loading: Bool
    @Published var connected: Bool
    @Published var serverAddress = ""
    
    private let session: Session = {
        let manager = ServerTrustManager(evaluators: ["192.168.1.1": DisabledTrustEvaluator()])
        let redirector = Redirector(behavior: .doNotFollow)
        let configuration = URLSessionConfiguration.af.default
        return Session(configuration: configuration, serverTrustManager: manager, redirectHandler: redirector)
    }()
    
    init(loading: Bool = true, connected: Bool = false) {
        self.loading = loading
        self.connected = connected
    }

    public func loadStuff() {
        loadPassword()
        getStatus()
    }

    private func loadPassword() {
        let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist")
        if let path = url?.path, let data = FileManager.default.contents(atPath: path) {
            do {
                let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
                guard let secrets = plist as? [String: String] else {
                    return
                }
                self.password = secrets["password"]!
                debugPrint(self.password)
            } catch {
                print("Error reading regions plist file: \(error)")
                return
            }
            
        }
    }
    
    public func getStatus() {
        let parameters: [String: String] = [
            // TODO – pull this session ID from the source in the script section: nvram["_http_id"]
            "_http_id": httpID,
            "client": "1"
        ]
        loading = true
        session.request(routerURL + statusPath, method: .post, parameters: parameters)
            .authenticate(username: username, password: password)
            .response { response in
                debugPrint(response)

                switch response.result {
                case .success(let data):
                    let statusCode = response.response?.statusCode
                    if statusCode == 200 {
                        // When VPN is not connected, response is nil body
                        self.connected = data != nil
                        self.getServer()
                    } else {
                        self.connected = false
                    }
                case .failure:
                    debugPrint("Error")
                }
                self.loading = false
            }
    }

    public func getServer() {
        let parameters: [String: String] = [
            "_http_id": httpID,
            "action": "execute",
            "nojs": "1",
            "working_dir": "/www",
            "command": "nvram get vpn_client1_addr"
        ]
        loading = true
        session.request(routerURL + shellPath, method: .post, parameters: parameters)
            .authenticate(username: username, password: password)
            .responseString { response in
                debugPrint(response)

                switch response.result {
                case .success(let body):
                    self.serverAddress = body
                case .failure:
                    debugPrint("Error")
                }
                self.loading = false
            }
    }

    public func getSuggestedServer(completion: @escaping (String?) -> Void) {
        let url = "https://api.nordvpn.com/v1/servers/recommendations?filters[country_id]=\(countryId)&limit=1"
        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                       let serverAddress = json.first?["hostname"] as? String {
                        completion(serverAddress)
                    } else {
                        completion(nil)
                    }
                } catch {
                    completion(nil)
                }
            case .failure:
                completion(nil)
            }
        }
    }

    public func updateVPNClientAddress(serverAddress: String, completion: @escaping (Bool) -> Void) {
        // Replace this with the appropriate API call to update the server address for the VPN client
        let url = routerURL + nvramUpdatePath
        let parameters: [String: String] = [
            "_ajax": "1",
            "vpn_client1_addr": serverAddress,
            "_http_id": httpID
        ]
        session.request(url, method: .post, parameters: parameters)
            .authenticate(username: username, password: password)
            .response { response in
                if response.error == nil {
                    completion(true)
                } else {
                    completion(false)
                }
            }
    }

    public func vpnConnection(start: Bool) {
        let toggleParameters: [String: String] = [
            "_http_id": httpID,
            "_service": start ? "vpnclient1-start" : "vpnclient1-stop"
        ]
        session.request(routerURL + togglePath, method: .post, parameters: toggleParameters)
            .authenticate(username: username, password: password)
            .responseString { response in
                debugPrint(response)

                switch response.result {
                case .success:
                    let statusCode = response.response?.statusCode
                    if statusCode == 302 {
                        self.connected = !self.connected
                    }
                case .failure:
                    debugPrint("Error")
                }
                self.loading = false
            }
    }

    public func toggleConnection() {
        loading = true
        if !connected {
            getSuggestedServer { serverAddress in
                guard let serverAddress = serverAddress else {
                    debugPrint("Error fetching suggested server")
                    self.loading = false
                    return
                }
                self.serverAddress = serverAddress
                self.updateVPNClientAddress(serverAddress: serverAddress) { success in
                    if success {
                        self.vpnConnection(start: true)
                    } else {
                        debugPrint("Error updating server address")
                        self.loading = false
                    }
                }
            }
        } else {
            self.vpnConnection(start: false)
        }
    }

    // public func toggleConnection() {
    //     loading = true
    //     let parameters: [String: String] = [
    //         // "_redirect": "vpn-client.asp",
    //         // "_sleep": "3",
    //         "_http_id": httpID,
    //         "_service": self.connected ? "vpnclient1-stop" : "vpnclient1-start"
    //     ]
    //     session.request(routerURL + togglePath, method: .post, parameters: parameters)
    //         .authenticate(username: username, password: password)
    //         .responseString { response in
    //             debugPrint(response)
    //
    //             switch response.result {
    //             case .success:
    //                 let statusCode = response.response?.statusCode
    //                 if statusCode == 302 {
    //                     self.connected = !self.connected
    //                 }
    //             case .failure:
    //                 debugPrint("Error")
    //             }
    //             self.loading = false
    //         }
    // }

}
