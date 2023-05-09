//
//  ScrollingBarChart+LollipopOverlay.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 5/1/23.
//

import SwiftUI
import Charts

extension ScrollingBarChart {
    struct LollipopOverlay: View {
        let selectedChartData: ChartData
        let chart: ChartProxy
        let containerSize: CGSize

        @State
        private var isLineVisible = true

        var body: some View {
            GeometryReader { geometry in
                let valuePosition = chart.position(for: (x: selectedChartData.date, y: selectedChartData.value)) ?? .zero

                let boxCornerRadius: CGFloat = 8.0

                let visibleBounds = CGRect(x: .zero,
                                           y: .zero,
                                           width: containerSize.width,
                                           height: containerSize.height)

                let overlayGeometry = OverlayGeometry(valuePosition: valuePosition,
                                                      visibleBounds: visibleBounds,
                                                      unitWidth: containerSize.width/4,
                                                      cornerRadius: boxCornerRadius,
                                                      chartFrame: geometry[chart.plotAreaFrame])
                Rectangle()
                    .fill(.red)
                    .frame(
                        width: overlayGeometry.line.width,
                        height: overlayGeometry.line.height,
                        alignment: .top
                    )
                    .position(
                        x: overlayGeometry.line.midX,
                        y: overlayGeometry.line.midY
                    )
                    .onChange(of: overlayGeometry.line.midX) { newValue in
                        let isVisible = (visibleBounds.minX ... visibleBounds.maxX).contains(newValue)
                        if isVisible != isLineVisible {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4)) {
                                isLineVisible = isVisible
                            }
                        }
                    }

                let boxScale = isLineVisible ? 1.0 : 0.2
                VStack(alignment: .center) {
                    Text("\(selectedChartData.date, format: .dateTime.year().month().day())")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("\(selectedChartData.value, format: .number)")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                .accessibilityElement(children: .combine)
                .padding()
                .frame(
                    width: overlayGeometry.box.width,
                    height: overlayGeometry.box.height,
                    alignment: .leading
                )
                .background {
                    let borderWidth = 1.0
                    RoundedRectangle(cornerRadius: boxCornerRadius)
                        .strokeBorder(.black, lineWidth: borderWidth)
                        .background {
                            Color(white: 0.9)
                                .padding(borderWidth/2)
                                .clipShape(RoundedRectangle(cornerRadius: boxCornerRadius))
                        }
                }
                .scaleEffect(x: boxScale,
                             y: boxScale,
                             anchor: overlayGeometry.line.maxX > visibleBounds.midX ? .bottomTrailing : .bottomLeading)
                .position(
                    x: overlayGeometry.box.midX,
                    y: overlayGeometry.box.midY
                )
                .opacity(isLineVisible ? 1.0 : 0.0)
            }
        }
    }
    
    private struct OverlayGeometry {
        let box: CGRect
        let line: CGRect

        init(valuePosition: CGPoint, visibleBounds: CGRect, unitWidth: CGFloat, cornerRadius: CGFloat, chartFrame: CGRect) {
            // height gets replaced later
            var lineRect = CGRect(origin: .zero, size: CGSize(width: 1, height: 0))
            lineRect.translateBy(x: valuePosition.x + chartFrame.minX + visibleBounds.minX + unitWidth / 2.0)

            let edgeInsets = CGSize(width: 8, height: 8)

            var boxRect = CGRect(origin: .zero, size: CGSize(width: unitWidth * 1.66, height: 88))

            // shift the box over for its "raw" offset
            boxRect.translateBy(x: lineRect.midX - boxRect.midX)

            // insets for the box relative to the full width of the selected unit
            boxRect.insettingBy(dx: edgeInsets.width, dy: edgeInsets.height)

            let stickyBounds = visibleBounds.insetBy(dx: edgeInsets.width, dy: edgeInsets.height)

            // clamp leading
            if boxRect.minX < stickyBounds.minX {
                boxRect.translateBy(x: stickyBounds.minX - boxRect.minX)
            }

            // clamp trailing
            if boxRect.maxX > stickyBounds.maxX {
                boxRect.translateBy(x: stickyBounds.maxX - boxRect.maxX)
            }

            let lineDraggingBounds = stickyBounds.insetBy(dx: cornerRadius, dy: cornerRadius)

            // drag leading
            if lineRect.minX < lineDraggingBounds.minX {
                boxRect.translateBy(x: lineRect.minX - lineDraggingBounds.minX)
            }

            // drag trailing
            if lineRect.maxX > lineDraggingBounds.maxX {
                boxRect.translateBy(x: lineRect.maxX - lineDraggingBounds.maxX)
            }

            // Fix the line height now that we know everything else
            lineRect.size.height = max(valuePosition.y - boxRect.maxY, .zero)
            lineRect.translateBy(y: boxRect.maxY)

            self.line = lineRect
            self.box = boxRect
        }
    }
}
