//////
//////  Lymphocytes.swift
//////  CytegeistApp
//////
//////  Created by Adam Treister on 12/6/24.
//////
import Foundation
import SwiftUI

class Population: Codable {
    enum CodingKeys: CodingKey {
        case name
        case gate
        case children
    }
    var name: String
    var gate: String
    var children: [Population]?
    
    init(name: String, gate: String) {
        self.name = name
        self.gate = gate
        self.children = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.gate = try container.decode(String.self, forKey: .gate)
        self.children = try container.decode([Population].self, forKey: .children)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(gate, forKey: .gate)
        try container.encode(children, forKey: .children)
    }
}
    
class FileLoader {
    
    static func readLocalFile(_ filename: String) -> Data? {
        guard let file = Bundle.main.path(forResource: filename, ofType: "json")
        else {
            fatalError("Unable to locate file \"\(filename)\" in main bundle.")
        }
        
        do {
            return try String(contentsOfFile: file, encoding: .utf8).data(using: .utf8)
        } catch {
            fatalError("Unable to load \"\(filename)\" from main bundle:\n\(error)")
        }
    }
    
    
    static public func showElements(pop: Population?, delimeter: String = "") {
          
        var newLevelDelimeter = delimeter
        newLevelDelimeter += "> "
        if let pop {
                print("\(newLevelDelimeter) \(pop.name)")           ///pop \(pop.gate)
                if let kids = pop.children {
                    for kid in kids {
                        showElements(pop: kid, delimeter: newLevelDelimeter)
                    }
                }
        }
    }

}
    
    ////
let cds = ["CD3", "CD4","CD5", "CD8", "CD10", "CD14", "CD16", "CD19", "CD20", "CD21", "CD24","CD27", "CD28", "CD33", "CD34", "CD38", "CD45", "CD45RA", "CD56", "CD94", "CD161", "CD197"]
let others = [ "CXCR5", "HLADR","IgA","IgD", "IgG", "IgM", "Ja18", "TCRVa24", "Tfh", "Th1", "Th2", "Th9", "Th17" , "Th22" ]
let markers = cds + others
