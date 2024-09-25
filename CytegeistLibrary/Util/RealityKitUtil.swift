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
            path = "\(parent!.dim)/\(path)"
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
            assert(template != nil, "EntityInstanceArray template must be set before count is set")
            
            while newValue > entities.count {
                let entity = template.clone(parent:parent)
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
    
    public func updateAll<DataType>(withData data:[DataType], update:(DataType, Element) throws -> Void) async throws {
        let count = min(entities.count, data.count)
        if entities.count != data.count {
            print("EntityList.updateAll() count mismatch (entity count \(entities.count) != \(data.count))")
        }
//        print("parent child count: \(entityCount)")
       
        for i in 0..<count {
            try update(data[i], entities[i])
            if i % 5 == 0 {
                await Task.yield()
            }
        }
    }
}


open class EntityWrapper<T:Entity> {
    public let entity:T
    public var dim:String {
        get { entity.dim }
        set { entity.dim = newValue }
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
    let obj:ModelEntity
    var material:ShaderGraphMaterial {
        get { obj.model!.materials[0] as! ShaderGraphMaterial }
        set { obj.model!.materials[0] = newValue }
    }
    
    required public init(_ entity: Entity) {
        obj = entity.children[0].children[0] as! ModelEntity
        super.init(entity)
    }
    
    public func setMaterialProperties(_ values:MaterialProperty...) throws {
        var material = self.material
        for (dim, value) in values {
            try material.setParameter(dim: dim, value: value)
        }
        self.material = material
    }
}

#endif
