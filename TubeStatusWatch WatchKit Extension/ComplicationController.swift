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

class ComplicationController: NSObject, CLKComplicationDataSource {
    private static let urlString = "https://api.tfl.gov.uk/line/mode/dlr,overground,tflrail,tram,tube/status"
    
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
            .dataTaskPublisher(for: URL(string: Self.urlString)!)
            .map { $0.data }
            .decode(type: [Line].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    handler(nil)
                }
            } receiveValue: { lines in
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
        if let sampleLines = sampleLines(for: complication),
           let complicationTemplate = complicationTemplate(for: complication.family, and: sampleLines) {
            handler(complicationTemplate)
        } else {
            handler(nil)
        }
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
    
    // MARK: - Complication Creation Helpers
    
    private func visibleLines(for complication: CLKComplication,
                              allLines: [Line],
                              selectedLines: [Line]) -> [Line] {
        switch ComplicationIdentifier(rawValue: complication.identifierPrefix) {
        case .onlyLineComplication:
            return [selectedLines.first].compactMap { $0 }
        case .singleLineComplication:
            let lineId = complication.userInfo?["lineId"] as? String
            let line = allLines.first { $0.id == lineId }
            return [line].compactMap { $0 }
        case .multipleLineComplication:
            return selectedLines
        case .none:
            fatalError("Unrecognized complication")
        }
    }
    
    private func sampleLines(for complication: CLKComplication) -> [Line]? {
        switch ComplicationIdentifier(rawValue: complication.identifierPrefix) {
        case .onlyLineComplication, .singleLineComplication:
            guard let lineId = complication.userInfo?["lineId"] as? String,
                  let lineName = LineData.lineIdsToNames[lineId] else {
                return nil
            }
            return [Line(id: lineId, name: lineName, lineStatuses: [.sampleGoodService])]
        case .multipleLineComplication:
            return .samples
        case .none:
            return nil
        }
    }
    
    private func complicationTemplate(for complicationFamily: CLKComplicationFamily,
                                      and lines: [Line]) -> CLKComplicationTemplate? {
        let firstLine = lines.first
        let firstLineId = firstLine?.id
        let firstLineName = firstLine?.name
        let firstLineMostSevereLineStatus = firstLine?.mostSevereLineStatus
        let firstLineMostSevereStatusSeverity = firstLineMostSevereLineStatus?.statusSeverity
        let firstLineMostSevereStatusSeverityDescription = firstLineMostSevereLineStatus?.statusSeverityDescription
        switch complicationFamily {
        case .modularSmall, .circularSmall:
            return nil
        case .modularLarge:
            guard let lineName = firstLineName,
                  let statusSeverityDescription = firstLineMostSevereStatusSeverityDescription else { return nil }
            let headerTextProvider = CLKTextProvider(format: lineName)
            let body1TextProvider = CLKTextProvider(format: statusSeverityDescription)
            return CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: headerTextProvider,
                                                                   body1TextProvider: body1TextProvider)
        case .utilitarianSmall, .utilitarianSmallFlat:
            guard let lineName = firstLineName,
                  let statusSeverity = firstLineMostSevereStatusSeverity else { return nil }
            let onePieceImage = UIImage(systemName: StatusSeverityMapper.systemImageName(for: statusSeverity))
            let textProvider = CLKTextProvider(format: lineName)
            let imageProvider = CLKImageProvider(onePieceImage: onePieceImage!)
            return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider,
                                                               imageProvider: imageProvider)
        case .utilitarianLarge:
            guard let lineName = firstLineName,
                  let statusSeverityDescription = firstLineMostSevereStatusSeverityDescription else { return nil }
            let textProvider = CLKTextProvider(format: "%@: %@", lineName, statusSeverityDescription)
            return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: textProvider)
        case .extraLarge: // not tested
            guard let lineName = firstLineName,
                  let statusSeverityDescription = firstLineMostSevereStatusSeverityDescription else { return nil }
            let line1TextProvider = CLKTextProvider(format: lineName)
            let line2TextProvider = CLKTextProvider(format: statusSeverityDescription)
            return CLKComplicationTemplateExtraLargeStackText(line1TextProvider: line1TextProvider,
                                                              line2TextProvider: line2TextProvider)
        case .graphicCorner:
            guard let lineName = firstLineName,
                  let statusSeverity = firstLineMostSevereStatusSeverity else { return nil }
            let icon = Image(systemName: StatusSeverityMapper.systemImageName(for: statusSeverity))
            let textProvider = CLKTextProvider(format: lineName)
            let label = Label(title: {}, icon: { icon })
            return CLKComplicationTemplateGraphicCornerTextView(textProvider: textProvider, label: label)
        case .graphicBezel:
            let sliceViewModels = self.sliceViewModels(for: lines)
            let contentView = CircularComplicationContentView(viewModels: sliceViewModels)
            let circularTemplate = CLKComplicationTemplateGraphicCircularView(contentView)
            let textProvider: CLKTextProvider?
            if let lineName = lines.mostSevereLine?.name,
               let statusSeverityDescription = lines
                .mostSevereLine?
                .mostSevereLineStatus?
                .statusSeverityDescription {
                textProvider = CLKTextProvider(format: "%@: %@", lineName, statusSeverityDescription)
            } else {
                textProvider = nil
            }
            return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circularTemplate,
                                                                   textProvider: textProvider)
        case .graphicCircular:
            let sliceViewModels = self.sliceViewModels(for: lines)
            let contentView = CircularComplicationContentView(viewModels: sliceViewModels)
            return CLKComplicationTemplateGraphicCircularView(contentView)
        case .graphicRectangular:
            guard let lineId = firstLineId,
                  let lineName = firstLineName,
                  let statusSeverityDescription = firstLineMostSevereStatusSeverityDescription else { return nil }
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
            guard let mostSevereLineStatus = line.mostSevereLineStatus else { return nil }
            let fillColor = Color(line.id)
            let borderColor = StatusSeverityMapper.color(for: mostSevereLineStatus.statusSeverity)
            return CircularComplicationSliceViewModel(fillColor: fillColor, borderColor: borderColor)
        }
    }
}
