//
//  LineStatus.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 23/08/2020.
//

struct LineStatus: Codable, Hashable {
    let statusSeverity: StatusSeverity
    let statusSeverityDescription: String
    let reason: String?
}

extension LineStatus {
    static var sampleGoodService: LineStatus {
        LineStatus(statusSeverity: .goodService,
                   statusSeverityDescription: "Good Service",
                   reason: "Good Service reason")
    }
    
    static var sampleSpecialService: LineStatus {
        LineStatus(statusSeverity: .specialService,
                   statusSeverityDescription: "Special Service",
                   reason: "Special Service reason")
    }
    
    static var sampleClosed: LineStatus {
        LineStatus(statusSeverity: .closed,
                   statusSeverityDescription: "Closed",
                   reason: "Closed reason")
    }
}
