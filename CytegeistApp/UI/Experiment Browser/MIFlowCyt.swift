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
//            Spacer(minLength: 36, maxLength: 36)
            HStack
            {
                Text(rec.PrimaryResearcher)
                Text("Experiment:").frame(width: 120)
                Text(rec.ExperimentName)
                Spacer()
            }
            HStack
            {
                Text("Purpose:") .font(.title3).frame(width: 120, alignment: .leading)
                Text(rec.Purpose)
                Spacer()
            }
            HStack
            {
                Text("Conclusion:")  .font(.title3).frame(width: 120, alignment: .leading)
                Text(rec.Conclusion)
                Spacer()
            }
            HStack
            {
                Text("Variables:") .font(.title3).frame(width: 120, alignment: .leading)
                Text(rec.Variables.joined())
                Spacer()
            }
            HStack
            {
                Text("Organizations:") .font(.title3).frame(width: 120, alignment: .leading)
                Text(rec.Organizations)
                Spacer()
            }
            HStack
            {
                VStack {
                    HStack {
                        Text("Start:") .font(.title3)
                        Text(dateFormatter.string(from: rec.StartDate))
                        Spacer()
                    }
                    HStack {
                        
                        Text("End:").font(.title3)
                        Text(dateFormatter.string(from: rec.EndDate))
                        Spacer()
                    }
                }.frame(width: 120, alignment: .leading)
                VStack {
                    HStack {
                        Text("Uploaded:") .font(.title3)
                        Text(dateFormatter.string(from: rec.Uploaded))
                        Spacer()
                    }
                    HStack {
                        
                        Text("Last Update:").font(.title3)
                        Text(dateFormatter.string(from: rec.LastUpdated))
                        Spacer()
                    }
                    
                }.frame(width: 200, alignment: .leading)
                Spacer()
            }
            HStack
            {
                Text("FlowRepository ID:").font(.title3)
                Text(rec.RepositoryID)
                Text(rec.Manuscripts)
                Spacer()
            }//.border(0.4)
            Spacer()
        }
    }
//    
//    func Line(_ prompt: String, _ value: String, _ width: Int) -> any View {
//
//         var body : any View {
//             HStack
//            {    Text(prompt).frame(width: width)
//                Text(value)
//                Spacer()
//            }
//            
//        }
//    }
}



