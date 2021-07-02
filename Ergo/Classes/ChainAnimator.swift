//
//  ChainAnimator.swift
//  Ergo
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation
#if canImport(UIKit)
import UIKit

public extension UIView {
    /// Create ChainAnimator object to perform chaining multiple animation one after another
    /// - Parameters:
    ///   - duration: The total duration of the animations, measured in seconds. If you specify a negative value or 0, the changes are made without animating them.
    ///   - delay: The amount of time (measured in seconds) to wait before beginning the animations. Specify a value of 0 to begin the animations immediately.
    ///   - dampingRatio: The damping ratio for the spring animation as it approaches its quiescent state.
    ///   - velocity: The initial spring velocity. For smooth start to the animation, match this value to the view’s velocity as it was prior to attachment.
    ///   - options: A mask of options indicating how you want to perform the animations.
    /// - Returns: ChainAnimator object
    static func chainAnimate(
        withDuration duration: TimeInterval,
        delay: TimeInterval = .zero,
        usingSpringWithDamping dampingRatio: CGFloat = 1,
        initialSpringVelocity velocity: CGFloat = 1,
        options: UIView.AnimationOptions = .curveLinear) -> ChainAnimator {
        ChainAnimator(
            animationValue: .init(
                duration: duration,
                delay: delay,
                dampingRatio: dampingRatio,
                velocity: velocity,
                options: options
            )
        )
    }
}

struct AnimationValue {
    let duration: TimeInterval
    let delay: TimeInterval
    let dampingRatio: CGFloat
    let velocity: CGFloat
    let options: UIView.AnimationOptions
}

public final class ChainAnimator {
    let previousAnimator: ChainedAnimator?
    let animationValue: AnimationValue
    
    init(previousAnimator: ChainedAnimator? = nil, animationValue: AnimationValue) {
        self.previousAnimator = previousAnimator
        self.animationValue = animationValue
    }
    
    /// Add block animation for animator
    /// - Parameter worker: A block object containing the changes to commit to the views. This is where you programmatically change any animatable properties of the views in your view hierarchy. This block takes no parameters and has no return value.
    /// - Returns: ChainedAnimator object
    public func animation(_ worker: @escaping () -> Void) -> ChainedAnimator {
        ChainedAnimator(
            previousAnimator: previousAnimator,
            animationValue: animationValue,
            animation: worker
        )
    }
}

public final class ChainedAnimator {
    
    let previousAnimator: ChainedAnimator?
    let animationValue: AnimationValue
    let animation: () -> Void
    
    init(previousAnimator: ChainedAnimator? = nil, animationValue: AnimationValue, animation: @escaping () -> Void) {
        self.previousAnimator = previousAnimator
        self.animationValue = animationValue
        self.animation = animation
    }
    
    /// Create ChainAnimator object to create animation that will run after current animation
    /// - Parameters:
    ///   - duration: The total duration of the animations, measured in seconds. If you specify a negative value or 0, the changes are made without animating them.
    ///   - delay: The amount of time (measured in seconds) to wait before beginning the animations. Specify a value of 0 to begin the animations immediately.
    ///   - dampingRatio: The damping ratio for the spring animation as it approaches its quiescent state.
    ///   - velocity: The initial spring velocity. For smooth start to the animation, match this value to the view’s velocity as it was prior to attachment.
    ///   - options: A mask of options indicating how you want to perform the animations.
    /// - Returns: ChainAnimator object
    public func chain(
        withDuration duration: TimeInterval,
        delay: TimeInterval = .zero,
        usingSpringWithDamping dampingRatio: CGFloat = 1,
        initialSpringVelocity velocity: CGFloat = 1,
        options: UIView.AnimationOptions = .curveLinear) -> ChainAnimator {
        ChainAnimator(
            previousAnimator: self,
            animationValue: .init(
                duration: duration,
                delay: delay,
                dampingRatio: dampingRatio,
                velocity: velocity,
                options: options
            )
        )
    }
    
    /// Perform all chaining animation starting from the first
    /// - Returns: Promise of Bool, if the Promise result is true then all animation is succeed
    @discardableResult
    public func animate() -> Promise<Bool> {
        let promise: Promise<Bool> = .init(currentQueue: .main)
        defer {
            runAnimationAfterPrevious { succeed in
                promise.result = succeed
            }
        }
        return promise
    }
    
    func runAnimationAfterPrevious(completion: @escaping (Bool) -> Void) {
        guard let previous = previousAnimator else {
            runAnimation(completion: completion)
            return
        }
        let currentAnimator = self
        previous.runAnimationAfterPrevious { succeed in
            currentAnimator.runAnimation { currentSucceed in
                completion(succeed && currentSucceed)
            }
        }
    }
    
    func runAnimation(completion: @escaping (Bool) -> Void) {
        let value = animationValue
        let animation = self.animation
        syncOnMainIfPossible {
            UIView.animate(
                withDuration: value.duration,
                delay: value.delay,
                usingSpringWithDamping: value.dampingRatio,
                initialSpringVelocity: value.velocity,
                options: value.options,
                animations: animation,
                completion: completion
            )
        }
    }
}
#endif
