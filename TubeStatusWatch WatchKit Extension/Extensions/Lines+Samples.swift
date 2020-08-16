//
//  Lines+Samples.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 16/08/2020.
//

extension Array where Element == Line {
    static var samples: [Line] {
        let lineIds = LineData.lineIds
        let lineNames = LineData.lineNames
        return [Line(id: lineIds[0], name: lineNames[0], lineStatuses: [.sampleGoodService]),
                Line(id: lineIds[1], name: lineNames[1], lineStatuses: [.sampleSpecialService]),
                Line(id: lineIds[2], name: lineNames[2], lineStatuses: [.sampleClosed])]
    }
}
