//
//  LineSetting.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 23/08/2020.
//

import Combine

class LineSetting: Codable, Identifiable, ObservableObject {
    enum CodingKeys: CodingKey {
        case id
        case name
        case isSelected
    }
    
    let id: String
    let name: String
    @Published var isSelected: Bool
    
    init(id: String, name: String, isSelected: Bool) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isSelected, forKey: .isSelected)
    }
}
