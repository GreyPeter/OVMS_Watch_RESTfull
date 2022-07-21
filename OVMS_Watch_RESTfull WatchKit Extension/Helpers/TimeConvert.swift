//
//  TimeConvert.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import Foundation

func timeConvert(time: String) -> String {
    guard let intTime = Int(time) else { return "--:--" }
    if intTime <= 0 {
        return "--:--"
    }
    return String(format: "%d:%02d",(Int(time) ?? 0)/60,(Int(time) ?? 0)%60)
}
