//
//  Line.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 23/08/2020.
//

struct Line: Codable, Identifiable {
    enum CodingKeys: CodingKey {
        case name
        case status
        case text
    }
    
    let id: String
    let name: String
    let status: StatusSeverity
    let text: String
    
    init(id: String, name: String, status: StatusSeverity, text: String) {
        self.id = id
        self.name = name
        self.status = status
        self.text = text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .name)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(StatusSeverity.self, forKey: .status)
        text = try container.decode(String.self, forKey: .text)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(status, forKey: .status)
        try container.encode(text, forKey: .text)
    }
}

extension Array where Element == Line {
    var mostSevereLine: Line? {
        sorted {
            StatusSeverityMapper.statusLevel(for: $0.status)
                > StatusSeverityMapper.statusLevel(for: $1.status)
        }.first
    }
    
    static var samples: [Line] {
        let lineIds = LineData.lineIds
        let lineNames = LineData.lineNames
        return [Line(id: lineIds[0], name: lineNames[0], status: .goodService, text: "Good Service reason"),
                Line(id: lineIds[1], name: lineNames[1], status: .someDelays, text: "Some Delays reason"),
                Line(id: lineIds[2], name: lineNames[2], status: .suspended, text: "Suspended reason")]
    }
}
