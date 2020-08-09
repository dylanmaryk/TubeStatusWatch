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
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) private var extensionDelegate
    
    var body: some Scene {
        WindowGroup {
            let selectedLineIds = Binding(
                get: { selectedLineIdsString.isEmpty ? [] : selectedLineIdsString.components(separatedBy: ",") },
                set: { selectedLineIdsString = $0.joined(separator: ",") }
            )
            let lineSettings = Self.lineIds.enumerated().map { index, lineId in
                LineSetting(id: lineId,
                            name: Self.lineNames[index],
                            isSelected: selectedLineIds.wrappedValue.contains(lineId))
            }
            LineList(lineSettings: lineSettings, selectedLineIds: selectedLineIds)
        }
    }
}

struct LineList: View {
    let lineSettings: [LineSetting]
    @Binding var selectedLineIds: [String]
    
    var body: some View {
        List {
            ForEach(lineSettings) { lineSetting in
                LineButton(lineSetting: lineSetting, selectedLineIds: $selectedLineIds)
            }
        }
    }
}

struct LineButton: View {
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
        LineList(lineSettings: lineSettings, selectedLineIds: selectedLineSettingIds)
    }
}
