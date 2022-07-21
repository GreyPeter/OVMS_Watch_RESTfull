//
//  ContentView.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model: ServerData
    var body: some View {
        GeometryReader { watchGeo in
            VStack {
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
