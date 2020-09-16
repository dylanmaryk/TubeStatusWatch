//
//  StatusSeverityMapper.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 15/08/2020.
//

import SwiftUI

enum StatusLevel: Comparable {
    case unknown
    case good
    case ok
    case bad
}

enum StatusSeverityMapper {
    static func color(for statusSeverity: StatusSeverity) -> Color {
        switch Self.statusLevel(for: statusSeverity) {
        case .unknown:
            return .gray
        case .good:
            return .green
        case .ok:
            return .yellow
        case .bad:
            return .red
        }
    }
    
    static func systemImageName(for statusSeverity: StatusSeverity) -> String {
        switch Self.statusLevel(for: statusSeverity) {
        case .unknown:
            return "questionmark"
        case .good:
            return "checkmark"
        case .ok:
            return "minus"
        case .bad:
            return "xmark"
        }
    }
    
    static func statusLevel(for statusSeverity: StatusSeverity) -> StatusLevel {
        switch statusSeverity {
        case .unknown:
            return .unknown
        case .crowding,
             .weekendService,
             .weekdayService,
             .goodService:
            return .good
        case .localToExpress,
             .expressToLocal,
             .stationsSkipped,
             .someDelays,
             .slowSpeeds:
            return .ok
        case .noScheduledService,
             .suspended,
             .plannedWork,
             .multipleImpacts,
             .partSuspended,
             .trainsRerouted,
             .someReroutes,
             .delays,
             .serviceChange:
            return .bad
        }
    }
}
