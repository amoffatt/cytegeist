//
//  FRExperiment.swift
//  CytegeistApp
//
//  Created by Adam Treister on 10/28/24.
//

import Foundation


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
    var fulltext: String = ""
    var cytof: Bool = false
    var firstManuscript: Bool = false
    
    init (tokens: [String])
    {
        print (tokens.count)
        if (tokens.count > 33) {
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
            self.Design_FCS_Count =  tokens[11]
            self.MifScore =  tokens[12]
            self.PResearcher =  tokens[13]
            self.PInvestigator =  tokens[14]
            self.UploadAuth =  tokens[15]
            self.ExpDates =  tokens[16]
            self.ExpStart =  tokens[17]
            self.ExpEnd =  tokens[18]
            self.UploadDate =  tokens[19]
            self.LastUpdate =  tokens[20]
            self.Organizations =  tokens[21]
            self.Funding =  tokens[22]
            self.QualControl =  tokens[23]
            self.QualControlUrl =  tokens[24]
            self.hasWSP =  tokens[25]
            self.Attachments =  tokens[26]
            self.Event_total_K =  tokens[27]
            self.Event_mean_K =  tokens[28]
            self.FCS_count =  tokens[29]
            self.FCS_total_MB =  tokens[30]
            self.FCS_mean_MB =  tokens[31]
            self.FCSVers =  tokens[32]
            self.Cytometer =  tokens[33]
            
        }
    }
    public func setFlags( cytof: Bool, firstManuscript: Bool, fulltext: String)  {
        self.cytof = cytof
        self.firstManuscript = firstManuscript
        self.fulltext = fulltext
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
