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
//struct LogicleTransformation  {
//    /**
//     * The function (with only T, w, and m specified) to use with the root finder. The
//     * Parameter Value must be specified for each Event before calling the root finder
//     * since it changes for each Event.
//     */
//    var  logicle: LogicleFunction
//    
//    /**
//     * We can use w to make our root finding guess slightly better. The Logicle function
//     * grows exponentially around w (in both directions) where it = 0 (when there is no
//     * parameterValue (i.e., parameterValue = 0). So we'll use a small interval
//     * around w as our initial guess since it will, in most cases contain the root.
//     */
//    var  w: Double
//    
//    /**
//     * Constructor.
//     * @param name The name of the Transformation.
//     * @param parameterReference A reference to the parameter it transforms.
//     * @param t See class documentation.
//     * @param w See class documentation.
//     * @param m See class documentation.
//     * @throws InvalidTransformationException Thrown if the value for p (given w) could not
//     * be calculated.
//     */
//    init ( name: String,  parameterReference: ParameterReference,  t: Double,  w: Double,  m: Double) throws InvalidTransformationException {
//        super(name, parameterReference);
//        
//        self.w = w;
//        do try {
//            logicle = new LogicleFunction( t, w, m);
//        } catch (RootFindingException ex) {
//            throw new InvalidTransformationException("Logicle Transformation " + name + " could not solve for p value. " + ex.getMessage());
//        }
//    }
//    
//    protected double applyTransformation(double parameterValue) throws RootFindingException {
//        logicle.setParameterValue(parameterValue);
//        try {
//            return FunctionUtils.findRoot(logicle, w - 10, w + 10);
//        } catch (RootFindingException ex) {
//            throw new RootFindingException(this.toString() + ex.getMessage());
//        }
//    }
//    
//    public String toString() {
//        return "Logicle " + super.toString();
//    }
//}
//
///**
// * <p>
// * The function whose root needs to be found for Logicle Transformations.
// * The function is defined as
// *
// * <p>
// * S(y; T, w, m) - parameterValue where
// *
// * <pre>
// * S(y; T, w, m) = { T * e ^ -(m - w) * (e ^ (y - w) - p ^ 2 * e ^ (-(y - w)/p) + p^2 - 1    if y >=w
// *                 { -(T * e ^ -(m - w) * (e ^ (w - y) - p ^ 2 * e ^ (-(w - y)/p) + p^2 - 1) otherwise
// * </pre>
// *
// * <p>
// * p is defined as w = 2 * ln(p) / (p + 1)
// *
// * <p>
// * The constants T, w (and thus, p), and m are specified at the time of construction, while
// * parameterValue is specified later since it changes for each event. Thus, this object
// * actually specifies a *family* of functions -- one for each different value of
// * parameterValue. Therefore, before performing the root finding, parameterValue must
// * be set to specify which of the functions in the family should be solved.
// *
// * @author echng
// *
// */
//struct LogicleFunction  {
//    var t: Double
//    var w: Double
//    var p: Double
//    var m: Double
//
//    var parameterValue: Double
//    
//    /**
//     * Constructor.
//     * @throws RootFindingException Thrown if p couldn't be calculated.
//     */
//    init(_ t: Double,_  w: Double,_  m: Double)  {
//        self.t = t;
//        self.w = w;
//        self.m = m;
//        
//        let pFunc = LogicleWidthPFunction(w)
//        self.p = FunctionUtils.findRoot(pFunc, 1, 1024);
//    }
//    
//    /**
//     * Sets the parameterValue. That is, it specifies which of the functions in the
//     * family should be solved when performing the root finding.
//     *
//     * @param parameter The parameterValue.
//     */
//    func setParameterValue( parameter: Double) {
//        parameterValue = parameter
//    }
//    
//   func value(_ y: Double) -> Double
//    {
//        if y >= w   {
//            return calculateS(y - w) - parameterValue
//        }
//        return -calculateS(w - y) - parameterValue
//    }
//    
//    /**
//     * Implements the S function for y >= w.
//     *
//     * @param y The function argument.
//     * @return The function value for the given argument.
//     */
//    func calculateS(_ exponent: Double) -> Double {
//        return t * exp(-(m - w)) *
//        (exp(exponent) - pow(p, 2) * exp(-(exponent) / p) +  pow(p, 2) - 1);
//    }
//}
//
///**
// * <p>
// * The function to calculate the p constant in the Logicle function. Given w, p is
// * defined as w = 2 * ln(p) / (p + 1). Thus we want to find the root of
// *
// * <p>
// * 2 * ln(p) / (p + 1) - w
// *
// * <p>
// * That is, p such that the function = 0. This object represents this function.
// *
// * @author echng
// *
// */
// struct LogicleWidthPFunction
//{
//    var w: Double
//    
//    init( _ w: Double) {      self.w = w;    }
//    
//     func value(p: Double) -> Double
//     {
//        return 2 * p * log(p) / (p + 1) - w;
//    }
//}
//----------------------------------------------------------------------

    
    public var maxLoops = 1000
    let initPLowBound = 1e-3
    let initPHighBound = 1e6
    let epsilon = 1e-12
    
struct Logicle {

        var T: Double
        var w: Double
        var m: Double
        var p: Double

     
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
    
