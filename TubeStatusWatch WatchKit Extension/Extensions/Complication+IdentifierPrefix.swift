//
//  Complication+IdentifierPrefix.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 16/08/2020.
//

import ClockKit

extension CLKComplication {
    var identifierPrefix: String {
        guard let prefix = identifier.components(separatedBy: "-").first else {
            fatalError("Failed to get complication identifier prefix")
        }
        return prefix
    }
}
