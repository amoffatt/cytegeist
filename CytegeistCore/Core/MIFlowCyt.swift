//
//  MIFlowCyt.swift
//  CytegeistCore
//
//  Created by Adam Treister on 9/18/24.
//

import SwiftUI


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
    var rec : MIFlowCyt
    
    var body: any View {
        VStack {
            Text(rec.Keywords)
            HStack
            {
                Text(rec.PrimaryResearcher)
                Text("Experiment:")
                Text(rec.ExperimentName)
            }
            HStack
            {
                Text("Purpose:").font(.bold)      
                Text(rec.Purpose)
            }
            HStack
            {
                Text("Conclusion:") .font(.bold)     
                Text(rec.Conclusion)
            }
            HStack
            {
                Text("Variables:").font(.bold)      
                Text(rec.Variables)
            }
            HStack
            {
                Text("Organizations:").font(.bold)     
                Text(rec.Organizations)
            }
            HStack
            {
                Text("Start:").font(.bold)
                Text(rec.StartDate)
                Text("End:").font(.bold)
                Text(rec.EndDate)
                Text("Uploaded:").font(.bold)
                Text(rec.Uploaded)
                Text("Last Update:").font(.bold)
                Text(rec.LastUpdated)
            }.border(0.4)
            
            HStack
            {
                Text("FlowRepository ID:").font(.bold)
                Text(rec.RepositoryID)
                Text(rec.Manuscripts)
            }.border(0.4)
        }
    }
    
}

