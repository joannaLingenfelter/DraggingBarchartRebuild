//
//  View+Measuring.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/21/23.
//

import SwiftUI

// Can probably use generics to support all floating point types, but it made the compiler angry
// when I tried it and I don't feel like fixing it right now
extension View {

// Measure a value based on a KeyPath of a GeometryProxy
    func measuring(
        _ path: KeyPath<GeometryProxy, Double>,
        assign value: Binding<Double>
    ) -> some View {
        self.background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        value.wrappedValue = proxy[keyPath: path]
                    }
                    .onChange(of: proxy[keyPath: path]) { newValue in
                        value.wrappedValue = newValue
                    }
            }
        }
    }

    // Measure a value based on a KeyPath from CGRect -> CGFloat
    func measuring(
        _ path: KeyPath<CGRect, CGFloat>,
        in coordinateSpace: CoordinateSpace = .global,
        assign value: Binding<CGFloat>
    ) -> some View {
        self.background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        value.wrappedValue = proxy.frame(in: coordinateSpace)[keyPath: path]
                    }
                    .onChange(of: proxy.frame(in: coordinateSpace)[keyPath: path]) { newValue in
                        value.wrappedValue = newValue
                    }
            }
        }
    }

    // Measure a whole frame in a given coordinate space
    func measuringFrame(
        in coordinateSpace: CoordinateSpace = .global,
        assign value: Binding<CGRect>
    ) -> some View {
        self.background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        value.wrappedValue = proxy.frame(in: coordinateSpace)
                    }
                    .onChange(of: proxy.frame(in: coordinateSpace)) { newValue in
                        value.wrappedValue = newValue
                    }
            }
        }
    }

    // Measure a keypath relative to a frame in a given coordinate space
    func measuringFrame(
        _ path: KeyPath<CGRect, CGFloat>,
        in coordinateSpace: CoordinateSpace = .global,
        assign value: Binding<CGFloat>
    ) -> some View {
        self.background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        value.wrappedValue = proxy.frame(in: coordinateSpace)[keyPath: path]
                    }
                    .onChange(of: proxy.frame(in: coordinateSpace)[keyPath: path]) { newValue in
                        value.wrappedValue = newValue
                    }
            }
        }
    }

    func measuring<T: Numeric>(
        _ path: KeyPath<GeometryProxy, T>,
        assign value: Binding<T>
    ) -> some View {
        self.background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        value.wrappedValue = proxy[keyPath: path]
                    }
                    .onChange(of: proxy[keyPath: path]) { newValue in
                        value.wrappedValue = newValue
                    }
            }
        }
    }
}
