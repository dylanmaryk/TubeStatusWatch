//
//  ComplicationController.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import ClockKit
import Combine
import SwiftUI

enum ComplicationIdentifier: String {
    case onlyLineComplication
    case singleLineComplication
    case multipleLineComplication
}

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

struct LineStatus: Codable {
    let statusSeverity: StatusSeverity
    let statusSeverityDescription: String
    let reason: String?
}

struct Line: Codable, Identifiable {
    let id: String
    let name: String
    let lineStatuses: [LineStatus]
}

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    @AppStorage("selectedLineIds") private var selectedLineIdsString = ""
    @AppStorage("selectedLineUpdates") private var selectedLineUpdatesData: Data?
    
    private var sessionCancellable: AnyCancellable?
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors: [CLKComplicationDescriptor]
        let selectedLineIds = selectedLineIdsString.componentsOrEmpty(separatedBy: ",")
        if selectedLineIds.count == 1,
           let lineId = selectedLineIds.first,
           let lineName = LineData.lineIdsToNames[lineId] {
            let identifier = ComplicationIdentifier.onlyLineComplication.rawValue
            let onlyLineDescriptor = singleLineComplicationDescriptor(identifier: identifier,
                                                                      lineName: lineName,
                                                                      lineId: lineId)
            descriptors = [onlyLineDescriptor]
        } else {
            let multipleLineDescriptor = multipleLineComplicationDescriptor()
            let singleLineDescriptors = selectedLineIds
                .compactMap { lineId -> CLKComplicationDescriptor? in
                    guard let lineName = LineData.lineIdsToNames[lineId] else {
                        return nil
                    }
                    let identifierPrefix = ComplicationIdentifier.singleLineComplication.rawValue
                    return singleLineComplicationDescriptor(identifier: "\(identifierPrefix)-\(lineId)",
                                                            lineName: lineName,
                                                            lineId: lineId)
                }
            descriptors = [multipleLineDescriptor] + singleLineDescriptors
        }
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
            .sink { _ in } receiveValue: { lines in
                let selectedLineIds = self.selectedLineIdsString.componentsOrEmpty(separatedBy: ",")
                let selectedLines = lines.filter { selectedLineIds.contains($0.id) }
                self.selectedLineUpdatesData = try? JSONEncoder().encode(selectedLines)
                let visibleLines: [Line?]
                guard let complicationIdentifierPrefix = complication
                        .identifier
                        .components(separatedBy: "-")
                        .first else {
                    fatalError("Failed to get complication identifier prefix")
                }
                switch ComplicationIdentifier(rawValue: complicationIdentifierPrefix) {
                case .onlyLineComplication:
                    visibleLines = [selectedLines.first]
                case .singleLineComplication:
                    let complicationLineId = complication.userInfo?["lineId"] as? String
                    let line = lines.first { $0.id == complicationLineId }
                    visibleLines = [line]
                case .multipleLineComplication:
                    visibleLines = selectedLines
                case .none:
                    fatalError("Unrecognized complication")
                }
                let sliceViewModels = visibleLines.compactMap { line -> CircularComplicationSliceViewModel? in
                    guard let line = line, let lineStatus = line.lineStatuses.first else {
                        return nil
                    }
                    let fillColor = Color(line.id)
                    let borderColor = StatusSeverityColorMapper.color(for: lineStatus.statusSeverity)
                    return CircularComplicationSliceViewModel(fillColor: fillColor, borderColor: borderColor)
                }
                let complicationTemplate: CLKComplicationTemplate?
                switch complication.family {
                case .modularSmall, .circularSmall:
                    complicationTemplate = nil
                case .modularLarge:
                    complicationTemplate = CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: CLKTextProvider(format: visibleLines.first!!.name),
                                                                                           body1TextProvider: CLKTextProvider(format: visibleLines.first!!.lineStatuses.first!.statusSeverityDescription))
                case .utilitarianSmall, .utilitarianSmallFlat:
                    complicationTemplate = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKTextProvider(format: visibleLines.first!!.name),
                                                                                       imageProvider: CLKImageProvider(onePieceImage: UIImage(systemName: "checkmark")!))
                case .utilitarianLarge:
                    complicationTemplate = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: CLKTextProvider(format: "%@: %@",
                                                                                                                     visibleLines.first!!.name,
                                                                                                                     visibleLines.first!!.lineStatuses.first!.statusSeverityDescription))
                case .extraLarge: // extraLarge not tested
                    complicationTemplate = CLKComplicationTemplateExtraLargeStackText(line1TextProvider: CLKTextProvider(format: visibleLines.first!!.name),
                                                                                      line2TextProvider: CLKTextProvider(format: visibleLines.first!!.lineStatuses.first!.statusSeverityDescription))
                case .graphicCorner:
                    complicationTemplate = CLKComplicationTemplateGraphicCornerTextView(textProvider: CLKTextProvider(format: visibleLines.first!!.name),
                                                                                        label: Label(title: {},
                                                                                                     icon: { Image(systemName: "checkmark") }))
                case .graphicBezel:
                    complicationTemplate = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: CLKComplicationTemplateGraphicCircularView(CircularComplicationContentView(viewModels: sliceViewModels)),
                                                                                           textProvider: CLKTextProvider(format: visibleLines.first!!.name))
                case .graphicCircular:
                    complicationTemplate = CLKComplicationTemplateGraphicCircularView(CircularComplicationContentView(viewModels: sliceViewModels))
                case .graphicRectangular:
                    complicationTemplate = CLKComplicationTemplateGraphicRectangularFullView(RectangularFullComplicationContentView(title: visibleLines.first!!.name,
                                                                                                                                    subtitle: (visibleLines.first?!.lineStatuses.first!.statusSeverityDescription)!,
                                                                                                                                    color: Color(visibleLines.first!!.id)))
                case .graphicExtraLarge:
                    complicationTemplate = CLKComplicationTemplateGraphicExtraLargeCircularView(CircularComplicationContentView(viewModels: sliceViewModels))
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
    
    // MARK: - Complication Descriptor Helpers
    
    private func singleLineComplicationDescriptor(identifier: String,
                                                  lineName: String,
                                                  lineId: String) -> CLKComplicationDescriptor {
        return CLKComplicationDescriptor(identifier: identifier,
                                         displayName: lineName,
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
                                         ],
                                         userInfo: ["lineId" : lineId])
    }
    
    private func multipleLineComplicationDescriptor() -> CLKComplicationDescriptor {
        return CLKComplicationDescriptor(identifier: ComplicationIdentifier.multipleLineComplication.rawValue,
                                         displayName: "All Selected Lines",
                                         supportedFamilies: [
                                            .graphicBezel,
                                            .graphicCircular,
                                            .graphicExtraLarge
                                         ])
    }
    
}
