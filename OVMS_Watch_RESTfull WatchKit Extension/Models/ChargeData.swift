//
//  ChargeData.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import Foundation
struct Charge: Decodable {
    var battvoltage: String
    var cac100: String
    var carawake: Int
    var caron: Int
    var charge_estimate: String
    var charge_etr_full: String
    var charge_etr_limit: String
    var charge_etr_range: String
    var charge_etr_soc: String
    var charge_limit_range: String
    var charge_limit_soc: String
    var chargeb4: String
    var chargecurrent: String
    var chargeduration: String
    var chargekwh: String
    var chargelimit: String
    var chargepower: String
    var chargepowerinput: String
    var chargerefficiency: String
    var chargestarttime: String
    var chargestate: String
    var chargesubstate: String
    var chargetimermode: String
    var chargetimerstale: String
    var chargetype: String
    var charging: Int
    var charging_12v: Int
    var cooldown_active: String
    var cooldown_tbattery: String
    var cooldown_timelimit: String
    var cp_dooropen: Int
    var estimatedrange: String
    var idealrange: String
    var idealrange_max: String
    var linevoltage: String
    var m_msgage_d: Int
    var m_msgage_s: Int
    var m_msgtime_d: String
    var m_msgtime_s: String
    var mode: String
    var pilotpresent: Int
    var soc: String
    var soh: String
    var staleambient: String
    var staletemps: String
    var temperature_ambient: String
    var temperature_battery: String
    var temperature_cabin: String
    var temperature_charger: String
    var temperature_motor: String
    var temperature_pem: String
    var units: String
    var vehicle12v: String
    var vehicle12v_current: String
    var vehicle12v_ref: String
    
    static let initial = Charge(battvoltage: "0", cac100: "0", carawake: 0, caron: 0, charge_estimate: "0", charge_etr_full: "0", charge_etr_limit: "0", charge_etr_range: "0", charge_etr_soc: "0", charge_limit_range: "0", charge_limit_soc: "0", chargeb4: "0", chargecurrent: "0", chargeduration: "0", chargekwh: "0", chargelimit: "0", chargepower: "0", chargepowerinput: "0", chargerefficiency: "0", chargestarttime: "0", chargestate: "stopped", chargesubstate: "0", chargetimermode: "0", chargetimerstale: "0", chargetype: "0", charging: 0, charging_12v: 0, cooldown_active: "0", cooldown_tbattery: "0", cooldown_timelimit: "0", cp_dooropen: 0, estimatedrange: "0", idealrange: "0", idealrange_max: "0", linevoltage: "0", m_msgage_d: 0, m_msgage_s: 0, m_msgtime_d: "0", m_msgtime_s: "0", mode: "0", pilotpresent: 0, soc: "0", soh: "0", staleambient: "0", staletemps: "0", temperature_ambient: "0", temperature_battery: "0", temperature_cabin: "0", temperature_charger: "0", temperature_motor: "0", temperature_pem: "0", units: "0", vehicle12v: "0", vehicle12v_current: "0", vehicle12v_ref: "0")
    
    static let dummy = Charge(battvoltage: "397.00", cac100: "0.00", carawake: 0, caron: 0, charge_estimate: "0", charge_etr_full: "0", charge_etr_limit: "0", charge_etr_range: "0", charge_etr_soc: "0", charge_limit_range: "100", charge_limit_soc: "80", chargeb4: "0", chargecurrent: "0.10", chargeduration: "0", chargekwh: "4", chargelimit: "0", chargepower: "0.00", chargepowerinput: "0.00", chargerefficiency: "0.00", chargestarttime: "0", chargestate: "stopped", chargesubstate: "0", chargetimermode: "0", chargetimerstale: "0", chargetype: "0", charging: 0, charging_12v: 0, cooldown_active: "0", cooldown_tbattery: "0", cooldown_timelimit: "0", cp_dooropen: 0, estimatedrange: "114", idealrange: "112", idealrange_max: "263", linevoltage: "0", m_msgage_d: 2, m_msgage_s: 2, m_msgtime_d: "2022-03-31 04:18:17", m_msgtime_s: "2022-03-31 04:18:17", mode: "standard", pilotpresent: 0, soc: "42.8", soh: "100", staleambient: "0", staletemps: "0", temperature_ambient: "28.8", temperature_battery: "26", temperature_cabin: "22.2", temperature_charger: "0", temperature_motor: "38", temperature_pem: "38", units: "K", vehicle12v: "12.74", vehicle12v_current: "0", vehicle12v_ref: "12.81")
}

extension Charge {
    
    func getCharge() async -> Charge {
        var value = Charge.initial
        var request: URLRequest
        if let url = URL(string: getURL(for: Endpoint.charge)!) {
            request = URLRequest(url: url)
            do {
                let ( data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let decodedResponse = try? JSONDecoder().decode(Charge.self, from: data) {
                            value = decodedResponse
                            print("(getCharge) SOC: \(value.soc) @ \(Date.now.formatted(date: .omitted, time: .standard))")
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
