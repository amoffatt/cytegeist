//
//  InputUtil.swift
//  CytegeistLibrary
//
//  Created by Aaron Moffatt on 8/21/24.
//

import Foundation

#if canImport(AppKit)
import AppKit


public func anyModifiers() -> Bool{    return (optionKey() || shiftKey() || commandKey() || controlKey()) }
public func optionKey() -> Bool{    return NSEvent.modifierFlags.contains(.option)}
public func shiftKey() -> Bool{ return NSEvent.modifierFlags.contains(.shift) }
public func commandKey() -> Bool{ return NSEvent.modifierFlags.contains(.command) }
public func controlKey() -> Bool{ return NSEvent.modifierFlags.contains(.control) }

#endif
