//
//  MIFlowCyt.swift
//  CytegeistCore
//
//  Created by Adam Treister on 9/18/24.
//

import SwiftUI
import CytegeistLibrary

struct MIFlowCyt
{
    var ExperimentName:  String
    var Purpose:  String
    var Conclusion: String
    var Keywords:    [String]
    var Variables: [String]

    var Score:    Float
    var StartDate:    Date
    var EndDate:    Date
    var Uploaded:   Date
    var LastUpdated:   Date

    var RepositoryID:    String
    var Manuscripts:     String
    var PrimaryResearcher:    String
    var Manager:   String
    var UploadedBy:    String
    var Organizations:   String
}



struct MIFlowCytView : View
{
    var rec = MIFlowCyt(ExperimentName: "20241001", Purpose: "Test Experiment", Conclusion: "Browser works", 
                        Keywords: ["Key", "Value"],  Variables: ["Key", "Value"], Score: 1.0,
                        StartDate: Date(), EndDate: Date(), Uploaded: Date(), LastUpdated:Date(),
                        RepositoryID: "ACB", Manuscripts: "Manuscripts",
                        PrimaryResearcher: "Adam", Manager: "Adam", UploadedBy: "Adam", Organizations: "Cytegeist")
    
    var body: some View {
        VStack {
            Text(rec.Keywords.joined())
            HStack
            {
                Text(rec.PrimaryResearcher)
                Text("Experiment:")
                Text(rec.ExperimentName)
            }
            HStack
            {
                Text("Purpose:") .font(.title3)
                Text(rec.Purpose)
            }
            HStack
            {
                Text("Conclusion:")  .font(.title3)
                Text(rec.Conclusion)
            }
            HStack
            {
                Text("Variables:") .font(.title3)
                Text(rec.Variables.joined())
            }
            HStack
            {
                Text("Organizations:") .font(.title3)
                Text(rec.Organizations)
            }
            HStack
            {
                Text("Start:") .font(.title3)
                Text(dateFormatter.string(from: rec.StartDate))
                Text("End:").font(.title3)
                Text(dateFormatter.string(from: rec.EndDate))
                Text("Uploaded:").font(.title3)
                Text(dateFormatter.string(from: rec.Uploaded))
                Text("Last Update:").font(.title3)
                Text(dateFormatter.string(from: rec.LastUpdated))
            }//.border()
            
            HStack
            {
                Text("FlowRepository ID:").font(.title3)
                Text(rec.RepositoryID)
                Text(rec.Manuscripts)
            }//.border(0.4)
        }
    }
    
}

