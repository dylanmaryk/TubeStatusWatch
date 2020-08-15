//
//  StatusSeverityColorMapper.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 15/08/2020.
//

import SwiftUI

enum StatusSeverityColorMapper {
    static func color(for statusSeverity: StatusSeverity) -> Color {
        switch statusSeverity {
        case .goodService,
             .noIssues:
            return .green
        case .specialService,
             .partSuspended,
             .reducedService,
             .minorDelays,
             .exitOnly,
             .noStepFreeAccess,
             .changeOfFrequency,
             .issuesReported,
             .information:
            return .yellow
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
            return .red
        }
    }
}
