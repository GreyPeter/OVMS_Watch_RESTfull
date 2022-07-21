//
//  Vehicles.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import SwiftUI

struct Vehicles: View {
    @StateObject var model: ServerData
    @State var vehicles: [Vehicle]
    @State var userName: String = ""
    @State var password: String = ""
    
    @State private var oldUsername = ""
    @State private var isPresentingSettingsView = false
    var body: some View {
        let keyChainService = KeychainService()
        
        NavigationView {
            VStack {
                Button(action: {
                    userName = userName
                    oldUsername = userName
                    password = keyChainService.retrievePassword(for: userName) ?? ""
                    isPresentingSettingsView = true
                }) {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                //.accessibilityLabel("New Vehicle")
                
                List(vehicles) { vehicle in
                    HStack {
                        Image(systemName: "car")
                        Text(vehicle.id)
                    }
                }
                Spacer()
                Button("Delete Tokens") {
                    Task {
                        currentToken.delTokens()
                    }
                }
            }
            .sheet(isPresented: $isPresentingSettingsView) {
                NavigationView {
                    Settings(userName: $userName, password: $password)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Dismiss") {
                                    isPresentingSettingsView = false
                                    oldUsername = userName
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    print("User: \(userName) Old: \(oldUsername) Password: \(password)")
                                    // Check if userName has changed.
                                    //If so update delete old password entry for username
                                    if userName != oldUsername {
                                        do {
                                            try keyChainService.deletePasswordFor(for:oldUsername)
                                        } catch {
                                            print(error)
                                        }
                                        //Save new password for updataed userName
                                        keyChainService.save(password, for: userName)
                                        userName = userName
                                    } else {
                                        // userName has not changed so only the password remains
                                        if let oldPassword = keyChainService.retrievePassword(for: userName)
                                        {
                                            if password != oldPassword {
                                                do {
                                                    try keyChainService.updatePasswordFor(user: userName, password: password)
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        } else {
                                            keyChainService.save(password, for: userName)
                                        }
                                        
                                    }
                                    isPresentingSettingsView = false
                                    let defaults = UserDefaults.standard
                                    defaults.set(userName, forKey: "username")
                                }
                            }
                        }
                }
            }
            
        }
    }
}

struct Vehicles_Previews: PreviewProvider {
    static var previews: some View {
        Vehicles(model: ServerData(), vehicles: Vehicle.dummy)
    }
}
