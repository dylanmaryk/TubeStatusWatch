//
//  Subway.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 13/09/2020.
//

struct Subway: Codable {
    enum CodingKeys: CodingKey {
        case line
    }
    
    let lines: [Line]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lines = try container.decode([Line].self, forKey: .line)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lines, forKey: .line)
    }
}
