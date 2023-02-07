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
    let loginPath = "login"
    let statusPath = "vpnstatus.cgi"
    let togglePath = "service.cgi"

    let username = "admin"

    @Published var loading: Bool = false
    @Published var connected: Bool = false
    
    private let session: Session = {
        let manager = ServerTrustManager(evaluators: ["192.168.1.1": DisabledTrustEvaluator()])
        let redirector = Redirector(behavior: .doNotFollow)
        let configuration = URLSessionConfiguration.af.default
        return Session(configuration: configuration, serverTrustManager: manager, redirectHandler: redirector)
    }()
    
    public func getStatus() {
        let parameters: [String: String] = [
            "client": "1",
            "_http_id": "TIDedd63e08e80c7be2"
        ]
        loading = true
        session.request(routerURL + statusPath, method: .post, parameters: parameters)
            .authenticate(username: username, password: password)
            .responseString { response in
                debugPrint(response)

                switch response.result {
                case .success:
                    self.connected = true
                case .failure:
                    // When VPN is not connected, response is zero length body, which results in serialization failure
                    self.connected = false
                }
                self.loading = false
            }
    }
    
    public func toggleConnection() {
        let parameters: [String: String] = [
            // "_redirect": "vpn-client.asp",
            // "_sleep": "3",
            "_service": self.connected ? "vpnclient1-stop" : "vpnclient1-start",
            "_http_id": "TIDedd63e08e80c7be2"
        ]
        session.request(routerURL + togglePath, method: .post, parameters: parameters)
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
            }
    }
}
