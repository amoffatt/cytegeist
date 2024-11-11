//
//  CGTableResult.swift
//  CytegeistApp
//
//  Created by Adam Treister on 11/9/24.
//

import Foundation
import SwiftUI

public struct CGTableResultView : View {
    @State var selection = Set<TColumn.ID>()
    @State var sortOrder = [KeyPathComparator(\TColumn.pop, order: .forward), KeyPathComparator(\TColumn.parm, order: .forward)]
    @State var columnCustomization = TableColumnCustomization<TColumn>()

    let table: CGTableResult
    


    public var body: some View {
            //            Table (of: TColumn.Type, selection: $selectedColumns)
        Table (table.rows)
        {
            let colnames = table.colNames()
            TableColumnForEach(0..<colnames.count, id: \.self) { i in
                TableColumn("\(colnames[i])") { _ in  Text(colnames[i])  }               
            }
        }
    }
}
//------------------------------------------------------------------------------------
