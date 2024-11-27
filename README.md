#  Cytegeist 

SwiftUI Data analysis for flow cytometry files (FCS)
![Screenshot](Screenshot.png)

----
Most of the domain specific code is in *Core*

The primary model object is **Experiment**<br>
It contains a list of **Samples**<br>

**Samples** have a URL to the data file<br>
They have a **meta** dictionary containing ~100 keyword-value pairs<br>
    
A Sample contains an AnalysisNode called **tree**<br>
AnalysisNodes have a list of **children**, which are also AnalysisNodes<br>
    
Each AnalysisNode contains one **gate**, which is the predicate applied to its parent to yield a population
    
Currently gates, are geometric regions in one or two dimensions, but any function on a population is a **gate**<br>
    
Each AnalysisNode has one **ChartDef**, which describes how to display the population<br>


----
The main view object is the **ExperimentView**<br>

It contains a **Sidebar**, **SampleList**, **AnalysisList** & **ReportPanel**<br>  
The **ReportPanel** is toggled between **GatingView**, **CGTableView** and **CGLayoutView**<br>
