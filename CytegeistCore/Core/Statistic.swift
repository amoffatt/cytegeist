//
//  Statistic.swift
//  CytegeistApp
//
//  Created by Adam Treister on 9/17/24.
//

import Foundation

public enum EStatistic : Codable
{
    var text: String
    {
        switch (self)
        {
            case .mean:         return "mean:"
            case .stdev:        return "stdev:"
            case .median:       return "median:"
            case .cv:           return "cv:"
            case .freq:         return "freq:"
            case .freqOf:       return "freqOf:"
        }
        
    }
    case mean
    case stdev
    case median
    case cv
    case freq
    case freqOf
}


//
//public struct Statistic : Codable, Hashable
//{
//    var stat: EStatistic = EStatistic.freq
//    var dims: String = ""
//    var value: Double?
//    
//    init()    {}
//}
