//
//  ComplicationController.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import ClockKit
import Combine
import SwiftUI

enum StatusSeverity: Int, Codable {
    case specialService
    case closed
    case suspended
    case partSuspended
    case plannedClosure
    case partClosure
    case severeDelays
    case reducedService
    case busService
    case minorDelays
    case goodService
    case partClosed
    case exitOnly
    case noStepFreeAccess
    case changeOfFrequency
    case diverted
    case notRunning
    case issuesReported
    case noIssues
    case information
    case serviceClosed
}

struct Line: Codable, Identifiable {
    let id: String
    let name: String
    let lineStatuses: [LineStatus]
}

struct LineStatus: Codable {
    let statusSeverity: StatusSeverity
    let statusSeverityDescription: String
    let reason: String?
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
        handler(Date())
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
                guard let selectedLineIdsString = UserDefaults.standard.string(forKey: "selectedLineIds") else {
                    // TODO: Handle no lines selected yet
                    return
                }
                let selectedLineIds = selectedLineIdsString.isEmpty
                    ? []
                    : selectedLineIdsString.components(separatedBy: ",")
                let selectedLines = lines.filter { selectedLineIds.contains($0.id) }
                UserDefaults.standard.setValue(try! JSONEncoder().encode(selectedLines), forKey: "selectedLineUpdates")
                let sliceViewModels = selectedLines.map { line -> CircularComplicationSliceViewModel in
                    let fillColor = Color(line.id)
                    let borderColor = self.sliceBorderColor(for: line.lineStatuses.first!.statusSeverity)
                    return CircularComplicationSliceViewModel(fillColor: fillColor, borderColor: borderColor)
                }
                let complicationTemplate: CLKComplicationTemplate?
                switch complication.family {
                case .modularSmall, .circularSmall:
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
                case .extraLarge, .graphicCircular, .graphicExtraLarge: // extraLarge not tested
                    complicationTemplate = CLKComplicationTemplateGraphicCircularView(CircularComplicationContentView(viewModels: sliceViewModels))
                case .graphicCorner:
                    complicationTemplate = CLKComplicationTemplateGraphicCornerTextView(textProvider: CLKTextProvider(format: lines.first!.name),
                                                                                        label: Label(title: {},
                                                                                                     icon: { Image(systemName: "checkmark") }))
                case .graphicBezel:
                    complicationTemplate = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: CLKComplicationTemplateGraphicCircularView(CircularComplicationContentView(viewModels: sliceViewModels)),
                                                                                           textProvider: CLKTextProvider(format: lines.first!.name))
                case .graphicRectangular:
                    complicationTemplate = CLKComplicationTemplateGraphicRectangularFullView(RectangularFullComplicationContentView(title: lines.first!.name,
                                                                                                                                    subtitle: (lines.first?.lineStatuses.first!.statusSeverityDescription)!,
                                                                                                                                    color: Color(lines.first!.id)))
                @unknown default:
                    complicationTemplate = nil
                }
                if let complicationTemplate = complicationTemplate {
                    handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: complicationTemplate))
                } else {
                    handler(nil)
                }
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
        // TODO: Handle sample templates
        handler(nil)
    }
    
    // MARK: - Helpers
    
    private func sliceBorderColor(for statusSeverity: StatusSeverity) -> Color {
        switch statusSeverity {
        case .goodService,
             .noIssues:
            return .green
        case .specialService,
             .partSuspended,
             .reducedService,
             .minorDelays,
             .exitOnly,
             .noStepFreeAccess,
             .changeOfFrequency,
             .issuesReported,
             .information:
            return .yellow
        case .closed,
             .suspended,
             .plannedClosure,
             .partClosure,
             .severeDelays,
             .busService,
             .partClosed,
             .diverted,
             .notRunning,
             .serviceClosed:
            return .red
        }
    }
    
}
