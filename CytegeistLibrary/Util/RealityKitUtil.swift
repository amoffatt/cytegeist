//
//  RealityKit.swift
//  DataSpace
//
//  Created by Aaron Moffatt on 1/27/24.
//

#if os(visionOS)
import Foundation
import RealityKit

public typealias MaterialProperty = (String, MaterialParameters.Value)

public extension Entity {
    var path:String {
        var path = ""
        var parent:Entity? = self
        while parent != nil {
            path = "\(parent!.name)/\(path)"
            parent = parent!.parent
        }
        return path
    }
    
    func clone(recursive:Bool = true, parent:Entity? = nil) -> Self {
        let cloned = self.clone(recursive: recursive)
        if parent != nil {
            cloned.setParent(parent)
        }
        return cloned
    }
    
    func hoverable(_ hitShape:[ShapeResource]) {
        self.components.set(HoverEffectComponent())   // Reality Composer isn't permitting adding the hover effect
        self.components.set(InputTargetComponent())
        self.components.set(CollisionComponent(shapes: hitShape))
    }
    
    
}


public struct EntityInstanceArray<Element:EntityWrapper<Entity>> {
    public let parent:Entity
    public var template:Element! = nil
    
    private var entities:[Element] = []
    
    public var count:Int {
        get { entities.count }
        set {
            //        var result = entities
            //        print("Updating entity count for \(entityTemplate.entity.name) \(entities.count) -> \(count)")
            assert(template != nil || newValue == 0, "EntityInstanceArray template must be set before count is set")
            
            while newValue > entities.count {
                let entity = template.clone(parent:parent)
                
                // Ensure invisible til updated
                entity.entity.scale = .zero
                
                entities.append(entity)
            }
            
            while newValue < entities.count {
                let entity = entities.removeLast()
                entity.entity.setParent(nil)
                //            parent.removeChild(entity.entity)
            }
        }
    }
    
    public init(parent:Entity) {
        self.parent = parent
    }
    
    public func updateAll<DataCollection:Collection>(withData data:DataCollection, update:(DataCollection.Element, Element) async throws -> Void) async rethrows {
        validateUpdateData(data)

        for (i, dataPoint) in data.enumerated() {
            try await update(dataPoint, entities[i])
            if i % 5 == 0 {
                await Task.yield()
            }
        }
    }
    
    public func updateAllOnMainActor<DataCollection:Collection>(withData data:DataCollection, blockSize:Int = 5, update:(DataCollection.Element, Element) throws -> Void) async rethrows where DataCollection.Index == Int {
        validateUpdateData(data)
        for i in stride(from: 0, to: data.count, by: blockSize) {
            try await MainActor.run {
                for j in i..<min(i+blockSize, data.count) {
                    try update(data[j], entities[j])
                }
            }
            await Task.yield()
        }
    }
    
    private func validateUpdateData(_ data:any Collection) {
        if entities.count != data.count {
            print("EntityList.updateAll() count mismatch (entity count \(entities.count) != \(data.count))")
        }
    }
}


open class EntityWrapper<T:Entity> {
    public let entity:T
    public var dim:String {
        get { entity.name }
        set { entity.name = newValue }
    }
    public var components:Entity.ComponentSet { entity.components }
    
    required public init(_ entity:T) {
        self.entity = entity
    }
    
    public func clone(parent:Entity) -> Self {
        Self(entity.clone(parent:parent))
    }
}


open class SimpleObjectEntity: EntityWrapper<Entity> {
    public let obj:ModelEntity
    public var material:ShaderGraphMaterial {
        get { obj.model!.materials[0] as! ShaderGraphMaterial }
        set { obj.model!.materials[0] = newValue }
    }
    
    required public init(_ entity: Entity) {
        obj = entity.children[0].children[0] as! ModelEntity
        super.init(entity)
    }
    
    public func setMaterialProperties(_ values:MaterialProperty...) throws {
        var material = self.material
        for (name, value) in values {
            try material.setParameter(name: name, value: value)
        }
        self.material = material
    }
}

#endif
