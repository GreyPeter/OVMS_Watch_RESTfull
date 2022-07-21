//
//  OVMS_Watch_RESTfullApp.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import SwiftUI

@main
struct OVMS_Watch_RESTfullApp: App {
    @StateObject private var model = ServerData.shared
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(model: model)
            }
        }
    }
}
