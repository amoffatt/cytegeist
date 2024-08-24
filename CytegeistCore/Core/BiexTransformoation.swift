//
//  BiexTransformoation.swift
//  CytegeistCore
//
//  Created by Adam Treister on 8/24/24.
//

import Foundation

/**package org.flowcyt.facejava.transformation;
 * <p>
 * Applies a Logicle Transformation to a Parameter value. The transformation applied is:
 *
 * <p>
 * root(S(y; T, w, m) - parameterValue) where
 *
 * <ul>
 * <li>root() finds the root of the given function
 * <li>
 *     <pre>
 * S(y; T, w, m) = { T * e ^ -(m - w) * (e ^ (y - w) - p ^ 2 * e ^ (-(y - w)/p) + p^2 - 1    if y >=w
 *                 { -(T * e ^ -(m - w) * (e ^ (w - y) - p ^ 2 * e ^ (-(w - y)/p) + p^2 - 1) otherwise
 *     </pre>
 * </li>
 * <li>p is defined as w = 2 * ln(p) / (p + 1)
 * </ul>
 *
 * Thus, the transformation returns y such that, given T, w, and m,
 * S(y; T, w, m) = parameterValue
 *
 * @author echng
 */
    
    public var maxLoops = 1000
    let initPLowBound = 1e-3
    let initPHighBound = 1e6
    let epsilon = 1e-12
    
    struct Logicle {
        var T: Double
        var w: Double
        var m: Double
        var p: Double = 0
     
    init(T: Double, w: Double, m: Double)
    {
//      assert((T>0) && (w>0) && (m>0))
        self.T = T
        self.w = w
        self.m = m
        self.p = calculateP()
    }
    
    func getP() -> Double {   return p   }
    
    func logicle(_ x: Double) -> Double 
    {
        var lowerBound: Double = -T
        var upperBound: Double = T
        var r: Double = (upperBound + lowerBound) / 2
        var nCheck = maxLoops
        while (lowerBound + epsilon < upperBound && nCheck > 0)
        {
            if(s(y: r, firstTime: true) > x)
                {    upperBound = r  }
            else {   lowerBound = r     }
            r = (upperBound + lowerBound) / 2
            nCheck -= 1
        }
        return r;
    }
    
   func calculateP() -> Double {
       var lowerBound = initPLowBound
       var upperBound = initPHighBound
       var p = (upperBound + lowerBound) / 2
       var nCheck = maxLoops;
        
            // w = 2p*ln(p)/(p+1)
        while (lowerBound + epsilon < upperBound && nCheck > 0) {
            if (2.0 * p * log(p) / (p+1)) > w
                    {     upperBound = p    }
            else    {      lowerBound = p    }
            p = (upperBound + lowerBound) / 2
            nCheck -= 1
        }
        return p;
    }

    func s(y: Double) -> Double {    return s(y: y, firstTime: true)    }

    func  s(y: Double,  firstTime: Bool)  -> Double
    {
        if((y >= w) || (!firstTime))
        {
            return T * exp(-(m-w)) * (exp(y-w) - p*p*exp(-(y-w)/p) + p*p - 1)
        }
        return -1.0 * s(y: w-y, firstTime: false);
    }
}

//-------------------------------------------------------------------------
func test() {
        //        System.out.println("Creating Logicle T=1000, w=0.5, m=" + Math.log(10) * 4.5);
    let l =  Logicle(T: 1000,w: 0.5,m: log(10) * 4.5)
    
    let max = l.logicle(262144)
    let min = l.logicle(-1000)
    let step = (max - min) / 256.0
    var x = min
    while  x  < max
    {
        print(l.s(y: Double(x)))
        x += step
    }
}
    
