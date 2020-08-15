//
//  String+ComponentsOrEmpty.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 15/08/2020.
//

extension String {
    func componentsOrEmpty(separatedBy separator: String) -> [String] {
        return isEmpty ? [] : components(separatedBy: separator)
    }
}
