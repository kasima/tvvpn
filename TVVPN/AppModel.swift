//
//  AppModel.swift
//  TVVPN
//
//  Created by kasima on 2/7/23.
//

import Foundation
final class AppModel: ObservableObject {
    @Published var loading: Bool = false
    @Published var connected: Bool = false
    
    public func getStatus() {
        
    }
    
    public func toggleConnection() {
        
    }
}
