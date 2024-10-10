//
//  ScatterChart3DEntity.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 9/24/24.
//

#if os(visionOS)
import Foundation
import RealityKit
import RealityKitContent
import CytegeistLibrary
import SwiftUI


class Chart3DEntities {
    public static func chartPointEntity() async -> ScatterPointEntity {
        ScatterPointEntity(try! await Entity(named: "ChartPoint", in: realityKitContentBundle))
    }
}

class ScatterPointEntity: SimpleObjectEntity {
    static let ColorProperty = "Color"
}

//public typealias DataPoints = [SIMD3<Float>]

public typealias UpdateData = (events:SampledPopulationData?, colormap:Colormap)

// Data needing to be applied to the point on the main actor
private struct PointData {
    public var position:SIMD3<Float>
    public var scale:SIMD3<Float>
    public var color:MaterialParameters.Value
}

public class ScatterChart3DEntity: Entity {
    public enum Indices : Int {
        case
        x, y, z,
        size, color
    }
    private var pointEntities: EntityInstanceArray<ScatterPointEntity>
    private var pointsParent: Entity = Entity()
    private var pointsUpdater:BackgroundUpdater<UpdateData>! = nil
    
    private var pointSize:Float = 0.2

    public required init() {
        pointEntities = .init(parent: pointsParent)
        super.init()
        addChild(pointsParent)
        pointsParent.position = .one * -0.5
        pointsUpdater = .init(updateHandler:updatePointEntities)
    }
        
//    public func setDataPoints(_ points: DataPoints) {
//        pointsUpdater.update(data: points)
//    }
    public func setDataPoints(_ data: UpdateData) {
        pointsUpdater.update(data: data)
    }
    
    private func updatePointEntities(_ data: UpdateData) async {
        guard let events = data.events,
              let allEvents = events.allEvents.data
            else {
            pointEntities.count = 0
            return
        }
        
        if pointEntities.template == nil {
            pointEntities.template = await Chart3DEntities.chartPointEntity()
        }

        let pointCount = events.count
        pointEntities.count = pointCount
        let normalizers = events.allEvents.axisNormalizers
        let colormap = data.colormap
        
        // TODO OPTIMIZE
        func normalizedValue(_ eventData:EventData, _ axis:Indices) -> Float {
            if let value = eventData.values.get(index: axis.rawValue),
               let normalizer = normalizers.get(index: axis.rawValue),
               let normalizer {
                return Float(normalizer.normalize(value))
            }
            return 0.5
        }
        
        // TODO OPTIMIZE cache this
        let pointData = (0..<pointCount).map { dataIndex in
            let eventData = allEvents[dataIndex]
            
            let color = colormap.color(at:normalizedValue(eventData, .color))
            return PointData(
                position: .init(
                    normalizedValue(eventData, .x),
                    normalizedValue(eventData, .y),
                    normalizedValue(eventData, .z)),
                scale: .init(repeating:normalizedValue(eventData, .size) * pointSize),
                color: .color(UIColor(color))
            )
        }
        
        do {
            try await pointEntities.updateAllOnMainActor(withData: pointData) { (data, entity) in
                let e = entity.entity
                e.position = data.position
                e.scale = data.scale
                try entity.setMaterialProperties((ScatterPointEntity.ColorProperty, data.color))
            }
            
            
        } catch {
            print("Error updating 3D chart data points: \(error)")
        }
    }
}

#endif
