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


class Chart3DEntities {
    public static func chartPointEntity() async -> ScatterPointEntity {
        ScatterPointEntity(try! await Entity(named: "ChartPoint", in: realityKitContentBundle))
    }
}

class ScatterPointEntity: EntityWrapper<Entity> {
}

public typealias DataPoints = [SIMD3<Float>]

public class ScatterChart3DEntity: Entity {
    private var pointEntities: EntityInstanceArray<ScatterPointEntity>
    private var pointsParent: Entity = Entity()
    private var pointsUpdater:BackgroundUpdater<DataPoints>! = nil

    public required init() {
        pointEntities = .init(parent: pointsParent)
        super.init()
        pointsUpdater = .init(updateHandler:updatePointEntities)
    }
        
    public func setDataPoints(_ points: DataPoints) {
        pointsUpdater.update(data: points)
    }

    private func updatePointEntities(_ points: DataPoints) async {
        if pointEntities.template == nil {
            pointEntities.template = await Chart3DEntities.chartPointEntity()
        }

        pointEntities.count = points.count
        do {
            try await pointEntities.updateAll(withData: points) { (point, entity) in
                entity.entity.position = point
            }
        } catch {
            print("Error updating 3D chart data points: \(error)")
        }
    }
}

#endif
