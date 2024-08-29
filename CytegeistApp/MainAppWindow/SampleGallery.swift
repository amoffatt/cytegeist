/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant gallery view.
*/

import SwiftUI
import Foundation
import CytegeistCore

struct SampleGallery: View {
    var experiment: Experiment
    @Binding var selection: Set<Sample.ID>

    @State private var itemSize: CGFloat = 250
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                Text("leaf")
//               ForEach($experiment.samples) {
//                    GalleryItem(sample: $0, size: itemSize, selection: $selection)
//                }
            }
        }
        .padding([.horizontal, .top])
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ItemSizeSlider(size: $itemSize)
        }
        .onTapGesture {
            selection = []
        }
    }

    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: itemSize, maximum: itemSize), spacing: 40)]
    }

    private struct GalleryItem: View {
        var sample: Sample
        var size: CGFloat
        @Binding var selection: Set<Sample.ID>

        var body: some View {
            VStack {
                GalleryImage(sample: sample, size: size)
                    .background(selectionBackground)
                Text(verbatim: sample.tubeName)
                    .font(.callout)
            }
            .frame(width: size)
            .onTapGesture {
                selection = [sample.id]
            }
        }

        var isSelected: Bool {
            selection.contains(sample.id)
        }

        @ViewBuilder
        var selectionBackground: some View {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.selection)
            }
        }
    }

    private struct GalleryImage: View {
        var sample: Sample
        var size: CGFloat

        var body: some View {
            AsyncImage(url: sample.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(background)
                    .frame(width: size, height: size)
            } placeholder: {
                Image(systemName: "leaf")
                    .symbolVariant(.fill)
                    .font(.system(size: 40))
                    .foregroundColor(Color.green)
                    .background(background)
                    .frame(width: size, height: size)
            }
        }

        var background: some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: size, height: size)
        }
    }

    private struct ItemSizeSlider: View {
        @Binding var size: CGFloat

        var body: some View {
            HStack {
                Spacer()
                Slider(value: $size, in: 100...500)
                    .controlSize(.small)
                    .frame(width: 100)
                    .padding(.trailing)
            }
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }
}
