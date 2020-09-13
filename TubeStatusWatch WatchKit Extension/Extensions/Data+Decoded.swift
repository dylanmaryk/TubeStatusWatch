//
//  Data+Decoded.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 19/08/2020.
//

import Foundation
import XMLCoder

extension Data {
    func decoded<T>(to type: T.Type) -> T? where T : Decodable {
        try? JSONDecoder().decode(T.self, from: self)
    }
    
    func xmlDecoded<T>(to type: T.Type) -> T? where T : Decodable {
        try? XMLDecoder().decode(T.self, from: self)
    }
}
