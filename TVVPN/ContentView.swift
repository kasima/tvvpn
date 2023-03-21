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
                        .frame(minHeight: 100)
                } else {
                    Image(systemName: appModel.connected ? "checkmark.icloud.fill" : "icloud.slash")
                        .font(.system(size: 60))
                        .frame(minHeight: 100)
                }

                Button(action: {
                    appModel.toggleConnection()
                }) {
                    Text(appModel.connected ? "Disconnect from 🇨🇭" : "Connect to 🇨🇭")
                        .font(.title)
                        //                    .frame(maxWidth: .infinity)
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
