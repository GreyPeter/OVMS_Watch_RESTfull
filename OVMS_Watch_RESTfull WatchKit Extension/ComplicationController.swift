//
//  ComplicationController.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import ClockKit
import SwiftUI


class ComplicationController: NSObject, CLKComplicationDataSource {
    lazy var model = ServerData.shared
    
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "OVMS_Watch_RESTfull", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        //if let ctemplate = makeTemplate(for: model, complication: complication) {
        if let ctemplate = createTemplate(forComplication: complication) {
            let entry = CLKComplicationTimelineEntry (
                date: Date(),
                complicationTemplate: ctemplate
            )
            handler(entry)
        } else {
            handler(nil)
        }
        
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
        handler(nil)
    }

    // MARK: - Sample Templates
    
    //func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
        // This method will be called once per supported complication, and the results will be cached
        return createTemplate(forComplication: complication)
    }
}

extension ComplicationController {
    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication) -> CLKComplicationTemplate? {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate()
        case .modularLarge:
            return createModularLargeTemplate()
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate()
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate()
        case .circularSmall:
            return createCircularSmallTemplate()
        case .extraLarge:
            return createExtraLargeTemplate()
        case .graphicCorner:
            return createGraphicCornerTemplate()
        case .graphicCircular:
            return createGraphicCircleTemplate()
        case .graphicRectangular:
            return createGraphicRectangularTemplate()
        case .graphicBezel:
            return nil
           // return createGraphicBezelTemplate()
        case .graphicExtraLarge:
            return createGraphicExtraLargeTemplate()
    
        @unknown default:
            print("Unknown Complication Family")
            fatalError()
        }
    }

    
    // Return a modular small template.
    private func createModularSmallTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: soc,
                                                            line2TextProvider: units)
    }
    
    // Return a modular large template.
    private func createModularLargeTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        let titleTextProvider = CLKSimpleTextProvider(text: "Current Charge", shortText: "Charge")

        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        
        // Create the template using the providers.
        //let imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeModularLarge"))
        return CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: titleTextProvider, body1TextProvider: combinedSOCProvider)
    }
    
    // Return a utilitarian small flat template.
    private func createUtilitarianSmallFlatTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        //let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedSOCProvider)
    }
    
    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        //let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedSOCProvider)
    }
    
    // Return a circular small template.
    private func createCircularSmallTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        
        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: combinedSOCProvider, line2TextProvider: combinedSOCProvider)
    }
    
    // Return an extra large template.
    private func createExtraLargeTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        
        // Create the template using the providers.
        return CLKComplicationTemplateExtraLargeStackText(line1TextProvider: soc,
                                                          line2TextProvider: units)
    }
    
    // Return a graphic template that fills the corner of the watch face.
    private func createGraphicCornerTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        let percentage = Float(model.chargePercent/100)
        let rounded = String(Int(model.chargePercent.rounded()))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.red, .orange, .yellow, .green],
                                                   gaugeColorLocations: [0.25, 0.5, 0.75, 1.0] as [NSNumber],
                                                   fillFraction: percentage)
        let labelProvider = CLKTextProvider(format: "%@", rounded)
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerGaugeText(gaugeProvider: gaugeProvider, outerTextProvider: labelProvider)
    }
    
    // Return a graphic circle template.
    private func createGraphicCircleTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        
        let percentage = Float(model.chargePercent/100)
        let rounded = String(Int(model.chargePercent.rounded()))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.red, .orange, .yellow, .green],
                                                   gaugeColorLocations: [0.25, 0.5, 0.75, 1.0] as [NSNumber],
                                                   fillFraction: percentage)
        let bottomText = CLKTextProvider(format: "%@%%", rounded)
        let centerText = CLKTextProvider(format: "%@", model.charge.estimatedrange)
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(gaugeProvider: gaugeProvider,
                                                                         bottomTextProvider: bottomText,
                                                                         centerTextProvider: centerText)
    }
    
    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate() -> CLKComplicationTemplate {
        // Create the data providers.
        //let imageProvider = CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicRectangular"))
        let percentage = Float(model.chargePercent/100)
        let rounded = String(Int(model.chargePercent.rounded()))
        let titleTextProvider = CLKSimpleTextProvider(text: "Charge Level \(rounded)%", shortText: "Charge")
        let combinedSOCProvider = CLKTextProvider(format: "Range %@%@", model.charge.estimatedrange, model.charge.units)

        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.red, .orange, .yellow, .green],
                                                   gaugeColorLocations: [0.25, 0.5, 0.75, 1.0] as [NSNumber],
                                                   fillFraction: percentage)

        // Create the template using the providers.
        
        //return CLKComplicationTemplateGraphicRectangularTextGauge(headerImageProvider: imageProvider,headerTextProvider: titleTextProvider,body1TextProvider: combinedSOCProvider,gaugeProvider: gaugeProvider)
        return CLKComplicationTemplateGraphicRectangularTextGauge(headerTextProvider: titleTextProvider, body1TextProvider: combinedSOCProvider, gaugeProvider: gaugeProvider)
    }
    /*
    // Return a circular template with text that wraps around the top of the watch's bezel.
    private func createGraphicBezelTemplate() -> CLKComplicationTemplate {
        
        // Create a graphic circular template with an image provider.
        let circle = CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicCircular")))
        
        // Create the text provider.
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        
        // Create the bezel template using the circle template and the text provider.
        return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circle,
                                                               textProvider: combinedSOCProvider)
    }
    */
    // Returns an extra large graphic template.
    private func createGraphicExtraLargeTemplate() -> CLKComplicationTemplate {
        
        // Create the data providers.
        let percentage = Float(model.chargePercent/100)
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.red, .orange, .yellow, .green],
                                                   gaugeColorLocations: [0.25, 0.5, 0.75, 1.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: CLKSimpleTextProvider(text: "%"),
            centerTextProvider: soc)
    }

}
