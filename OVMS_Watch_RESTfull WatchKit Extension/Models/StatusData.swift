//
//  StatusData.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import Foundation

struct Status: Decodable {
    var alarmsounding: Int
    var bt_open: Int
    var cac100: String
    var carawake: Int
    var carlocked: Int
    var caron: Int
    var chargestate: String
    var charging: Int
    var charging_12v: Int
    var cooldown_active: String
    var cp_dooropen: Int
    var estimatedrange: String
    var fl_dooropen: Int
    var fr_dooropen: Int
    var handbrake: Int
    var idealrange: String
    var idealrange_max: String
    var m_msgage_d: Int
    var m_msgage_s: Int
    var m_msgtime_d: String
    var m_msgtime_s: String
    var mode: String
    var odometer: String
    var parkingtimer: String
    var pilotpresent: Int
    var soc: String
    var soh: String
    var speed: String
    var staleambient: String
    var staletemps: String
    var temperature_ambient: String
    var temperature_battery: String
    var temperature_cabin: String
    var temperature_charger: String
    var temperature_motor: String
    var temperature_pem: String
    var tr_open: Int
    var tripmeter: String
    var units: String
    var valetmode: Int
    var vehicle12v: String
    var vehicle12v_current: String
    var vehicle12v_ref: String
    static let dummy = Status(alarmsounding: 0, bt_open: 0, cac100: "0.00", carawake: 0, carlocked: 0, caron: 0, chargestate: "stopped", charging: 0, charging_12v: 0, cooldown_active: "-1", cp_dooropen: 0, estimatedrange: "172", fl_dooropen: 0, fr_dooropen: 0, handbrake: 64, idealrange: "169", idealrange_max: "263", m_msgage_d: 137, m_msgage_s: 137, m_msgtime_d: "2022-03-05 23:16:46", m_msgtime_s: "2022-03-05 23:16:46", mode: "standard", odometer: "149220", parkingtimer: "248032", pilotpresent: 8, soc: "64.4", soh: "100", speed: "0", staleambient: "0", staletemps: "0", temperature_ambient: "32", temperature_battery: "28", temperature_cabin: "31", temperature_charger: "0", temperature_motor: "42", temperature_pem: "44", tr_open: 0, tripmeter: "0", units: "K", valetmode: 0, vehicle12v: "12.47", vehicle12v_current: "0", vehicle12v_ref: "12.82")
    static let initial = Status(alarmsounding: 0, bt_open: 0, cac100: "", carawake: 0, carlocked: 0, caron: 0, chargestate: "", charging: 0, charging_12v: 0, cooldown_active: "", cp_dooropen: 0, estimatedrange: "", fl_dooropen: 0, fr_dooropen: 0, handbrake: 0, idealrange: "", idealrange_max: "", m_msgage_d: 0, m_msgage_s: 0, m_msgtime_d: "", m_msgtime_s: "", mode: "", odometer: "", parkingtimer: "", pilotpresent: 0, soc: "", soh: "", speed: "", staleambient: "", staletemps: "", temperature_ambient: "", temperature_battery: "", temperature_cabin: "", temperature_charger: "", temperature_motor: "", temperature_pem: "", tr_open: 0, tripmeter: "", units: "", valetmode: 0, vehicle12v: "", vehicle12v_current: "", vehicle12v_ref: "")
}

extension Status {
    
    func getStatus() async -> Status {
        var value = Status.initial
        var request: URLRequest
        if let url = URL(string: getURL(for: Endpoint.status)!) {
            request = URLRequest(url: url)
            do {
                let ( data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let decodedResponse = try? JSONDecoder().decode(Status.self, from: data) {
                            value = decodedResponse
                            //print("(getStatus) SOC: \(value.soc) @ \(Date.now.formatted(date: .omitted, time: .standard))")
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
