//
//  Smoothing.swift
//  CytegeistCore
//
//  Created by Adam Treister on 8/23/24.
//

import Foundation

let radLowRes:Int = 8
let radHighRes:Int = 24
let gSmoothingLowresolution = 64
let gSmoothingHighresolution = 256
let kMaxRadHigh = 13.5 // was 9;
let kMaxRadLow = 6
let reflect = true

let kMatricesToBuild = 256;
 
var initialized = false
var kernels = [[Double]]  ()      //kMatricesToBuild*2+1
var kernelSizes = [Int] () //kMatricesToBuild*2+1

struct Smoother
{
        //------------------------------------------------------------------------
    func matrixSize( bins: Int, hiRes: Bool) -> Int
    {
        let radius = hiRes ?  radHighRes : radLowRes;
        let sq = sqrt(Double(bins))
        return  Int(Double(radius) / sqrt(sq) + 0.9999);
    }
        //------------------------------------------------------------------------
    init()
    {
        if initialized   { return }
        for idx in 1 ... kMatricesToBuild          // low res
        {
            let binCt = idx;
            let nElements = matrixSize(bins: binCt, hiRes: false);
            kernelSizes[idx] = nElements;
            kernels[idx] = smoothingMatrix(bins: Double(binCt), mxSize: nElements, hiRes: false);
        }
        
        for idx  in kMatricesToBuild + 1 ... 2 * kMatricesToBuild           // high res
        {
            let binCt = idx;
            let nElements = matrixSize(bins: binCt,hiRes: true);
            kernelSizes[idx] = nElements;
            kernels[idx] = smoothingMatrix(bins: Double(binCt),  mxSize: nElements, hiRes: true);
        }
        initialized = true;
    }
    
    
        //------------------------------------------------------------------------
    func smoothingMatrix(bins: Double, mxSize: Int, hiRes: Bool) -> [Double]
    {
        let radius = hiRes ?  radHighRes : radLowRes;
        let sq = sqrt(bins);
        let nDevs = 2.4
        let x = nDevs/Double(radius)
        let factor = -0.5 * sq * x * x
        var matrix = [Double]()
        
        for i in 0...mxSize {
            matrix.append(exp(factor * Double(i * i)));
        }
        
        var matrixTotal = 0.0;
        for i in -mxSize...mxSize {
            for j in -mxSize...mxSize {
                matrixTotal += matrix[abs(i)] * matrix[abs(j)];
            }
        }
        
        let rootTotal = sqrt(matrixTotal);
        
        for i in 0...mxSize {
            matrix[i]  /= rootTotal;
        }
        return matrix
    }
        //------------------------------------------------------------------------
    
    func smoothInPlace(srcMatrix: inout [Double],  inRows: Int, inCols: Int, hiRes: Bool)
    {
        let mIdxOffset:Int = hiRes ? kMatricesToBuild : 0;
        let radius:Int = hiRes ?  radHighRes : radLowRes;
        let matrixCols = inCols + 2 * radius;
        let matrixArea = (inRows + 2 * radius) * matrixCols;
        
        var localSmoothMatrix = [Double]()
        var destMatrix = [Double]()
        for ii in 0 ..< matrixArea {
            destMatrix.append(0.0)
        }
        
        for row in radius ..< radius + inRows  {
            for col in radius ..< radius + inCols {
                
                var smoothMatrix: [Double]
                var nElements: Int
                let i1 = (row - radius) * inCols + (col - radius);
                let binCt = srcMatrix[i1];
                if (binCt == 0.0)   { continue }
                
                if binCt <= Double(kMatricesToBuild)
                {
                    let i = Int(binCt) + mIdxOffset
                    nElements = kernelSizes[i]
                    smoothMatrix = kernels[i]
               }
                else                                            // not precomputed
                {
                    nElements = matrixSize(bins: Int(binCt), hiRes: hiRes)
                    smoothMatrix = smoothingMatrix(bins: binCt, mxSize: nElements, hiRes: hiRes)
                }
                
                destMatrix[row * matrixCols + col] += smoothMatrix[0] * smoothMatrix[0] * binCt;    // 0,0 point
                
                for i in 1 ..< nElements
                {
                    let k3 = smoothMatrix[0] * smoothMatrix[i] * binCt                  // 0,y and x,0 points
                    let i1 = (row + i) * matrixCols + (col    )
                    let i2 = (row - i) * matrixCols + (col    )
                    let i3 = (row    ) * matrixCols + (col + i)
                    let i4 = (row    ) * matrixCols + (col - i)
                    destMatrix[i1] += k3
                    destMatrix[i2] += k3
                    destMatrix[i3] += k3
                    destMatrix[i4] += k3
                }
                
                for i in 1 ... nElements                                               // all other points
                {
                    let k2 = smoothMatrix[i] * binCt
                    for j in 1 ... nElements
                    {
                        let k3 = k2 * smoothMatrix[j]
                        let i1 = (row + j) * matrixCols + (col + i)
                        let i2 = (row - j) * matrixCols + (col + i)
                        let i3 = (row + j) * matrixCols + (col - i)
                        let i4 = (row - j) * matrixCols + (col - i)
                        destMatrix[i1] += k3
                        destMatrix[i2] += k3
                        destMatrix[i3] += k3
                        destMatrix[i4] += k3
                    }
                }
            }
            
            if (reflect) {
                reflectMargins(destMatrix: &destMatrix,inRows: inRows, inCols: inCols, margin: radius)
            }
                // copy the destMatrix back onto srcMatrix
            for row in radius ..< (radius + inRows) {
                for col in radius ..< radius + inCols    {
                    let idx = (row-radius) * inCols + (col-radius);
                    srcMatrix[idx] = destMatrix[row * matrixCols + col];
                }
            }
        }
    }
    
    
        // reflect smoothed events outside of the matrix back symmetrical to the edge.
        // The first pixel outside is added to the last spot inside.
    
    func reflectMargins(destMatrix: inout [Double], inRows: Int , inCols: Int , margin:  Int)
    {
        let colsInMatrix = inCols + margin + margin;
        let rightEdge = inCols + margin;                                // the edges of the part to be kept
        let topEdge = inRows + margin;
        
        for row in 0 ..< margin       {
            for col in 0 ..< rightEdge + margin    {
                let i = (margin-1+(margin-row)) * colsInMatrix + col;
                let j = row * colsInMatrix + col;
                destMatrix[i] += destMatrix[j];
            }
        }
        
        for row in topEdge+1 ..< topEdge + margin  {
            for col in 0 ..< rightEdge + margin    {
                let i = (topEdge+1-(row-topEdge)) * colsInMatrix + col;
                let j = row * colsInMatrix + col;
                destMatrix[i] += destMatrix[j];
            }
        }
        
        for col in 0 ..< margin       {
            for row in margin ..< topEdge    {
                let i = row * colsInMatrix +  (margin-1+(margin-col));
                let j = row * colsInMatrix + col;
                destMatrix[i] += destMatrix[j];
            }
        }
        
        for col in rightEdge + 1 ..< rightEdge + margin       {
            for row in margin ..< topEdge    {
                let  i = row * colsInMatrix +  (rightEdge+1-(col-rightEdge));
                let j = row * colsInMatrix + col;
                destMatrix[i] += destMatrix[j];
            }
        }
    }
        //----------------------------------------------------------------------------------
        // Same algorithm as Smooth, in one dimension only
    
    func smoothHistogram(srcBins: [Double], inNBins: Int, hiRes: Bool) -> [Double]
    {
        let mIdxOffset = hiRes ? kMatricesToBuild : 0
        let radius:Int = hiRes ?  radHighRes : radLowRes
        
        let matrixBins = inNBins + 2 * radius
        var matrix = [Double]()
        var smoothMatrix = [Double]()
        var nElements: Int
        var destBins = [Double]()
        
        for bin in radius ..< radius + inNBins
        {
            let binCt = srcBins[bin - radius]
            if binCt == 0.0 { continue }
            
            if binCt <= Double(kMatricesToBuild)
            {
                let i = Int(binCt)+mIdxOffset
                nElements = kernelSizes[i]
                smoothMatrix = kernels[i]
            }
            else                                            // not precomputed
            {
                nElements = matrixSize(bins: Int(binCt),hiRes: hiRes)
                smoothMatrix = smoothingMatrix(bins: binCt , mxSize: nElements, hiRes: hiRes)
            }
            
            matrix[bin] += smoothMatrix[0] * binCt;    // 0 point
            for i in 1 ..< nElements        // points to either side
            {
                let k3 = smoothMatrix[i] * binCt;
                matrix[bin + i] += k3;
                matrix[bin - i] += k3;
            }
            
            if reflect
            {
                for i in 1 ..< radius
                {
                    let leftEdge = radius;
                    let rightEdge = radius + inNBins;
                    matrix[leftEdge + i - 1] += matrix[leftEdge - i];
                    matrix[rightEdge - i + 1] += matrix[rightEdge + i];
                }
            }
//                // copy the destMatrix back onto srcMatrix
//            for bin in radius ..< radius + inNBins {
//                destBins[bin-radius] = matrix[bin]
//            }
        }
        return matrix
    }
}
