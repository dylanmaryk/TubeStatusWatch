//
//  StatusSeverity.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 15/09/2020.
//

enum StatusSeverity: Int, Codable {
    case specialService
    case closed
    case suspended
    case partSuspended
    case plannedClosure
    case partClosure
    case severeDelays
    case reducedService
    case busService
    case minorDelays
    case goodService
    case partClosed
    case exitOnly
    case noStepFreeAccess
    case changeOfFrequency
    case diverted
    case notRunning
    case issuesReported
    case noIssues
    case information
    case serviceClosed
    case unknown
    
    init(from decoder: Decoder) throws {
        self = StatusSeverity(rawValue: try decoder.singleValueContainer().decode(Int.self)) ?? .unknown
    }
}
