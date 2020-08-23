//
//  Line.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 23/08/2020.
//

struct Line: Codable, Identifiable {
    let id: String
    let name: String
    let lineStatuses: [LineStatus]
}

extension Line {
    var mostSevereLineStatus: LineStatus? {
        lineStatuses.sorted {
            StatusSeverityMapper.statusLevel(for: $0.statusSeverity)
                > StatusSeverityMapper.statusLevel(for: $1.statusSeverity)
        }.first
    }
}

extension Array where Element == Line {
    var mostSevereLine: Line? {
        filter { $0.mostSevereLineStatus != nil }
            .sorted {
                StatusSeverityMapper.statusLevel(for: $0.mostSevereLineStatus!.statusSeverity)
                    > StatusSeverityMapper.statusLevel(for: $1.mostSevereLineStatus!.statusSeverity)
            }.first
    }
    
    static var samples: [Line] {
        let lineIds = LineData.lineIds
        let lineNames = LineData.lineNames
        return [Line(id: lineIds[0], name: lineNames[0], lineStatuses: [.sampleGoodService]),
                Line(id: lineIds[1], name: lineNames[1], lineStatuses: [.sampleSpecialService]),
                Line(id: lineIds[2], name: lineNames[2], lineStatuses: [.sampleClosed])]
    }
}
