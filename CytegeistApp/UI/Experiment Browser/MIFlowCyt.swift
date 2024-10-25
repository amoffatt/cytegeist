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
//    var rec = MIFlowCyt(ExperimentName: "20241001", Purpose: "Test Experiment", Conclusion: "Browser works",
//                        Keywords: ["Key", "Value"],  Variables: ["Key", "Value"], Score: 1.0,
//                        StartDate: Date(), EndDate: Date(), Uploaded: Date(), LastUpdated:Date(),
//                        RepositoryID: "ACB", Manuscripts: "Manuscripts",
//                        PrimaryResearcher: "Adam", Manager: "Adam", UploadedBy: "Adam", Organizations: "Cytegeist")
//    
    
    var exp: FRExperiment
    var body: some View {
        VStack {
//            Spacer(minLength: 36, maxLength: 36)
            HStack
            {
                Text(exp.PResearcher)
                Text("Experiment:").frame(width: 120)
                Text(exp.ExpName)
                Spacer()
            }
            HStack
            {
                Text("Purpose:") .font(.title3).frame(width: 120, alignment: .leading)
                Text(exp.Purpose)
                Spacer()
            }
            HStack
            {
                Text("Conclusion:")  .font(.title3).frame(width: 120, alignment: .leading)
                Text(exp.Conclusion)
                Spacer()
            }
            HStack
            {
                Text("Variables:") .font(.title3).frame(width: 120, alignment: .leading)
                Text(exp.Keywords )
                Spacer()
            }
            HStack
            {
                Text("Organizations:") .font(.title3).frame(width: 120, alignment: .leading)
                Text(exp.Organizations)
                Spacer()
            }
            HStack
            {
                VStack {
                    HStack {
                        Text("Start:") .font(.title3)
                        Text(exp.ExpStart)
                        Spacer()
                    }
                    HStack {
                        
                        Text("End:").font(.title3)
                        Text(exp.ExpEnd)
                        Spacer()
                    }
                }.frame(width: 120, alignment: .leading)
                VStack {
                    HStack {
                        Text("Uploaded:") .font(.title3)
                        Text(exp.UploadDate)
                        Spacer()
                    }
                    HStack {
                        
                        Text("Last Update:").font(.title3)
                        Text(exp.LastUpdate)
                        Spacer()
                    }
                    
                }.frame(width: 200, alignment: .leading)
                Spacer()
            }
            HStack
            {
                Text("FlowRepository ID:").font(.title3)
                Text(exp.RepID)
                Text(exp.Manuscripts)
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



public class FRExperiment : Identifiable, Codable {
    public static func == (lhs: FRExperiment, rhs: FRExperiment) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id = UUID()
    var RepID: String = ""
    var RepIDurl: String = ""
    var ExpID: String = ""
    var ExpName: String = ""
    var Purpose: String = ""
    var Conclusion: String = ""
    var Comments: String = ""
    var Keywords: String = ""
    
    var ManuscriptUrl: String = ""
    var Manuscripts: String = ""
    var Design: String = ""
    var Design_FCS_Count: String = ""
    var MifScore: String = ""
    var PResearcher: String = ""
    var PInvestigator: String = ""
    var UploadAuth: String = ""
    
    var ExpDates: String = ""
    var ExpStart: String = ""
    var ExpEnd: String = ""
    var UploadDate: String = ""
    var LastUpdate: String = ""
    var Organizations: String = ""
    var Funding: String = ""
    var QualControl: String = ""
    var QualControlUrl: String = ""
    
    var hasWSP: String = ""
    var Attachments: String = ""
    var Event_total_K: String = ""
    var Event_mean_K: String = ""
    var FCS_count: String = ""
    var FCS_total_MB: String = ""
    var FCS_mean_MB: String = ""
    var FCSVers: String = ""
    var Cytometer: String = ""
    
    init (tokens: [String])
    {
        print (tokens.count)
        if (tokens.count > 31) {
            self.RepID =  tokens[0]
            self.RepIDurl =  tokens[1]
            self.ExpID =  tokens[2]
            self.ExpName =  tokens[3]
            self.Purpose =  tokens[4]
            self.Conclusion =  tokens[5]
            self.Comments =  tokens[6]
            self.Keywords =  tokens[7]
            self.ManuscriptUrl =  tokens[8]
            self.Manuscripts =  tokens[9]
            self.Design =  tokens[10]
            self.MifScore =  tokens[11]
            self.PResearcher =  tokens[12]
            self.PInvestigator =  tokens[13]
            self.UploadAuth =  tokens[14]
            self.ExpDates =  tokens[15]
            self.ExpStart =  tokens[16]
            self.ExpEnd =  tokens[17]
            self.UploadDate =  tokens[18]
            self.LastUpdate =  tokens[19]
            self.Organizations =  tokens[20]
            self.Funding =  tokens[21]
            self.QualControl =  tokens[22]
            self.QualControlUrl =  tokens[23]
            self.hasWSP =  tokens[24]
            self.Attachments =  tokens[25]
            self.Event_total_K =  tokens[26]
            self.Event_mean_K =  tokens[27]
            self.FCS_count =  tokens[28]
            self.FCS_total_MB =  tokens[29]
            self.FCSVers =  tokens[30]
            self.Cytometer =  tokens[31]

        }
//        
//        , RepIDurl: token[1], ExpID: token[2], ExpName: token[3], Purpose: token[4], Conclusion: token[5], Comments: token[6], Keywords: token[7], ManuscriptUrl: token[8], Manuscripts: token[9], Design: token[10], Design_FCS_Count: token[11], MifScore: token[12], PResearche: token[13], PInvestigator: token[14], UploadAuth: token[15], ExpDates: token[16], ExpStart: token[17], ExpEnd: token[18], UploadDate: token[19], LastUpdate: token[20], Organizations: token[21], Funding: token[22], QualControl: token[23], QualControlUrl: token[24], hasWSP: token[25], Attachments: token[26], Event_total_K: token[27], Event_mean_K: token[28], FCS_count: token[29], FCS_total_MB: token[30], FCSVers: token[31], Cytometer: token[32]
    }
    init( RepID: String, RepIDurl: String, ExpID: String, ExpName: String, Purpose: String, Conclusion: String, Comments: String, Keywords: String, ManuscriptUrl: String, Manuscripts: String, Design: String, Design_FCS_Count: String, MifScore: String, PResearcher: String, PInvestigator: String, UploadAuth: String, ExpDates: String, ExpStart: String, ExpEnd: String, UploadDate: String, LastUpdate: String, Organizations: String, Funding: String, QualControl: String, QualControlUrl: String, hasWSP: String, Attachments: String, Event_total_K:String, Event_mean_K:String, FCS_count: String, FCS_total_MB: String, FCSVers: String, Cytometer: String )
    {
        self.RepID = RepID
        self.RepIDurl = Manuscripts
        self.ExpID = ExpID
        self.ExpName = ExpName
        self.Purpose = Purpose
        self.Conclusion = Conclusion
        self.Comments = Comments
        self.Keywords = Keywords
        self.ManuscriptUrl = ManuscriptUrl
        
        
        self.Manuscripts = Manuscripts
        self.Design = Design
        self.Design_FCS_Count = Design_FCS_Count
        self.MifScore = MifScore
        self.PResearcher = PResearcher
        self.PInvestigator = PInvestigator
        self.UploadAuth = UploadAuth
        self.ExpDates = ExpDates
        self.ExpStart = ExpStart
        self.ExpEnd = ExpEnd
        self.UploadDate = UploadDate
        self.LastUpdate = LastUpdate
        self.Organizations = Organizations
        self.Funding = Funding
        self.QualControl = QualControl
        self.QualControlUrl = QualControlUrl
        
        self.hasWSP = hasWSP
        self.Attachments = Attachments
        self.Event_total_K = Event_total_K
        self.Event_mean_K = Event_mean_K
        self.FCS_count = FCS_count
        self.FCS_total_MB = FCS_total_MB
        self.FCSVers = FCSVers
        self.Cytometer = Cytometer
    }
    
    
    let colNames: [String] =  ["RepID","RepIDurl","ExpID","ExpName","Purpose","Conclusion","Comments","Keywords",
                               "ManuscriptUrl","Manuscripts","Design","Design_FCS_Count","MifScore","PResearcher","PInvestigator","UploadAuth",
                               "ExpDates","ExpStart","ExpEnd","UploadDate","LastUpdate","Organizations","Funding","QualControl","QualControlUrl",
                               "hasWSP","Attachments","Event_total_K","Event_mean_K","FCS_count","FCS_total_MB","FCS_mean_MB","FCSVers","Cytometer"]
    
    

}
