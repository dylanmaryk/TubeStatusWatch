//
//  StatusSeverityMapper.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 15/08/2020.
//

import SwiftUI

enum StatusLevel: Comparable {
    case good
    case ok
    case bad
}

enum StatusSeverityMapper {
    static func color(for statusSeverity: StatusSeverity) -> Color {
        switch Self.statusLevel(for: statusSeverity) {
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
        case .goodService,
             .noIssues:
            return .good
        case .specialService,
             .partSuspended,
             .reducedService,
             .minorDelays,
             .exitOnly,
             .noStepFreeAccess,
             .changeOfFrequency,
             .issuesReported,
             .information:
            return .ok
        case .closed,
             .suspended,
             .plannedClosure,
             .partClosure,
             .severeDelays,
             .busService,
             .partClosed,
             .diverted,
             .notRunning,
             .serviceClosed:
            return .bad
        }
    }
}
