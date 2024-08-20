//
//  GraphicsUtil.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/19/24.
//

import Foundation
import SwiftUI


extension CGImage {
    var image:Image? {
#if canImport(AppKit)
        let nsImage = NSImage(cgImage: self, size: .init(width: width, height: height))
        return Image(nsImage: nsImage)
#elseif canImport(UIKit)
        let uiImage = UIImage(cgImage: self)
        return Image(uiImage: nsImage)

#else
        print("Error: Platform cannot convert CGImage to SwiftUI Image")
        return nil
#endif
        
    }
}


