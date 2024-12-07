////
////  Lymphocytes.swift
////  CytegeistApp
////
////  Created by Adam Treister on 12/6/24.
////
//
//let cds = ["CD3", "CD4","CD5", "CD8", "CD10", "CD14", "CD16", "CD19", "CD20", "CD21", "CD24","CD27", "CD28", "CD33", "CD34", "CD38", "CD45", "CD45RA", "CD56", "CD94", "CD161", "CD197"]
//let others = [ "CXCR5", "HLADR","IgA","IgD", "IgG", "IgM", "Ja18", "TCRVa24", "Tfh", "Th1", "Th2", "Th9", "Th17" , "Th22" ]
//let markers = cds + others
//
//let lymphocytes = { "Lymphocyte", "CD45+", [
//    {  "B" , "CD3-CD14-CD33-CD34-", [
//        {    "B cell" ,   "CD19+CD20+CD56-", [
//            { "Transitional",   "CD27-CD5+", [
//                { "CD10+CD38+CD24+", "CD10+CD38+CD24+", [
//                    { "T1" ,"IgM+IgD-" },
//                    { "T2",  "IgM+IgD+"},
//                    { "T3",  "IgM-IgD+"} ] } ]}
//            
//            { "Naive mature resting" , "CD27-CD38-CD5-CD24-" },
//            { "Memory", " CD27+CD38-CD24+" , [
//                { "IgD+ only unswitched" ,"IgD+IgM-"},
//                { "unswitched", "IgD+IgM+"},
//                { "IgA memory", "IgD-IgM-IgA+"},
//                { "IgG memory", "IgD-IgM-IgG+"}] },
//            
//            { "(B-1)", ""},
//            { "(B-2)", ""},
//            
//            { "Atypical/DN Memory", "CD27-CD38-", [
//                { "DN1", "CD21+CXCR5+" },
//                { "DN2", "CD21-CXCR5-" }]
//            },
//            { "Regulatory", "CD27+CD38-IgD+IgM+"}
//            
//        ] },
//        { "Non-B/T", "CD19-CD20-CD56+"},
//        { "ASC", " CD19+CD20-CD56-"}
//    ] },
//    
//    
//    { "NK" , "CD16+", [
//        { "CD56 bright" , "CD16+CD56+"},
//        { "CD56 dim",  "CD16+CD56-"},
//        { "Conventional",  "CD94+CD161+"},
//        { "CD94-CD161-", "CD94-CD161-"},
//        { "CD94+CD161-", "CD94+CD161-"},
//        { "CD94-CD161+", "CD94-CD161+"} ]},
//    
//    { "NKT" ,      "CD19-CD20-CD56+TCRgd-", [
//        { "CD4+CD8-",    "CD4+CD8-" },
//        { "CD4+CD8+",    "CD4+CD8+"},
//        { "CD4-CD8+",    "CD4-CD8+"},
//        { "CD4-CD8-",    "CD4-CD8-"},
//        { "Type 1",        "TCRVa24-Ja18+", [
//            { "CD94+" ,     "CD94+"},
//            { "CD94-",      "CD94-"},
//            { "Helper",   "" } ]}
//        { "Type 2"  " TCRVa24-Ja18-" , [
//            {   "CD94+",      "CD94+"},
//            {   "CD94-",      "CD94-"},
//            {  "Helper" ,       ""} ]} ] },
//    
//    { "T",   "CD34-CD45+CD3+CD14-CD33-",  [
//        { "CD4",  "CD4+",  [
//            { "ICOS?PD-1",   "ICOS?PD-1", [
//                {  "HLADR+CD38+",  "HLADR+CD38+"},
//                {  "HLADR-CD38+",   "HLADR-CD38+"},
//                {  "HLADR+CD38-",   "HLADR+CD38-"},
//                {  "HLADR-CD38-" ,  "HLADR-CD38-"} ] },
//            
//            {  "naive memory",   "CD197+CD45RA+", [
//                {  "early" ,        "CD28+CD27+" },
//                {  "early-like",    "CD28+CD27-" },
//                {  "intermediate",  "CD28-CD27+" },
//                {  "terminal",      "CD28-CD27-"} ] }
//            
//            {  "central memory",   "CD197+CD45RA-", [
//                {  "early" ,        "CD28+CD27+" },
//                {  "early-like",    "CD28+CD27-" },
//                {  "intermediate",  "CD28-CD27+" },
//                {  "terminal",      "CD28-CD27-"} ] }
//            
//            {  "effector memory",   "CD197-CD45RA-", [
//                {  "early" ,        "CD28+CD27+" },
//                {  "early-like",    "CD28+CD27-" },
//                {  "intermediate",  "CD28-CD27+" },
//                {  "terminal",      "CD28-CD27-"} ] },
//            
//            {  "Effector",  "CD197-CD45RA+"  },
//            {  "RA-terminal", "CD28-CD27-"   },
//              
//            { "CD161+", "CD161+"  },
//            { "CD161-", "CD161-"  },
//            { "CD57+", "CD57+"  },
//            { "CD57-", "CD57-"  },
//            { "CD85j+", "+CD85j+"  },
//            { "CD85j-", "CD85j-"  },
//            { "Tfh+", "Tfh+"  },
//            { "Tfr+ ", "Tfr+"  },
//            { "Th1+", "Th1+"  },
//            { "Th2+", "Th2+"  },
//            { "Th9+", "Th9+"  },
//            { "Th17+", "Th17+"},
//            {  "Th22+" "Th22+"   },
//            
//            {  "Treg",  "CD39+", [
//                {  "CD161+CD45RA+",     "CD161+CD45RA+" },
//                {  "CD161+CD45RA-",     "CD161+CD45RA-" },
//                {  "CD161-CD45RA+",     "CD161-CD45RA+" },
//                {  "CD161-CD45RA-",     "CD161-CD45RA-" }] }
//        ] },
//         
//        
//        { "CD8", "CD8+", [
//            { "ICOS?PD-1",   "ICOS?PD-1", [
//                {  "HLADR+CD38+",  "HLADR+CD38+"},
//                {  "HLADR-CD38+",   "HLADR-CD38+"},
//                {  "HLADR+CD38-",   "HLADR+CD38-"},
//                {  "HLADR-CD38-" ,  "HLADR-CD38-"} ] },
//            
//            {  "naive memory",   "CD197+CD45RA+", [
//                {  "early" ,        "CD28+CD27+" },
//                {  "early-like",    "CD28+CD27-" },
//                {  "intermediate",  "CD28-CD27+" },
//                {  "terminal",      "CD28-CD27-"} ] }
//            
//            {  "central memory",   "CD197+CD45RA-", [
//                {  "early" ,        "CD28+CD27+" },
//                {  "early-like",    "CD28+CD27-" },
//                {  "intermediate",  "CD28-CD27+" },
//                {  "terminal",      "CD28-CD27-"} ] }
//            
//            {  "effector memory",   "CD197-CD45RA-", [
//                {  "early" ,        "CD28+CD27+" },
//                {  "early-like",    "CD28+CD27-" },
//                {  "intermediate",  "CD28-CD27+" },
//                {  "terminal",      "CD28-CD27-"} ] },
//            
//            {  "Effector",  "CD197-CD45RA+"  },
//            {  "RA-terminal", "CD28-CD27-"   } ] }
//    ] } ] }
//        
//    
