//
//  NSError+PurchasesLocalizedDescription.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 11/09/2020.
//

import Foundation
import Purchases

extension NSError {
    var purchasesLocalizedDescription: String {
        switch Purchases.ErrorCode(_nsError: self).code {
        case .networkError:
            return "A network error occurred. Check if you are online."
        default:
            return localizedDescription
        }
    }
}
