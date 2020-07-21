//
//  TubeStatusWatchApp.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import SwiftUI

struct LineSetting: Codable, Identifiable {
    let id: String
    let name: String
}

struct LineList: View {
    private static let defaultLineSettings = [LineSetting(id: "bakerloo", name: "Bakerloo"),
                                              LineSetting(id: "central", name: "Central"),
                                              LineSetting(id: "circle", name: "Circle"),
                                              LineSetting(id: "district", name: "District"),
                                              LineSetting(id: "dlr", name: "DLR"),
                                              LineSetting(id: "hammersmith-city", name: "Hammersmith & City"),
                                              LineSetting(id: "jubilee", name: "Jubilee"),
                                              LineSetting(id: "london-overground", name: "London Overground"),
                                              LineSetting(id: "metropolitan", name: "Metropolitan"),
                                              LineSetting(id: "northern", name: "Northern"),
                                              LineSetting(id: "piccadilly", name: "Piccadilly"),
                                              LineSetting(id: "tfl-rail", name: "TfL Rail"),
                                              LineSetting(id: "tram", name: "Tram"),
                                              LineSetting(id: "victoria", name: "Victoria"),
                                              LineSetting(id: "waterloo-city", name: "Waterloo & City")]
    private static let defaultLineSettingsData = try! JSONEncoder().encode(Self.defaultLineSettings)
    
    @AppStorage(wrappedValue: Self.defaultLineSettingsData, "lineSettings") var lineSettingsData
    
    var body: some View {
        List {
            let lineSettings = try! JSONDecoder().decode([LineSetting].self, from: lineSettingsData)
            ForEach(lineSettings) { lineSetting in
                    Text(lineSetting.name)
                        .listRowBackground(Color(lineSetting.id)
                                            .cornerRadius(9))
            }
        }
    }
}

@main
struct TubeStatusWatchApp: App {
    var body: some Scene {
        WindowGroup {
            LineList()
        }
    }
}

struct TubeStatusWatchApp_Previews: PreviewProvider {
    static var previews: some View {
        LineList()
    }
}
