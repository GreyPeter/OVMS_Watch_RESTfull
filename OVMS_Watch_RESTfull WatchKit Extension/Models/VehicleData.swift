//
//  VehicleData.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import Foundation

struct Vehicle: Decodable, Identifiable {
    var id: String
    var v_apps_connected: Int
    var v_btcs_connected: Int
    var v_net_connected: Int
    
    static let initial: [Vehicle] = [Vehicle(id: "", v_apps_connected: 0, v_btcs_connected: 0, v_net_connected: 0)]
    
    static let dummy: [Vehicle] =
    [Vehicle(id: "No Password", v_apps_connected: 0, v_btcs_connected: 0, v_net_connected: 1),
     Vehicle(id: "Home", v_apps_connected: 0, v_btcs_connected: 0, v_net_connected: 1)]
    
}
