//
//  TVVPNApp.swift
//  TVVPN
//
//  Created by kasima on 2/7/23.
//

import SwiftUI

@main
struct TVVPNApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .onAppear {
                    appModel.loadStuff()
                }
        }
    }
}
