//
//  Smoothing.swift
//  CytegeistCore
//
//  Created by Adam Treister on 8/23/24.
//

import Foundation
import CytegeistLibrary

let radLowRes:Int = 8
let radHighRes:Int = 24
let reflect = true
let nMatrices = 256;
 

struct Smoother
{
    var kernels = [[Double]] ()
    var kernelSizes = [Int] ()

//------------------------------------------------------------------------
//------------------------------------------------------------------------
    init()
    {
        kernels.append([1])
        kernelSizes.append(0)
        
        let totalKernels = 2 * nMatrices
        for idx in 1 ... totalKernels
        {
            let hiRes =  idx > nMatrices
            let nElements = matrixSize(bins: idx, hiRes: hiRes);
            kernelSizes.append(nElements)
            kernels.append(kernel(bins: idx, mxSize: nElements, hiRes: hiRes))
        }
    }

    private func matrixSize( bins: Int, hiRes: Bool) -> Int
    {
//        let radius = hiRes ?  radHighRes : radLowRes;
//        let sq = sqrt(sqrt(Double(bins)))
//        return  Int(Double(radius) / sq + 0.9999);
        
        
        let radius = hiRes ?  radHighRes : radLowRes;
        let sqrtZ = sqrt(Double(bins));
        let r = Double(radius) / (sqrt(sqrtZ));
        var matrixElements = Int(r);
        if (r - Double(matrixElements) > 0.0) {
            matrixElements += 1;
        }
        return matrixElements;
    }
   
    private func kernel(bins: Int, mxSize: Int, hiRes: Bool) -> [Double]
    {
        let radius = hiRes ?  radHighRes : radLowRes;
        let sq = sqrt(Double(bins));
        let nDevs = 2.4
        let x = nDevs/Double(radius)
        let factor = -0.5 * sq * x * x
        let matrix:[Double] = (0 ... mxSize).map( { exp(factor * Double($0 * $0)) } )
        
        var matrixTotal = 0.0
        for i in -mxSize...mxSize {
            for j in -mxSize...mxSize {
                matrixTotal += matrix[abs(i)] * matrix[abs(j)];
            }
        }
        let rootTotal = sqrt(matrixTotal)
        return matrix.map( { $0 / rootTotal } )
    }
//----------------------------------------------------------------------------------
    
    public func smooth1D(srcMatrix: [Double], nBins: Int, hiRes: Bool) -> [Double]
    {
        let kernelIdxOffset = hiRes ? nMatrices : 0
        let radius:Int = hiRes ?  radHighRes : radLowRes
        let destBinsCount = nBins + 2 * radius + 1
        var destArray = [Double](repeating:0, count: destBinsCount)
        
        for bin in radius ..< radius + nBins
        {
            let binHeight = srcMatrix[bin - radius]
            let intBinHeight = Int(binHeight)
            if intBinHeight == 0 { continue }
            
            var kernel1D:[Double]
            var nElements:Int
            
            if intBinHeight <= nMatrices
            {
                let i = intBinHeight + kernelIdxOffset
                nElements = kernelSizes[i]
                kernel1D = kernels[i]
            }
            else                                            // not precomputed
            {
                print("binHeight > 256")             // looks hinky, should be a dictionary of height to cached kernel
                nElements = matrixSize(bins: Int(binHeight), hiRes: hiRes)
                kernel1D = kernel(bins: Int(binHeight), mxSize: nElements, hiRes: hiRes)
            }
            
            destArray[bin] += kernel1D[0] * binHeight;    // 0 point
            for i in 1 ... nElements        // points to either side
            {
                let k3 = kernel1D[i] * binHeight;
                destArray[bin + i] += k3;
                destArray[bin - i] += k3;
            }
        }
            
        if reflect
        {
            for i in 1 ... radius
            {
                let leftEdge = radius;
                let rightEdge = radius + nBins;
                destArray[leftEdge + i - 1] += destArray[leftEdge - i];
                destArray[rightEdge - i + 1] += destArray[rightEdge + i];
            }
        }
                //                // used to copy the destMatrix back onto srcMatrix
                //            for bin in radius ..< radius + inNBins {
                //                destBins[bin-radius] = matrix[bin]
                //            }
        return Array(destArray[radius...(nBins + radius)])
    }
//------------------------------------------------------------------------
    
    public func smooth2D(srcMatrix: [Double], size:Tuple2<Int>, hiRes: Bool) -> [Double]
    {
        let rows = size.y
        let cols = size.x
        let idxOffset = hiRes ? nMatrices : 0
        let radius: Int = hiRes ?  radHighRes : radLowRes
        let matrixCols = cols + 2 * radius
        let matrixArea = (rows + 2 * radius) * matrixCols
        func index(_ x: Int, _ y: Int) -> Int { return y * matrixCols + x }
        
        var destMatrix:[Double] = (0 ..< matrixArea).map( { _ in return Double(0.0) })
        
        for row in radius ..< radius + rows  {
            for col in radius ..< radius + cols {
                
                var kernel2D: [Double]
                var nElements: Int
                let i1 = (row - radius) * cols + (col - radius);
                let binHeight = srcMatrix[i1];
                let intBinHeight = Int(binHeight)
                if intBinHeight == 0 { continue }

                if intBinHeight <= nMatrices
                {
                    let i = intBinHeight + idxOffset
                    nElements = kernelSizes[i]
                    kernel2D = kernels[i]
               }
                else             // not precomputed
                {
                    nElements = matrixSize(bins: intBinHeight, hiRes: hiRes)
                    kernel2D = kernel(bins: intBinHeight, mxSize: nElements, hiRes: hiRes)
                }
                 
                destMatrix[row * matrixCols + col] += kernel2D[0] * kernel2D[0] * binHeight    // x = y = 0
                
                for i in 1 ..< nElements
                {
                    let k3 = kernel2D[0] * kernel2D[i] * binHeight         // either x == 0 or y == 0
                    destMatrix[index( col, row + i)] += k3
                    destMatrix[index( col, row - i)] += k3
                    destMatrix[index( col + i, row )] += k3
                    destMatrix[index( col - i, row )] += k3
                }
                
                for i in 1 ... nElements                                   // both x and y are >= 1
                {
                    let k2 = kernel2D[i] * binHeight
                    for j in 1 ... nElements
                    {
                        let k3 = k2 * kernel2D[j]
                        destMatrix[index(col + i, row + j)] += k3
                        destMatrix[index(col + i, row - j)] += k3
                        destMatrix[index(col - i, row + j)] += k3
                        destMatrix[index(col - i, row - j)] += k3
                    }
                }
            }
        }
        
        if (reflect) {
            reflectMargins(destMatrix: &destMatrix,rows: rows, cols: cols, margin: radius)
        }
        
        var output = [Double](repeating:0, count:srcMatrix.count)
            // copy the destMatrix back onto srcMatrix
        for row in radius ..< (radius + rows) {
            for col in radius ..< radius + cols    {
                let idx = (row-radius) * cols + (col-radius);
                output[idx] = destMatrix[index(col, row)];
            }
        }

        return output
  }
    
    
        // reflect smoothed events outside of the matrix back symmetrical to the edge.
        // The first pixel outside is added to the last spot inside.
    
    private func reflectMargins(destMatrix: inout [Double], rows: Int , cols: Int , margin:  Int)
    {
        let colsInMatrix = cols + margin + margin;
        let rightEdge = cols + margin;                                // the edges of the part to be kept
        let topEdge = rows + margin;
        
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
 
}
