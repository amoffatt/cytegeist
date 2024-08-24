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
var gSmoothingInitialized = false
var gSmoothingMatrices = [[Double]]  ()      //kMatricesToBuild*2+1
var gSmoothingMatrixSize = [Int] () //kMatricesToBuild*2+1
let gReflect = true

let kMatricesToBuild = 256;
    //------------------------------------------------------------------------
func buildAllSmoothingMatrices()
{
    if gSmoothingInitialized   { return }
    for idxM in 1 ... kMatricesToBuild          // low res
    {
        let binCt = idxM;
        let matrixElements = matrixSize(bins: binCt, hiRes: false);
        gSmoothingMatrixSize[idxM] = matrixElements;
        gSmoothingMatrices[idxM] = smoothingMatrix(bins: Double(binCt), nDevs: Double(2.4), matrixElements: matrixElements, hiRes: <#Bool#>);
    }
    
    for idxM  in 1 ... kMatricesToBuild           // high res
    {
        let binCt = idxM;
        let matrixElements = matrixSize(bins: binCt,hiRes: true);
        gSmoothingMatrixSize[idxM+kMatricesToBuild] = matrixElements;
        gSmoothingMatrices[idxM+kMatricesToBuild] = smoothingMatrix(bins: Double(binCt), nDevs: Double(2.4), 
                                                                    matrixElements: matrixElements, hiRes: <#Bool#>);
    }
    gSmoothingInitialized = true;
}

    //------------------------------------------------------------------------
func matrixSize( bins: Int, hiRes: Bool) -> Int
{
     
    let radius = hiRes ?  radHighRes : radLowRes;
    let sq = sqrt(Double(bins))
    return  Int(Double(radius) / sqrt(sq) + 0.9999);
}

    //------------------------------------------------------------------------
func smoothingMatrix(bins: Double, nDevs : Double,  matrixElements: Int, hiRes: Bool) -> [Double]
{
    let radius = hiRes ?  radHighRes : radLowRes;
    let sq = sqrt(bins);
    let x = nDevs/Double(radius)
    let factor = -0.5 * sq * x * x
    var matrix = [Double]()
    
    for i in 0...matrixElements {
        matrix.append(exp(factor * Double(i * i)));
    }
    
    var matrixTotal = 0.0;
    for i in -matrixElements...matrixElements {
        for j in -matrixElements...matrixElements {
            matrixTotal += matrix[abs(i)] * matrix[abs(j)];
        }}
    
    matrixTotal = sqrt(matrixTotal);
    
    for i in 0...matrixElements {
        matrix[i]  /= matrixTotal;
    }
    return matrix
}
    //------------------------------------------------------------------------


func smoothInPlace(srcMatrix: [Double],  inRows: Int, inCols: Int, hiRes: Bool)
{
    let mIdxOffset = hiRes ? kMatricesToBuild : 0;
    let radius:Int = hiRes ?  radHighRes : radLowRes;
    let matrixCols = inCols + 2 * radius;
    let matrixSize = (inRows + 2 * radius) * matrixCols;
    
    var localSmoothMatrix = [Double]()
    var destMatrix = [Double]()
    for ii in 0 ..< matrixSize {
        destMatrix.append(0.0)
    }
    
    for row in radius ..< radius + inRows  {
        for col in radius ..< radius + inCols {
            
            var smoothMatrix: [Double]
            var matrixElements: Int
            let i1 = (row - radius) * inCols + (col - radius);
            let binCt = srcMatrix[i1];
            if (binCt == 0.0)   { continue }
            
            if binCt <= Double(kMatricesToBuild)
            {
                let i = binCt
                smoothMatrix = gSmoothingMatrices[i+mIdxOffset]
                matrixElements = gSmoothingMatrixSize[i+mIdxOffset]
            }
            else                                            // not precomputed
            {
                matrixElements = matrixSize(binCt);
                smoothMatrix = localSmoothMatrix;
                smoothingMatrix(binCt, Double(2.4), localSmoothMatrix, matrixElements)
            }
            
            destMatrix[row * matrixCols + col] += smoothMatrix[0] * smoothMatrix[0] * binCt;    // 0,0 point
            
            for i in 1 ..< matrixElements
            {
                let k3 = smoothMatrix[0] * smoothMatrix[i] * binCt;                    // 0,y and x,0 points
                let i1 = (row + i) * matrixCols + (col    );
                let i2 = (row - i) * matrixCols + (col    );
                let i3 = (row    ) * matrixCols + (col + i);
                let i4 = (row    ) * matrixCols + (col - i);
                destMatrix[i1] += k3;
                destMatrix[i2] += k3;
                destMatrix[i3] += k3;
                destMatrix[i4] += k3;
            }
            
            for i in 1 ... matrixElements                                               // all other points
            {
                let k2 = smoothMatrix[i] * binCt;
                for j in 1 ... matrixElements
                {
                    let k3 = k2 * smoothMatrix[j]
                    let i1 = (row + j) * matrixCols + (col + i)
                    let i2 = (row - j) * matrixCols + (col + i)
                    let i3 = (row + j) * matrixCols + (col - i)
                    let i4 = (row - j) * matrixCols + (col - i)
                    destMatrix[i1] += k3;
                    destMatrix[i2] += k3;
                    destMatrix[i3] += k3;
                    destMatrix[i4] += k3;
                }
            }
        }
        
        if (gReflect) {
            ReflectMargins(destMatrix: destMatrix,inRows: inRows, inCols: inCols, margin: radius);
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



func ReflectMargins(destMatrix: [Double], inRows: Int , inCols: Int , margin:  Int)
{
        // reflect smoothed events outside of the matrix back in.
        // reflect such that the axis of reflection is the outside edge of the
        // extreme pixel, so that the first pixel outside is added to the extreme-most pixel.
    
    let colsInMatrix = inCols + margin + margin;
    let rightEdge = inCols + margin;                                // the edges of the part to be kept
    let topEdge = inRows + margin;
    
    for row in 0 ..< margin       {                                   // reflect entire bottom edge
        for col in 0 ..< rightEdge + margin    {
            let i = (margin-1+(margin-row)) * colsInMatrix + col;
            let j = row * colsInMatrix + col;
            destMatrix[i] += destMatrix[j];
        }
    }
    
    for row in topEdge+1 ..< topEdge + margin  {                                   // reflect entire bottom edge
        for col in 0 ..< rightEdge + margin    {
            let i = (topEdge+1-(row-topEdge)) * colsInMatrix + col;
            let j = row * colsInMatrix + col;
            destMatrix[i] += destMatrix[j];
        }
    }

    for col in 0 ..< margin       {                                   // reflect entire bottom edge
        for row in margin ..< topEdge    {
            let i = row * colsInMatrix +  (margin-1+(margin-col));
            let j = row * colsInMatrix + col;
            destMatrix[i] += destMatrix[j];
        }
    }
    
    for col in rightEdge + 1 ..< rightEdge + margin       {                                   // reflect entire bottom
        for row in margin ..< topEdge    {
            let  i = row * colsInMatrix +  (rightEdge+1-(col-rightEdge));
            let j = row * colsInMatrix + col;
            destMatrix[i] += destMatrix[j];
        }
    }
}
    //----------------------------------------------------------------------------------
    // Same algorithm exactly as Smooth, just do it in one dimension only

func SmoothHistogram(srcBins: [Double], destBins: [Double], inNBins: Int, hiRes: Bool)
{
    let mIdxOffset = hiRes ? kMatricesToBuild : 0
    let radius:Int = hiRes ?  radHighRes : radLowRes

    let matrixBins = inNBins + 2 * radius
   var destMatrix = [Double]()
    for bin in radius ..< radius + inNBins
    {
        let binCt = srcBins[bin - radius]
        if binCt == 0.0 { continue }
        
        if binCt <= Double(kMatricesToBuild)
        {
            let i = binCt;
            let smoothMatrix = gSmoothingMatrices[i+mIdxOffset];
            let matrixElements = gSmoothingMatrixSize[i+mIdxOffset];
        }
        else                                            // not precomputed
        {
            let matrixElements = matrixSize(binCt, hiRes);
            let smoothMatrix = localSmoothMatrix;
            SmoothingMatrix(binCt, Double(2.4) localSmoothMatrix, matrixElements);
        }
        
        destMatrix[bin] += smoothMatrix[0] * binCt;    // 0 point
        for i in 1 ..< matrixElements        // points to either side
        {
            let k3 = smoothMatrix[i] * binCt;
            destMatrix[bin + i] += k3;
            destMatrix[bin - i] += k3;
        }
        
        if (gReflect)
        {
            for i in 1 ..< radius
            {
                let leftEdge = radius;
                let rightEdge = radius + inNBins;
                destMatrix[leftEdge + i - 1] += destMatrix[leftEdge - i];
                destMatrix[rightEdge - i + 1] += destMatrix[rightEdge + i];
            }
        }
            // copy the destMatrix back onto srcMatrix
        for bin in radius ..< radius + inNBins {
            destBins[bin-radius] = destMatrix[bin]
        }
    }
}
