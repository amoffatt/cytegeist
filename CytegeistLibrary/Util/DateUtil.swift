//
//  DateUtil.swift
//  CytegeistLibrary
//
//  Created by Aaron Moffatt on 8/21/24.
//

import Foundation


public extension Date {
    static var currentYear:Int { Date.now[.year] }
    
    subscript(_ component:Calendar.Component) -> Int {
        Calendar.current.component(component, from: self)
    }
}
