//
//  ChartAxis.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/22/24.
//

import SwiftUI
import CytegeistLibrary

public typealias AxisUpdateCallback = (AxisDef) -> Void

public struct ChartAxisView: View {
    
    static func height(of def: AxisDef?, immersive:Bool = false) -> CGFloat {
        if let def = def {
            return (def.scale ?? 1) * (
                5.0 +
                (def.showTicks ? Self.ticksHeight : 0) +
                (def.showTickLabels ? Self.tickLabelsHeight : 0) +
                (def.showLabel ? Self.labelHeight : 0) +
                (immersive ? immersiveLabelPadding * 6 : 0)
            )
        }
        return Self.labelHeight
    }
    static let ticksHeight:CGFloat = 7
    static let tickLabelsHeight:CGFloat = 25
    static let labelHeight:CGFloat = 35
    static let immersiveLabelPadding:CGFloat = 10

    let def:AxisDef?
    let normalizer: AxisNormalizer?
    let sampleMeta: FCSMetadata?
    let width: CGFloat
    let update:AxisUpdateCallback?
    let immersive:Bool

    public init(def:AxisDef?, normalizer:AxisNormalizer?, sampleMeta:FCSMetadata?, width: CGFloat, immersive:Bool = false, update:AxisUpdateCallback? = nil) {
        self.def = def
        self.normalizer = normalizer
        self.sampleMeta = sampleMeta
        self.width = width
        self.immersive = immersive
        self.update = update
    }

    public var body: some View {
        let scale = def?.scale ?? 1
        let scaledWidth = width / scale     // compensate for scaling
        let height = Self.height(of: def, immersive: immersive)
        let scaledHeight = height / scale
        
        return VStack(spacing:0) {
            axisLine
            
            if let normalizer = normalizer {
                ticks(scaledWidth, normalizer)
//                    .if(immersive) { view in
//                        view
//                            .padding(.horizontal, 8)
//                            .glassBackgroundEffect()
//                    }
            }
            label

            Spacer()
        }
//        .fixedSize(horizontal: false, vertical: true)
        .frame(width: scaledWidth, height: scaledHeight)
        .scaleEffect(scale)//config.wrappedValue?.xAxis?.scale ?? 1))
        .frame(width: width, height:height)
    }
    
    private var dimBinding:Binding<String> { .init {
        def?.dim ?? ""
    } set: {
        var def = self.def ?? AxisDef()
        def.dim = $0
        update?(def)
    }}
    
    @ViewBuilder
    var axisLine: some View {
        if immersive {
            Rectangle()
                .frame(width: width, height: 2)
        }
        
    }
    
    func ticks(_ width: CGFloat, _ normalizer:AxisNormalizer) -> some View {
        let majorTicks = normalizer.tickMarks(4).map { (tick:$0, x:width * CGFloat($0.normalizedValue))}
        let maxLabelWidth:CGFloat = width / CGFloat(majorTicks.count + 1)

        func axisTickLabel(_ x:CGFloat, _ label:String, _ alignment:Alignment) -> some View {
            return Text(label)
            // .multilineTextAlignment(alignment)
//                .scaledToFit()
//                .minimumScaleFactor(0.3)
                .font(.body)
                            .if(immersive) {
                    $0
                        .padding(Self.immersiveLabelPadding)
                        .padding(.horizontal, 8)
                        .glassBackgroundEffect()
                }


//                .frame(width: maxLabelWidth, height: Self.tickLabelsHeight, alignment: alignment)
                .position(x:x)
//                .border(.blue)
        }

        return VStack {
            if let def = def {
                
                if def.showTicks {
                    ZStack(alignment: .topLeading) {
                        ForEach(majorTicks, id:\.tick.id) { (majorTick, x) in
                            let x = clamp(x, min:1.5, max:width - 1.5)      // prevent wide major ticks overlapping edge of axis
                            Rectangle()
                                .frame(width: 2, height: Self.ticksHeight)
                                .position(x: x, y: Self.ticksHeight / 2)
                            
                            ForEach(majorTick.minorTicks, id:\.self) { minorTick in
                                let minorX = width * CGFloat(minorTick)
                                Rectangle()
                                    .frame(width: 1, height: Self.ticksHeight / 2)
                                    .position(x: minorX, y: Self.ticksHeight / 4)
                            }
                        }
                    }
                }
                if def.showTickLabels {
                    ZStack(alignment:.topLeading) {
//                        if (tickCount > 0) {
//                            let tick = majorTicks[0]
//                            axisTickLabel(tick.x, tick.tick.label, .leading)
//                        }
//                        if tickCount > 2 {
//                            ForEach(majorTicks[1...(tickCount-2)], id:\.tick.id) { (majorTick, x) in
                            ForEach(majorTicks, id:\.tick.id) { (majorTick, x) in
                                axisTickLabel(x, majorTick.label, .center)
                            }
//                        }
//                        if (tickCount > 1) {
//                            let tick = majorTicks[tickCount - 1]
//                            axisTickLabel(tick.x, tick.tick.label, .trailing)
//                        }
                    }
                }
            }
        }
        .frame(width: width)
    }
    
    var label: some View {
        let availableParameters = sampleMeta?.parameters ?? []
        return VStack {
            if update != nil {
                Picker("", selection: dimBinding) {
                    Text("<None>")
                        .tag("")
                    ForEach(availableParameters, id: \.name) { p in
                        Text(p.displayName)
                            .tag(p.name)
                    }//.frame(maxWidth: 50, maxHeight: 200)
                }
                .pickerStyle(.menu)
            } else {
                let p = sampleMeta?.parameter(named: def?.dim)
                Text(p?.displayName ?? def?.dim ?? "")
                    .font(.title)
                    .fontWeight(.semibold)
            }
        }
        .if(immersive) {
            $0
                .padding(Self.immersiveLabelPadding)
                .padding(.horizontal, 20)   // Extra horizontal padding
                .glassBackgroundEffect()
        }
        .padding(.top, 20)
    }
}

//#Preview {
//    ChartAxisView(
//        label:"My Parameter",
//        normalizer: .linear(min: -2.1, max: 520)
//    )
//}
