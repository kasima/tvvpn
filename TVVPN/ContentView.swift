//
//  ContentView.swift
//  TVVPN
//
//  Created by kasima on 2/7/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        VStack {
            Image(systemName: appModel.connected ? "checkmark.icloud.fill" : "icloud.slash")
                .font(.system(size: 60))
                .padding()
            
            Button {
                appModel.toggleConnection()
            } label: {
                Text(appModel.connected ? "Disconnect VPN" : "Connect VPN")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppModel())
    }
}
