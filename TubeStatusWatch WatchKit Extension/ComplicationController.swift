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
                    guard let lineName = LineData.lineIdsToNames[lineId] else { return nil }
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
                let visibleLines = self.visibleLines(for: complication,
                                                     allLines: lines,
                                                     selectedLines: selectedLines)
                if let complicationTemplate = self.complicationTemplate(for: complication.family,
                                                                        and: visibleLines) {
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
    
    // MARK: - Timeline Entry Helpers
    
    private func visibleLines(for complication: CLKComplication,
                              allLines: [Line],
                              selectedLines: [Line]) -> [Line] {
        guard let complicationIdentifierPrefix = complication.identifier.components(separatedBy: "-").first else {
            fatalError("Failed to get complication identifier prefix")
        }
        switch ComplicationIdentifier(rawValue: complicationIdentifierPrefix) {
        case .onlyLineComplication:
            return [selectedLines.first].compactMap { $0 }
        case .singleLineComplication:
            let complicationLineId = complication.userInfo?["lineId"] as? String
            let line = allLines.first { $0.id == complicationLineId }
            return [line].compactMap { $0 }
        case .multipleLineComplication:
            return selectedLines
        case .none:
            fatalError("Unrecognized complication")
        }
    }
    
    private func complicationTemplate(for complicationFamily: CLKComplicationFamily,
                                      and lines: [Line]) -> CLKComplicationTemplate? {
        let firstLine = lines.first
        let firstLineId = firstLine?.id
        let firstLineName = firstLine?.name
        let firstLineStatusSeverityDescription = firstLine?.lineStatuses.first?.statusSeverityDescription
        switch complicationFamily {
        case .modularSmall, .circularSmall:
            return nil
        case .modularLarge:
            guard let lineName = firstLineName,
                  let statusSeverityDescription = firstLineStatusSeverityDescription else { return nil }
            let headerTextProvider = CLKTextProvider(format: lineName)
            let body1TextProvider = CLKTextProvider(format: statusSeverityDescription)
            return CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: headerTextProvider,
                                                                   body1TextProvider: body1TextProvider)
        case .utilitarianSmall, .utilitarianSmallFlat:
            guard let lineName = firstLineName else { return nil }
            let textProvider = CLKTextProvider(format: lineName)
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(systemName: "checkmark")!)
            return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider,
                                                               imageProvider: imageProvider)
        case .utilitarianLarge:
            guard let lineName = firstLineName,
                  let statusSeverityDescription = firstLineStatusSeverityDescription else { return nil }
            let textProvider = CLKTextProvider(format: "%@: %@", lineName, statusSeverityDescription)
            return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: textProvider)
        case .extraLarge: // not tested
            guard let lineName = firstLineName,
                  let statusSeverityDescription = firstLineStatusSeverityDescription else { return nil }
            let line1TextProvider = CLKTextProvider(format: lineName)
            let line2TextProvider = CLKTextProvider(format: statusSeverityDescription)
            return CLKComplicationTemplateExtraLargeStackText(line1TextProvider: line1TextProvider,
                                                              line2TextProvider: line2TextProvider)
        case .graphicCorner:
            guard let lineName = firstLineName else { return nil }
            let textProvider = CLKTextProvider(format: lineName)
            let label = Label(title: {}, icon: { Image(systemName: "checkmark") })
            return CLKComplicationTemplateGraphicCornerTextView(textProvider: textProvider, label: label)
        case .graphicBezel:
            guard let lineName = firstLineName,
                  let statusSeverityDescription = firstLineStatusSeverityDescription else { return nil }
            let sliceViewModels = self.sliceViewModels(for: lines)
            let contentView = CircularComplicationContentView(viewModels: sliceViewModels)
            let circularTemplate = CLKComplicationTemplateGraphicCircularView(contentView)
            let textProvider = CLKTextProvider(format: "%@: %@", lineName, statusSeverityDescription)
            return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circularTemplate,
                                                                   textProvider: textProvider)
        case .graphicCircular:
            let sliceViewModels = self.sliceViewModels(for: lines)
            let contentView = CircularComplicationContentView(viewModels: sliceViewModels)
            return CLKComplicationTemplateGraphicCircularView(contentView)
        case .graphicRectangular:
            guard let lineId = firstLineId,
                  let lineName = firstLineName,
                  let statusSeverityDescription = firstLineStatusSeverityDescription else { return nil }
            let contentView = RectangularFullComplicationContentView(title: lineName,
                                                                     subtitle: statusSeverityDescription,
                                                                     color: Color(lineId))
            return CLKComplicationTemplateGraphicRectangularFullView(contentView)
        case .graphicExtraLarge:
            let sliceViewModels = self.sliceViewModels(for: lines)
            let contentView = CircularComplicationContentView(viewModels: sliceViewModels)
            return CLKComplicationTemplateGraphicExtraLargeCircularView(contentView)
        @unknown default:
            return nil
        }
    }
    
    private func sliceViewModels(for lines: [Line]) -> [CircularComplicationSliceViewModel] {
        return lines.compactMap { line in
            guard let lineStatus = line.lineStatuses.first else { return nil }
            let fillColor = Color(line.id)
            let borderColor = StatusSeverityColorMapper.color(for: lineStatus.statusSeverity)
            return CircularComplicationSliceViewModel(fillColor: fillColor, borderColor: borderColor)
        }
    }
    
}
