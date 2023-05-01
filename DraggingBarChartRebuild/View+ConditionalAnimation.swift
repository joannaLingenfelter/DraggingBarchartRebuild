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
    let shouldAnimate: (Output, Output) -> Bool
    let content: Content

    @State
    private var oldValue: Output!

    var body: some View {
        content
            .onAppear {
                binding.wrappedValue = transform(value.wrappedValue)
                oldValue = binding.wrappedValue
            }
            .onChange(of: transform(value.wrappedValue)) { newValue in
                if shouldAnimate(oldValue, newValue) {
                    withAnimation(animation) {
                        binding.wrappedValue = newValue
                    }
                } else {
                    binding.wrappedValue = newValue
                }
                oldValue = newValue
            }
    }
}

private struct ConditionalAnimationModifier<Input: Equatable, Output: Equatable>: ViewModifier {

    let outputBinding: Binding<Output>
    let inputBinding: Binding<Input>
    let transform: (Input) -> Output
    let filter: (Output, Output) -> Bool
    let animation: Animation

    init(
        animatedValue: Binding<Output>,
        onChangeOf value: Input,
        transform: @escaping (Input) -> Output,
        filter: @escaping (Output, Output) -> Bool,
        animation: Animation
    ) {
        self.outputBinding = animatedValue
        self.inputBinding = .constant(value)
        self.transform = transform
        self.animation = animation
        self.filter = filter
    }

    init(
        animatedValue: Binding<Output>,
        onChangeOf value: Binding<Input>,
        transform: @escaping (Input) -> Output,
        filter: @escaping (Output, Output) -> Bool,
        animation: Animation
    ) {
        self.outputBinding = animatedValue
        self.inputBinding = value
        self.transform = transform
        self.animation = animation
        self.filter = filter
    }

    func body(content: Content) -> some View {
        ConditionalAnimationModifierWrapperView(binding: outputBinding,
                                                value: inputBinding,
                                                animation: animation,
                                                transform: transform,
                                                shouldAnimate: filter,
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
                                                   filter: { (_, _) in true },
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
                                                   filter: { (_, _) in true },
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
                                                   filter: { (_, _) in true },
                                                   animation: animation))
    }

    func animating<Input: Equatable, Output: Equatable>(
        changeOf value: Binding<Input>,
        into binding: Binding<Output>,
        using transform: @escaping (Input) -> Output,
        filter: @escaping (Output, Output) -> Bool,
        animation: Animation = .default
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animatedValue: binding,
                                                   onChangeOf: value,
                                                   transform: transform,
                                                   filter: { (_, _) in true },
                                                   animation: animation))
    }

    func animating<Value: Equatable>(
        changeOf value: Value,
        into binding: Binding<Value>,
        filter: @escaping (Value, Value) -> Bool,
        animation: Animation = .default
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animatedValue: binding,
                                                   onChangeOf: value,
                                                   transform: { $0 },
                                                   filter: filter,
                                                   animation: animation))
    }

    func animating<Value: Equatable>(
        changeOf value: Binding<Value>,
        into binding: Binding<Value>,
        filter: @escaping (Value, Value) -> Bool,
        animation: Animation = .default
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animatedValue: binding,
                                                   onChangeOf: value,
                                                   transform: { $0 },
                                                   filter: filter,
                                                   animation: animation))
    }

    func animating<Input: Equatable, Output: Equatable>(
        changeOf value: Input,
        into binding: Binding<Output>,
        using transform: @escaping (Input) -> Output,
        filter: @escaping (Output, Output) -> Bool,
        animation: Animation = .default
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animatedValue: binding,
                                                   onChangeOf: value,
                                                   transform: transform,
                                                   filter: filter,
                                                   animation: animation))
    }
}
