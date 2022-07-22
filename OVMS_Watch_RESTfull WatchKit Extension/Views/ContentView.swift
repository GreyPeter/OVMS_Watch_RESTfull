//
//  ContentView.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model: ServerData
    @Environment(\.scenePhase) var scenePhase
    var body: some View {
        let duration = Int(model.charge.chargeduration) ?? 0
        let chgkwh =  (Float(model.charge.chargekwh) ?? 0.0)
        GeometryReader { watchGeo in
            VStack {
                NavigationLink(
                    destination: Vehicles(model: model, vehicles: vehicles),
                    label: {
                        Image(systemName: "car")
                        Text(vehicles[0].id)
                            .font(.caption2)
                    })
                .frame(width: watchGeo.size.width * 0.79, height: watchGeo.size.height * 0.14)
                .padding()
                .task {
                    await currentToken.getToken()
                    await model.getVehicle()
                    model.charge = await model.charge.getCharge()
                    model.chargePercent = Double(model.charge.soc) ?? 0.0
                    print("Charge % = \(model.chargePercent)")
                    if model.charge.charging == 0 {
                        model.mode = model.charge.caron == 0 ? .idle : .driving
                    } else {
                        model.mode = .charging
                    }
                    model.startBackgroundDownload(refreshInterval: 0)
                }
                Image("battery_000")
                    .resizable()
                    .scaledToFit()
                    .frame(width: watchGeo.size.width * 0.9, height: watchGeo.size.height * 0.3, alignment: .center)
                    .frame(width: watchGeo.size.width, height: watchGeo.size.height * 0.3, alignment: .center)
                    .overlay(ProgressBar(value: model.chargePercent,
                                         maxValue: 100,
                                         backgroundColor: .clear,
                                         foregroundColor: color(forChargeLevel: model.chargePercent)
                                        )
                        .frame(width: watchGeo.size.width * 0.7, height: watchGeo.size.height * 0.25)
                        .frame(width: watchGeo.size.width, height: watchGeo.size.height * 0.25)
                        .opacity(0.6)
                        .padding(0)
                    )
                    .overlay(
                        VStack {
                            Text("\(model.mode == .charging ? model.charge.soc : model.status.soc)%      \(model.currMode)")
                                .fontWeight(.bold)
                                .foregroundColor(Color.white)
                            Text("\(model.mode == .charging ? model.charge.estimatedrange : model.status.estimatedrange)\(model.mode == .charging ? model.charge.units : model.status.units)")
                                .fontWeight(.bold)
                                .foregroundColor(Color.white)
                        }
                            .background(Color.clear)
                            .opacity(0.9))
                switch model.mode {
                case .charging:
                    SubView(Text1: "Full", Data1: timeConvert(time: model.charge.charge_etr_full), Text2: "\(model.charge.charge_limit_soc)%", Data2: timeConvert(time: model.charge.charge_etr_soc), Text3: "\(model.charge.charge_limit_range)\(model.charge.units)", Data3: timeConvert(time: model.charge.charge_etr_range), Text4: "Dur", Data4: timeConvert(time: "\(duration/60)"), Text5: "kWh", Data5: String(format:"%0.1f",chgkwh / 10), Text6: "@ kW", Data6: model.charge.chargepower)
                case .driving:
                    SubView(Text1: "Speed", Data1: model.location.speed, Text2: "PWR", Data2: model.location.power, Text3: "Trip", Data3: model.location.tripmeter, Text4: "Rxed", Data4: model.location.energyrecd, Text5: "Used", Data5: model.location.energyused, Text6: "Mode", Data6: model.location.drivemode)
                default:
                    SubView(Text1: "Motor", Data1: "\(model.status.temperature_motor)°", Text2: "Batt", Data2: "\(model.status.temperature_battery)°", Text3: "PEM", Data3: "\(model.status.temperature_pem)°", Text4: "Amb", Data4: "\(model.status.temperature_ambient)°", Text5: "Cabin", Data5: "\(model.status.temperature_cabin)°", Text6: "12V", Data6: model.status.vehicle12v)
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .active {
                print("Active")
                model.startBackgroundDownload(refreshInterval: 0)
            } else if newPhase == .background {
                print("Background")
                let currentSOC = model.mode == .charging ? model.charge.soc : model.status.soc
                print("Current SOC = \(currentSOC)")
                updateComplications(soc: currentSOC)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let model = ServerData()
    static var previews: some View {
        return Group {
            ContentView(model: model)
                .previewDevice("Apple Watch Series 3 - 38mm")
            ContentView(model: model)
                .previewDevice("Apple Watch Series 5 - 40mm")
            ContentView(model: model)
                .previewDevice("Apple Watch Series 7 - 45mm")
        }
    }
}
