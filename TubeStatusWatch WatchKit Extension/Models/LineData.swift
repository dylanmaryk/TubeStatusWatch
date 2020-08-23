//
//  LineData.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 15/08/2020.
//

enum LineData {
    static let lineIds = ["bakerloo",
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
    static let lineNames = ["Bakerloo",
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
    static let lineIdsToNames = Dictionary(uniqueKeysWithValues: zip(Self.lineIds, Self.lineNames))
}
