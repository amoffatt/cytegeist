//
//  MIFlowCyt.swift
//  CytegeistCore
//
//  Created by Adam Treister on 9/18/24.
//

import SwiftUI
import CytegeistLibrary


struct FlowRepoDetailView : View
{
    var exp: FRExperiment
    var body: some View {
        VStack {
            header.padding(.bottom, 24)
            mainbody
            Spacer(minLength: 16)
            VStack {
                source.padding(.bottom, 8)
                dates.padding(.bottom, 8)
                stats.padding(.bottom, 8)
                }
            }
        }
    //---------------------------------------------------------------------
    var header: some View {
        VStack
        {
            HStack
            {
                Text(exp.LastUpdate)
                Spacer()
                HStack {
                    Spacer()
                    Text(exp.RepID)
                    Spacer()
                    
                    Text("Score: " + exp.MifScore)
                    Spacer()
                }
            }
         HStack
            {
                Text(exp.ExpName).font(.title2)
                Spacer()
            }
        }.toolbar(content: {
            Button("Repository", action: repo)
            if !exp.ManuscriptUrl.isEmpty {
                Button("Manuscript", action: opener)
            }
        })
    }
    func repo()
    {
        @Environment(\.openURL) var openURL
        let flowrepo = "http://flowrepository.org/id/"
        if let url = URL(string: flowrepo + exp.RepID) {
            openURL(url)
        }
    }
    func opener()
    {
        @Environment(\.openURL) var openURL
       let pubmed = "http://www.ncbi.nlm.nih.gov/pubmed/"
        let brackets: CharacterSet =   CharacterSet(["[" ,"]"])
        let id = exp.ManuscriptUrl.trimmingCharacters(in: brackets)
        if let url = URL(string: pubmed + id) {
            openURL(url)
        }
    }

    //---------------------------------------------------------------------
   var mainbody: some View {
        VStack
        {
            if !exp.Purpose.isEmpty && exp.Purpose != "None"  {
                HStack
                {
                    Text("Purpose:") .font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.Purpose).textSelection(.enabled).padding(20)
                    Spacer()
                }
                Spacer()
            }
            if !exp.Conclusion.isEmpty && exp.Conclusion != "None"  {
                HStack
                {
                    Text("Conclusion:")  .font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.Conclusion).textSelection(.enabled).padding(20)
                    Spacer()
                }
                Spacer()
            }
            if !exp.Comments.isEmpty && exp.Comments != "None"  {
                HStack
                {
                    Text("Comments:") .font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.Comments ).padding(20).textSelection(.enabled)
                    Spacer()
                }
                Spacer()
            }
            if !exp.Keywords.isEmpty && exp.Keywords != "None"  {
                HStack
                {
                    Text("Keywords:") .font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.Keywords ).padding(20).textSelection(.enabled)
                    Spacer()
                }
                Spacer()
            }
            
            if !exp.Design.isEmpty  && exp.Design != "None" {
                HStack  {
                    Text("Design:").font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.Design).padding(20).textSelection(.enabled)
                    Spacer()
                }
            }
            
            
            if !exp.QualControl.isEmpty  && exp.QualControl != "None" {
                HStack  {
                    Text("Quality Control:").font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.QualControl).padding(20).textSelection(.enabled)
                    Spacer()
                }
            }
            if !exp.QualControlUrl.isEmpty {
                HStack {
                    Text("QC Url:").font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.QualControlUrl).padding(20).textSelection(.enabled)
                    Spacer()
                }
            }
        }
    }

    //---------------------------------------------------------------------
    var source: some View {
        return  VStack {
            HStack
            {
                if !exp.PResearcher.isEmpty {
                    Text("Researcher:") .font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.PResearcher).padding(.leading, 20)
                    Spacer()
                }
                if !exp.PInvestigator.isEmpty {
                    Text("Investigator:") .font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.PInvestigator).padding(.leading,20)
                    Spacer()
                }
            }
            if !exp.Organizations.isEmpty && exp.Organizations != "None"  {
                HStack
                {
                    Text("Organizations:") .font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.Organizations).padding(.leading,20)
                    Spacer()
                }
            }
            if !exp.Funding.isEmpty && exp.Funding != "Not disclosed" {
                HStack
                {
                    Text("Funding:") .font(.title3).frame(width: 120, alignment: .leading)
                    Text(exp.Funding).padding(.leading,20)
                    Spacer()
                }
            }
        }
        
    }
    //---------------------------------------------------------------------
    var dates: some View {
        return HStack
        {
            HStack {
                VStack {
                    HStack {
                        Text("Start:") .font(.title3)
                        Text(exp.ExpStart).frame(width: 150, alignment: .leading)
                        Spacer()
                    }
                    HStack {
                        
                        Text("End:  ").font(.title3)
                        Text(exp.ExpEnd).frame(width: 150, alignment: .leading)
                        Spacer()
                    }
                }.frame(width: 245, alignment: .leading)
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
        }
    }
    
    //---------------------------------------------------------------------
   var stats: some View {
        return VStack{
            
            HStack
            {
                if !exp.hasWSP.isEmpty {
                    HStack {
                        Text("Workspace:").font(.title3)
                        Text(exp.hasWSP)
                    }.frame(width: 120, alignment: .leading)
                }
                if !exp.Attachments.isEmpty {
                    Text("Attachments:").font(.title3)
                    Text(exp.Attachments)
                    
                }
                Spacer()
            }
            VStack {
                HStack
                {
                    Text("Files").font(.title3)
                    Text(exp.Design_FCS_Count)
                    Text(exp.FCS_count)
                    Spacer()
                    
                }
                HStack
                {
                    Text("Events").font(.title3)
                    Text("Mean:").font(.title3)
                    Text(exp.Event_mean_K.preprocessK())
                    Text("Total:").font(.title3)
                    Text(exp.Event_total_K.preprocessK())
                    Spacer()
                }
                HStack {
                    Text("Size ").font(.title3)
                    Text("Mean:").font(.title3)
                    Text(exp.FCS_mean_MB.preprocessM())
                    Text(" Total: ").font(.title3)
                    Text(exp.FCS_total_MB.preprocessM())
                    Spacer()
                }
//                HStack  {
//                    Text("RepID:").font(.title3)
//                    Text(exp.RepID)
//                    Text("ExpID:").font(.title3)
//                    Text(exp.ExpID)
//                    Text("MifScore:").font(.title3)
//                    Text(exp.MifScore)
//                    Text("RepIDurl:").font(.title3)
//                    Text(exp.RepIDurl)
//                    Spacer()
//                }
                HStack {
                    Text("FCS Vers:").font(.title3)
                    Text(exp.FCSVers)
                    Text("Cytometer:").font(.title3)
                    Text(exp.Cytometer)
                    Spacer()
                }
                HStack  {
                    if !exp.Manuscripts.isEmpty {
                        Text("Manuscripts:").font(.title3)
                        Text(exp.Manuscripts)
                    }
                    if !exp.ManuscriptUrl.isEmpty {
                        Text("ManuscriptUrl:").font(.title3)
                        Text(exp.ManuscriptUrl)
                    }
                    Spacer()
                }
            }.padding(.bottom, 66)
        }
    }
    
   
    }

//-----------------------------------------------------------------
