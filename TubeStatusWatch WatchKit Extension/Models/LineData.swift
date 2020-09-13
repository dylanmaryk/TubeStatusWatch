//
//  LineData.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 15/08/2020.
//

enum LineData {
    static let lineIds = Self.lineNames
    static let lineNames = ["123",
                            "456",
                            "7",
                            "ACE",
                            "BDFM",
                            "G",
                            "JZ",
                            "L",
                            "NQR",
                            "S",
                            "SIR"]
    static let lineIdsToNames = Dictionary(uniqueKeysWithValues: zip(Self.lineIds, Self.lineNames))
}
