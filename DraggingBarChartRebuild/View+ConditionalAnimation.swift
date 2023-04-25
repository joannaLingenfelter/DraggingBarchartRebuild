//
//  View+ConditionalAnimation.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/25/23.
//

import SwiftUI

private struct ConditionalAnimationModifierWrapperView<Content: View, Input: Equatable, Output: Equatable>: View {
    let binding: Binding<Output>
    let value: Binding<Input>
    let animation: Animation
    let transform: (Input) -> Output
    let content: Content

    var body: some View {
        content
            .onAppear {
                binding.wrappedValue = transform(value.wrappedValue)
            }
            .onChange(of: transform(value.wrappedValue)) { newValue in
                withAnimation(animation) {
                    binding.wrappedValue = newValue
                }
            }
    }
}

private struct ConditionalAnimationModifier<Input: Equatable, Output: Equatable>: ViewModifier {

    let outputBinding: Binding<Output>
    let inputBinding: Binding<Input>
    let transform: (Input) -> Output
    let animation: Animation

    init(
        animatedValue: Binding<Output>,
        onChangeOf value: Input,
        transform: @escaping (Input) -> Output,
        animation: Animation
    ) {
        self.outputBinding = animatedValue
        self.inputBinding = .constant(value)
        self.transform = transform
        self.animation = animation
    }

    init(
        animatedValue: Binding<Output>,
        onChangeOf value: Binding<Input>,
        transform: @escaping (Input) -> Output,
        animation: Animation
    ) {
        self.outputBinding = animatedValue
        self.inputBinding = value
        self.transform = transform
        self.animation = animation
    }

    func body(content: Content) -> some View {
        ConditionalAnimationModifierWrapperView(binding: outputBinding,
                                                value: inputBinding,
                                                animation: animation,
                                                transform: transform,
                                                content: content)
    }
}

extension View {

    func animating<Value: Equatable>(
        changeOf value: Value,
        into binding: Binding<Value>,
        animation: Animation = .default
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animatedValue: binding,
                                                   onChangeOf: value,
                                                   transform: { $0 },
                                                   animation: animation))
    }

    func animating<Value: Equatable>(
        changeOf value: Binding<Value>,
        into binding: Binding<Value>,
        animation: Animation = .default
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animatedValue: binding,
                                                   onChangeOf: value,
                                                   transform: { $0 },
                                                   animation: animation))
    }

    func animating<Input: Equatable, Output: Equatable>(
        changeOf value: Input,
        into binding: Binding<Output>,
        using transform: @escaping (Input) -> Output,
        animation: Animation = .default
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animatedValue: binding,
                                                   onChangeOf: value,
                                                   transform: transform,
                                                   animation: animation))
    }

    func animating<Input: Equatable, Output: Equatable>(
        changeOf value: Binding<Input>,
        into binding: Binding<Output>,
        using transform: @escaping (Input) -> Output,
        animation: Animation = .default
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animatedValue: binding,
                                                   onChangeOf: value,
                                                   transform: transform,
                                                   animation: animation))
    }
}
