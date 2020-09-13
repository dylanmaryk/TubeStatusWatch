//
//  StatusSeverity.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 23/08/2020.
//

enum StatusSeverity: String, Codable {
    case suspended = "SUSPENDED"
    case multipleImpacts = "MULTIPLE IMPACTS"
    case partSuspended = "PART SUSPENDED"
    case plannedWork = "PLANNED WORK"
    case trainsRerouted = "TRAINS REROUTED"
    case delays = "DELAYS"
    case serviceChange = "SERVICE CHANGE"
    case localToExpress = "LOCAL TO EXPRESS"
    case expressToLocal = "EXPRESS TO LOCAL"
    case stationsSkipped = "STATIONS SKIPPED"
    case someDelays = "SOME DELAYS"
    case slowSpeeds = "SLOW SPEEDS"
    case crowding = "CROWDING"
    case weekendService = "WEEKEND SERVICE"
    case weekdayService = "WEEKDAY SERVICE"
    case goodService = "GOOD SERVICE"
}
