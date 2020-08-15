//
//  TubeStatusWatchApp.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import ClockKit
import Combine
import SwiftUI

class LineSetting: Codable, Identifiable, ObservableObject {
    enum CodingKeys: CodingKey {
        case id
        case name
        case isSelected
    }
    
    let id: String
    let name: String
    @Published var isSelected: Bool
    
    init(id: String, name: String, isSelected: Bool) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isSelected, forKey: .isSelected)
    }
}

struct LineSettingButton: View {
    @ObservedObject var lineSetting: LineSetting
    @Binding var selectedLineIds: [String]
    
    var body: some View {
        Button {
            lineSetting.isSelected.toggle()
            lineSetting.isSelected
                ? selectedLineIds.append(lineSetting.id)
                : selectedLineIds.removeAll { $0 == lineSetting.id }
        } label: {
            HStack {
                Text(lineSetting.name)
                Spacer()
                lineSetting.isSelected ? Image(systemName: "checkmark") : nil
            }
        }
        .listRowBackground(Color(lineSetting.id)
                            .cornerRadius(9))
    }
}

struct LineSettingList: View {
    let lineSettings: [LineSetting]
    @Binding var selectedLineIds: [String]
    
    var body: some View {
        List {
            ForEach(lineSettings) { lineSetting in
                LineSettingButton(lineSetting: lineSetting, selectedLineIds: $selectedLineIds)
            }
        }
    }
}

struct LineUpdateItem: View {
    let name: String
    let statusSeverityDescription: String?
    let statusSeverityColor: Color?
    let reason: String?
    
    var body: some View {
        VStack {
            Text(name)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let statusSeverityDescription = statusSeverityDescription {
                Text(statusSeverityDescription)
                    .font(.headline)
                    .foregroundColor(statusSeverityColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let reason = reason {
                Text(reason)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct LineUpdateList: View {
    let lines: [Line]
    
    var body: some View {
        List {
            ForEach(lines) { line in
                if let lineStatus = line.lineStatuses.first {
                    LineUpdateItem(name: line.name,
                                   statusSeverityDescription: lineStatus.statusSeverityDescription,
                                   statusSeverityColor: StatusSeverityColorMapper
                                    .color(for: lineStatus.statusSeverity),
                                   reason: lineStatus.reason)
                }
            }
        }
    }
}

@main
struct TubeStatusWatchApp: App {
    private static let lineIds = ["bakerloo",
                                  "central",
                                  "circle",
                                  "district",
                                  "dlr",
                                  "hammersmith-city",
                                  "jubilee",
                                  "london-overground",
                                  "metropolitan",
                                  "northern",
                                  "piccadilly",
                                  "tfl-rail",
                                  "tram",
                                  "victoria",
                                  "waterloo-city"]
    
    private static let lineNames = ["Bakerloo",
                                    "Central",
                                    "Circle",
                                    "District",
                                    "DLR",
                                    "Hammersmith & City",
                                    "Jubilee",
                                    "London Overground",
                                    "Metropolitan",
                                    "Northern",
                                    "Piccadilly",
                                    "TfL Rail",
                                    "Tram",
                                    "Victoria",
                                    "Waterloo & City"]
    
    @AppStorage("selectedLineIds") private var selectedLineIdsString = ""
    @AppStorage("selectedLineUpdates") private var selectedLineUpdatesData: Data?
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) private var extensionDelegate
    @State private var isSheetPresented = false
    
    var body: some Scene {
        let selectedLineIds = Binding(
            get: { selectedLineIdsString.isEmpty ? [] : selectedLineIdsString.components(separatedBy: ",") },
            set: { selectedLineIdsString = $0.joined(separator: ",") }
        )
        let lineSettings = Self.lineIds.enumerated().map { index, lineId in
            LineSetting(id: lineId,
                        name: Self.lineNames[index],
                        isSelected: selectedLineIds.wrappedValue.contains(lineId))
        }
        
        WindowGroup {
            LineSettingList(lineSettings: lineSettings, selectedLineIds: selectedLineIds)
                .onAppear {
                    isSheetPresented = selectedLineUpdatesData != nil
                }
                .onChange(of: selectedLineUpdatesData) { value in
                    isSheetPresented = value != nil
                }
                .sheet(isPresented: $isSheetPresented, onDismiss: { selectedLineUpdatesData = nil }) {
                    if let selectedLineUpdatesData = selectedLineUpdatesData,
                       let selectedLines = try? JSONDecoder().decode([Line].self, from: selectedLineUpdatesData) {
                        LineUpdateList(lines: selectedLines)
                    }
                }
        }
    }
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidEnterBackground() {
        let complicationServer = CLKComplicationServer.sharedInstance()
        complicationServer.activeComplications?.forEach(complicationServer.reloadTimeline)
    }
}

struct TubeStatusWatchApp_Previews: PreviewProvider {
    static var previews: some View {
        let lineSettings = [LineSetting(id: "bakerloo", name: "Bakerloo", isSelected: true),
                            LineSetting(id: "central", name: "Central", isSelected: false),
                            LineSetting(id: "circle", name: "Circle", isSelected: false)]
        let selectedLineSettingIds = Binding(
            get: { ["bakerloo"] },
            set: { _ in }
        )
        let goodServiceLineStatus = LineStatus(statusSeverity: .goodService,
                                               statusSeverityDescription: "Good Service",
                                               reason: "Good Service reason")
        let specialServiceLineStatus = LineStatus(statusSeverity: .specialService,
                                                  statusSeverityDescription: "Special Service",
                                                  reason: "Special Service reason")
        let closedLineStatus = LineStatus(statusSeverity: .closed,
                                          statusSeverityDescription: "Closed",
                                          reason: "Closed reason")
        let lines = [Line(id: "bakerloo", name: "Bakerloo", lineStatuses: [goodServiceLineStatus]),
                     Line(id: "central", name: "Central", lineStatuses: [specialServiceLineStatus]),
                     Line(id: "circle", name: "Circle", lineStatuses: [closedLineStatus])]
        
        Group {
            LineSettingList(lineSettings: lineSettings, selectedLineIds: selectedLineSettingIds)
            LineUpdateList(lines: lines)
        }
    }
}
