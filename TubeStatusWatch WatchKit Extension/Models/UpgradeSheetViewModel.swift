//
//  UpgradeSheetViewModel.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 05/09/2020.
//

import Combine

class UpgradeSheetViewModel: ObservableObject {
    var localizedDescription: String
    var localizedPrice: String
    var package: Package
    
    init(localizedDescription: String = "", localizedPrice: String = "", package: Package = Package()) {
        self.localizedDescription = localizedDescription
        self.localizedPrice = localizedPrice
        self.package = package
    }
}
