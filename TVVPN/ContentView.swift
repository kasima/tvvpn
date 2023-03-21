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
        ZStack {
            Color(UIColor.systemGray6)
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Image(systemName: "tv")
                    Text("TV VPN")
                }
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

                Spacer()

                if appModel.loading {
                    ProgressView()
                        .frame(height: 100)
                    Text("Doing stuff...")
                        .font(.caption)
                } else {
                    Image(systemName: appModel.connected ? "checkmark.icloud.fill" : "icloud.slash")
                        .font(.system(size: 60))
                        .frame(height: 100)

                    if appModel.connected {
                        if appModel.serverAddress == "" {
                            Text("Connected")
                                .font(.caption)
                        } else {
                            Text("Connected to \(appModel.serverAddress)")
                                .font(.caption)
                        }
                    } else {
                        Text("Not connected")
                            .font(.caption)
                    }
                }

                Button(action: {
                    appModel.toggleConnection()
                }) {
                    Text(appModel.connected ? "Disconnect from 🇨🇭" : "Connect to 🇨🇭")
                        .font(.title)
                        // .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.bold)
                }
                .padding()
                .disabled(appModel.loading)

                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environmentObject(AppModel())
            
            ContentView()
                .environmentObject(AppModel(loading: false, connected: true))
       }
    }
}
