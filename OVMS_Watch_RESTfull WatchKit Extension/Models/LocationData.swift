//
//  LocationData.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import Foundation

struct Location: Decodable {
    var altitude: String
    var direction: String
    var drivemode: String
    var energyrecd: String
    var energyused: String
    var gpslock: String
    var invefficiency: String
    var invpower: String
    var latitude: String
    var longitude: String
    var m_msgage_l: Int
    var m_msgtime_l: String
    var power: String
    var speed: String
    var stalegps: String
    var tripmeter: String
    
    static let dummy = Location(altitude:"-0.1",direction:"41.4",drivemode:"0",energyrecd:"0.512",energyused:"0.900",gpslock:"1",invefficiency:"0",invpower:"0",latitude:"-27.708397",longitude:"153.216858",m_msgage_l:28,m_msgtime_l:"2022-03-05 23:26:47",power:"0.000",speed:"0.0",stalegps:"1",tripmeter:"0")
    
    static let initial = Location(altitude: "", direction: "", drivemode: "", energyrecd: "", energyused: "", gpslock: "", invefficiency: "", invpower: "", latitude: "", longitude: "", m_msgage_l: 0, m_msgtime_l: "", power: "", speed: "", stalegps: "", tripmeter: "")
    }

extension Location {
    func getLocation() async -> Location {
        var value = Location.initial
        var request: URLRequest
        if let url = URL(string: getURL(for: Endpoint.location)!) {
            request = URLRequest(url: url)
            do {
                let ( data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let decodedResponse = try? JSONDecoder().decode(Location.self, from: data) {
                            value = decodedResponse
                            print("(getLocation) latitude: \(value.latitude) longitude: \(value.longitude) @ \(Date.now.formatted(date: .omitted, time: .standard))")
                        }
                        return value
                    }
                }
                return value
            }
            catch {
                return value
            }
        }
        return value
    }
}
