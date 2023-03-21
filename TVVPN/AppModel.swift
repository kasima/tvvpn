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
        self.loading = true
        loadPassword()

        Task { @MainActor in
            do {
                self.connected = try await getStatus()
                self.serverAddress = try await getCurrentServer()
            } catch {
                debugPrint("Error: \(error)")

            }
            self.loading = false
        }
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

    public func getStatus() async throws -> Bool {
        let parameters: [String: String] = [
            "_http_id": httpID,
            "client": "1"
        ]
        let request = session.request(routerURL + statusPath, method: .post, parameters: parameters)
            .authenticate(username: username, password: password)
            .serializingString()
        let response = await request.response
        debugPrint(response)

        let statusCode = response.response?.statusCode
        if statusCode == 200 {
            // When VPN is not connected, response is nil body
            return response.data != nil
        } else {
            return false
        }
    }

    public func getCurrentServer() async throws -> String {
        let parameters: [String: String] = [
            "_http_id": httpID,
            "action": "execute",
            "nojs": "1",
            "working_dir": "/www",
            "command": "nvram get vpn_client1_addr"
        ]
        let request = session.request(routerURL + shellPath, method: .post, parameters: parameters)
            .authenticate(username: username, password: password)
            .serializingString()
        let response = await request.response
        debugPrint(response)

        return response.value ?? ""
    }

    public func getSuggestedServer() async throws -> String {
        let url = "https://api.nordvpn.com/v1/servers/recommendations?filters[country_id]=\(countryId)&limit=1"
        let request = AF.request(url).serializingData()
        let response = await request.response
        switch response.result {
        case .success(let data):
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
               let serverAddress = json.first?["hostname"] as? String {
                return serverAddress
            } else {
                return ""
            }
        case .failure:
            return ""
        }
    }

    public func updateVPNClientAddress(serverAddress: String) async throws {
        let url = routerURL + nvramUpdatePath
        let parameters: [String: String] = [
            "_ajax": "1",
            "vpn_client1_addr": serverAddress,
            "_http_id": httpID
        ]
        let request = session.request(url, method: .post, parameters: parameters)
            .authenticate(username: username, password: password)
            .serializingData()
        let response = await request.response
        switch response.result {
        case .success:
            print("Successfully updated")
        case .failure:
            throw NSError(domain: "getVPNClientParameters", code: -1, userInfo: nil)
        }
    }

    public func vpnConnection(start: Bool) async throws -> Bool {
        let toggleParameters: [String: String] = [
            "_http_id": httpID,
            "_service": start ? "vpnclient1-start" : "vpnclient1-stop"
        ]
        let request = session.request(routerURL + togglePath, method: .post, parameters: toggleParameters)
            .authenticate(username: username, password: password)
            .serializingString()
        let response = await request.response
        debugPrint(response)

        switch response.result {
        case .success:
            let statusCode = response.response?.statusCode
            if statusCode == 302 {
                return true
            }
        case .failure:
            debugPrint("Error")
        }
        return false
    }

    public func toggleConnection() {
        loading = true

        Task { @MainActor in
            do {
                if !connected {
                    self.serverAddress = try await self.getSuggestedServer()
                    try await self.updateVPNClientAddress(serverAddress: self.serverAddress)
                    self.connected = try await self.vpnConnection(start: true)
                } else {
                    self.connected = try await !self.vpnConnection(start: false)
                }
            } catch {
                debugPrint(error)
            }
            self.loading = false
        }
    }
}
