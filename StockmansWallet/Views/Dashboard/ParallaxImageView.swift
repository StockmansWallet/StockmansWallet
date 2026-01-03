//
//  ParallaxImageView.swift
//  StockmansWallet
//
//  Parallax Background Image using built-in UIMotionEffect
//  Debug: Uses native iOS parallax (same as home screen wallpapers)
//

import SwiftUI
import UIKit

// MARK: - Parallax Image View (SwiftUI)
struct ParallaxImageView: View {
    let imageName: String
    let intensity: CGFloat // How much movement (default: 20-30 points)
    let opacity: Double
    let scale: CGFloat // Scale DOWN to show more (0.5 = 50% of screen height)
    let verticalOffset: CGFloat // Position from top
    let blur: CGFloat // Blur radius
    
    init(
        imageName: String,
        intensity: CGFloat = 25,
        opacity: Double = 0.1,
        scale: CGFloat = 0.5, // 50% of screen height by default
        verticalOffset: CGFloat = 0, // Start at top by default
        blur: CGFloat = 0 // No blur by default
    ) {
        self.imageName = imageName
        self.intensity = intensity
        self.opacity = opacity
        self.scale = scale
        self.verticalOffset = verticalOffset
        self.blur = blur
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ParallaxImageRepresentable(
                    imageName: imageName,
                    intensity: intensity,
                    size: geometry.size,
                    scale: scale,
                    verticalOffset: verticalOffset
                )
                .blur(radius: blur) // Apply blur effect
                .opacity(opacity)
                
                // Debug: Bottom fade gradient to hide image edge when pulled down
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Start fade from middle-bottom area
                    LinearGradient(
                        colors: [
                            .clear,
                            Theme.backgroundColor.opacity(0.5),
                            Theme.backgroundColor.opacity(0.9),
                            Theme.backgroundColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.4) // Fade over bottom 40% of image
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - UIKit Representable Wrapper
struct ParallaxImageRepresentable: UIViewRepresentable {
    let imageName: String
    let intensity: CGFloat
    let size: CGSize
    let scale: CGFloat
    let verticalOffset: CGFloat
    
    func makeUIView(context: Context) -> ParallaxImageUIView {
        let view = ParallaxImageUIView(
            imageName: imageName,
            intensity: intensity,
            scale: scale,
            verticalOffset: verticalOffset
        )
        return view
    }
    
    func updateUIView(_ uiView: ParallaxImageUIView, context: Context) {
        uiView.updateSize(size)
    }
}

// MARK: - UIKit View with Motion Effect
class ParallaxImageUIView: UIView {
    private let imageView: UIImageView
    private let intensity: CGFloat
    private let scale: CGFloat
    private let verticalOffset: CGFloat
    
    init(imageName: String, intensity: CGFloat, scale: CGFloat, verticalOffset: CGFloat) {
        self.intensity = intensity
        self.scale = scale
        self.verticalOffset = verticalOffset
        self.imageView = UIImageView(image: UIImage(named: imageName))
        
        super.init(frame: .zero)
        
        // Configure image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = false  // Don't clip to allow full width
        self.clipsToBounds = true  // Clip at parent level instead
        addSubview(imageView)
        
        // Add parallax motion effects
        addParallaxMotionEffects()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Debug: Keep FULL WIDTH to prevent cropping on sides
        // Only scale down the HEIGHT to show more of the image
        let finalWidth = bounds.width + (intensity * 2)  // Full width + parallax padding
        let finalHeight = (bounds.height * scale) + (intensity * 2)  // Scale height + parallax padding
        
        // Position: centered horizontally (accounting for padding), vertically at offset
        let xPosition = -intensity  // Start at left edge with padding buffer
        let yPosition = verticalOffset  // Start at top with optional offset
        
        imageView.frame = CGRect(
            x: xPosition,
            y: yPosition,
            width: finalWidth,
            height: finalHeight
        )
    }
    
    func updateSize(_ size: CGSize) {
        frame.size = size
        setNeedsLayout()
    }
    
    // MARK: - Parallax Motion Effects (Built-in iOS Feature)
    // Debug: Uses UIInterpolatingMotionEffect - same technology as iOS home screen wallpapers
    private func addParallaxMotionEffects() {
        // Horizontal motion effect
        let horizontalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.x",
            type: .tiltAlongHorizontalAxis
        )
        horizontalEffect.minimumRelativeValue = -intensity
        horizontalEffect.maximumRelativeValue = intensity
        
        // Vertical motion effect
        let verticalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.y",
            type: .tiltAlongVerticalAxis
        )
        verticalEffect.minimumRelativeValue = -intensity
        verticalEffect.maximumRelativeValue = intensity
        
        // Debug: Combine effects into a group
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [horizontalEffect, verticalEffect]
        
        // Apply to image view
        imageView.addMotionEffect(motionEffectGroup)
    }
}

