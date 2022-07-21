//
//  ComplicationsView.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import SwiftUI
import ClockKit

struct ComplicationViewCircular: View {
    @StateObject var model: ServerData
    
    var body: some View {
        let chargePercent = model.chargePercent
        let rounded = String(Int(chargePercent.rounded()))
        
        ZStack {
            ProgressView(
                rounded,
                value: chargePercent,
                total: 100.0)
                .progressViewStyle(
                    CircularProgressViewStyle(tint: color(forChargeLevel: chargePercent.rounded())))
        }
        .onAppear {
            print("Circular Appeared")
        }
    }
}

struct ComplicationGraphicCornerGaugeText: View {
    @StateObject var model: ServerData
    
    var body: some View {
        let chargePercent = model.chargePercent
        let rounded = String(Int(chargePercent.rounded()))
        
        ZStack {
            ProgressView(
                rounded,
                value: chargePercent,
                total: 100.0)
                .progressViewStyle(
                    CircularProgressViewStyle(tint: color(forChargeLevel: chargePercent)))
        }
        .onAppear {
            print("Corner Guage Appeared")
            
        }
    }
}

struct ComplicationViewCornerCircular: View {
    @StateObject var model: ServerData
  @Environment(\.complicationRenderingMode) var renderingMode

  var body: some View {
      let chargePercent = model.chargePercent
    ZStack {
      switch renderingMode {
      case .fullColor:
        Circle()
          .fill(Color.white)
      case .tinted:
        Circle()
          .fill(
            RadialGradient(
              gradient: Gradient(colors: [.clear, .white]),
              center: .center,
              startRadius: 10,
              endRadius: 15))
      @unknown default:
        Circle()
          .fill(Color.white)
      }
        Text(model.charge.soc)
        .foregroundColor(Color.black)
        .complicationForeground()
      Circle()
            //.stroke(.yellow, lineWidth: 5)
            .stroke(color(forChargeLevel: chargePercent), lineWidth: 5)
        .complicationForeground()
    }
    .onAppear {
        print("Corner Circular Appeared")
    }
  }
}

struct ComplicationViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let model = ServerData.shared
            CLKComplicationTemplateGraphicCircularView(
                ComplicationViewCircular(model: model)
            ).previewContext()
            
            CLKComplicationTemplateGraphicCornerCircularView(
                ComplicationViewCornerCircular(model: model)
            ).previewContext()
        }
    }
}
