//
//  ComplicationController.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import ClockKit
import Combine
import SwiftUI

struct Line: Decodable {
    let id: String
    let name: String
    let lineStatuses: [LineStatus]
}

struct LineStatus: Decodable {
    let statusSeverity: Int
    let statusSeverityDescription: String
    let reason: String
}

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    private var sessionCancellable: AnyCancellable?
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication",
                                      displayName: "TubeStatusWatch",
                                      supportedFamilies: [
                                        .modularLarge,
                                        .utilitarianSmall,
                                        .utilitarianSmallFlat,
                                        .utilitarianLarge,
                                        .extraLarge,
                                        .graphicCorner,
                                        .graphicBezel,
                                        .graphicCircular,
                                        .graphicRectangular,
                                        .graphicExtraLarge
                                      ])
        ]
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication,
                            withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication,
                            withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication,
                                 withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        sessionCancellable = URLSession.shared
            .dataTaskPublisher(for: URL(string: "https://api.tfl.gov.uk/line/mode/dlr,overground,tflrail,tram,tube/status")!)
            .map { $0.data }
            .decode(type: [Line].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            } receiveValue: { lines in
                let complicationTemplate: CLKComplicationTemplate?
                switch complication.family {
                case .modularSmall:
                    complicationTemplate = nil
                case .modularLarge:
                    complicationTemplate = CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: CLKTextProvider(format: lines.first!.name),
                                                                                           body1TextProvider: CLKTextProvider(format: lines.first!.lineStatuses.first!.statusSeverityDescription))
                case .utilitarianSmall, .utilitarianSmallFlat:
                    complicationTemplate = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKTextProvider(format: lines.first!.name),
                                                                                       imageProvider: CLKImageProvider(onePieceImage: UIImage(systemName: "checkmark")!))
                case .utilitarianLarge:
                    complicationTemplate = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: CLKTextProvider(format: "%@: %@",
                                                                                                                     lines.first!.name,
                                                                                                                     lines.first!.lineStatuses.first!.statusSeverityDescription))
                case .circularSmall:
                    complicationTemplate = nil
                case .extraLarge: // not tested
                    let viewModels = [CircularComplicationSliceViewModel(fillColor: Color(lines[0].id),
                                                                         borderColor: .green),
                                      CircularComplicationSliceViewModel(fillColor: Color(lines[1].id),
                                                                         borderColor: .yellow),
                                      CircularComplicationSliceViewModel(fillColor: Color(lines[2].id),
                                                                         borderColor: .red)]
                    complicationTemplate = CLKComplicationTemplateGraphicCircularView(CircularComplicationContentView(viewModels: viewModels))
                case .graphicCorner:
                    complicationTemplate = CLKComplicationTemplateGraphicCornerTextView(textProvider: CLKTextProvider(format: lines.first!.name),
                                                                                        label: Label(title: {},
                                                                                                     icon: { Image(systemName: "checkmark") }))
                case .graphicBezel:
                    let viewModels = [CircularComplicationSliceViewModel(fillColor: Color(lines[0].id),
                                                                         borderColor: .green),
                                      CircularComplicationSliceViewModel(fillColor: Color(lines[1].id),
                                                                         borderColor: .yellow),
                                      CircularComplicationSliceViewModel(fillColor: Color(lines[2].id),
                                                                         borderColor: .red)]
                    complicationTemplate = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: CLKComplicationTemplateGraphicCircularView(CircularComplicationContentView(viewModels: viewModels)),
                                                                                           textProvider: CLKTextProvider(format: lines.first!.name))
                case .graphicCircular:
                    let viewModels = [CircularComplicationSliceViewModel(fillColor: Color(lines[0].id),
                                                                         borderColor: .green),
                                      CircularComplicationSliceViewModel(fillColor: Color(lines[1].id),
                                                                         borderColor: .yellow),
                                      CircularComplicationSliceViewModel(fillColor: Color(lines[2].id),
                                                                         borderColor: .red)]
                    complicationTemplate = CLKComplicationTemplateGraphicCircularView(CircularComplicationContentView(viewModels: viewModels))
                case .graphicRectangular: // tested
                    complicationTemplate = CLKComplicationTemplateGraphicRectangularFullView(RectangularFullComplicationContentView(title: lines.first!.name,
                                                                                                                                    subtitle: (lines.first?.lineStatuses.first!.statusSeverityDescription)!,
                                                                                                                                    color: Color(lines.first!.id)))
                case .graphicExtraLarge:
                    let viewModels = [CircularComplicationSliceViewModel(fillColor: Color(lines[0].id),
                                                                         borderColor: .green),
                                      CircularComplicationSliceViewModel(fillColor: Color(lines[1].id),
                                                                         borderColor: .yellow),
                                      CircularComplicationSliceViewModel(fillColor: Color(lines[2].id),
                                                                         borderColor: .red)]
                    complicationTemplate = CLKComplicationTemplateGraphicExtraLargeCircularView(CircularComplicationContentView(viewModels: viewModels))
                @unknown default:
                    fatalError()
                }
                handler(CLKComplicationTimelineEntry(date: Date(),
                                                     complicationTemplate: complicationTemplate!))
            }
    }
    
    func getTimelineEntries(for complication: CLKComplication,
                            after date: Date,
                            limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication,
                                      withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(nil)
    }
    
}
