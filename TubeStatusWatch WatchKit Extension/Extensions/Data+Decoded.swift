//
//  Data+Decoded.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 19/08/2020.
//

import Foundation

extension Data {
    func decoded<T>(to type: T.Type) -> T? where T : Decodable {
        return try? JSONDecoder().decode(T.self, from: self)
    }
}
