//
//  LottieView.swift
//  StockmansWallet
//
//  SwiftUI wrapper for Lottie animations (v4+).
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .playOnce
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var speed: CGFloat = 1.0

    // External control: play once when true, stop when false.
    @Binding var isPlaying: Bool
    // Optional callback when the animation finishes.
    var onCompleted: (() -> Void)? = nil

    final class Coordinator {
        // Force Main Thread rendering engine via configuration
        private let configuration = LottieConfiguration(renderingEngine: .mainThread)
        let animationView: LottieAnimationView
        var onCompleted: (() -> Void)?

        init() {
            // Initialize the LottieAnimationView with the Main Thread configuration
            self.animationView = LottieAnimationView(configuration: configuration)
            // Explicit (optional): ensure default background behavior for Main Thread
            self.animationView.backgroundBehavior = .pauseAndRestore
        }

        func configure(animationName: String,
                       loopMode: LottieLoopMode,
                       contentMode: UIView.ContentMode,
                       speed: CGFloat) {
            animationView.backgroundColor = .clear
            animationView.contentMode = contentMode
            animationView.loopMode = loopMode
            animationView.animationSpeed = speed
            
            // Debug: Performance optimizations for smooth 60fps playback
            animationView.shouldRasterizeWhenIdle = true // Rasterize when not animating
            animationView.layer.drawsAsynchronously = true // Async drawing for better performance

            if let animation = LottieAnimation.named(animationName) {
                animationView.animation = animation
                // Debug: Log animation info for debugging
                print("LottieView: Loaded '\(animationName)' - Duration: \(animation.duration)s, FPS: \(animation.framerate)")
            } else {
                print("LottieView: Failed to load animation named \(animationName)")
            }
        }

        func playOnce(completion: (() -> Void)? = nil) {
            animationView.play { [weak self] finished in
                if finished {
                    // Leave at final frame so it remains visible.
                    self?.animationView.currentProgress = 1.0
                    completion?()
                    self?.onCompleted?()
                }
            }
        }

        func stop() {
            animationView.stop()
        }
    }

    func makeCoordinator() -> Coordinator {
        let c = Coordinator()
        c.onCompleted = onCompleted
        return c
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear // Transparent container, animation content provides opacity

        let animationView = context.coordinator.animationView
        context.coordinator.configure(
            animationName: animationName,
            loopMode: loopMode,
            contentMode: contentMode,
            speed: speed
        )

        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        if isPlaying {
            context.coordinator.playOnce()
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let animationView = context.coordinator.animationView
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.contentMode = contentMode

        if isPlaying && !animationView.isAnimationPlaying {
            context.coordinator.playOnce()
        } else if !isPlaying && animationView.isAnimationPlaying {
            context.coordinator.stop()
        }
    }
}
