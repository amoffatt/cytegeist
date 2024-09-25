//
//  FormattingUtil.swift
//  CytegeistLibrary
//
//  Created by Aaron Moffatt on 8/21/24.
//

import Foundation


public let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
//    formatter.hasThousandSeparators = false
    formatter.usesSignificantDigits = true
    return formatter
}()

public let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()
