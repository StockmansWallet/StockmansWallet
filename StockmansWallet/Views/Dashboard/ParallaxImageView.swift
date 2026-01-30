//
//  ParallaxImageView.swift
//  StockmansWallet
//
//  Parallax Background Image using built-in UIMotionEffect
//  Debug: Uses native iOS parallax (same as home screen wallpapers)
//  Includes support for both built-in assets and custom user-uploaded images
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
                
                // Debug: Bottom fade gradient to blend image edge seamlessly into background
                // Fixed 300pt gradient provides consistent, smooth transition
                VStack(spacing: 0) {
                    Spacer()
                    
                    LinearGradient(
                        colors: [
                            Color.clear,                          // Transparent at top
                            Theme.background.opacity(0.2),   // Gentle start
                            Theme.background.opacity(0.5),   // Mid fade
                            Theme.background.opacity(0.8),   // Strong fade
                            Theme.background                 // Solid at bottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 300)  // Fixed 300pt gradient fade zone
                    .allowsHitTesting(false)  // Don't intercept touches
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

// MARK: - Custom Parallax Image View (for user-uploaded images)
// Debug: Same as ParallaxImageView but loads images from document directory
struct CustomParallaxImageView: View {
    let imageName: String
    let intensity: CGFloat
    let opacity: Double
    let scale: CGFloat
    let verticalOffset: CGFloat
    let blur: CGFloat
    
    init(
        imageName: String,
        intensity: CGFloat = 25,
        opacity: Double = 0.1,
        scale: CGFloat = 0.5,
        verticalOffset: CGFloat = 0,
        blur: CGFloat = 0
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
                CustomParallaxImageRepresentable(
                    imageName: imageName,
                    intensity: intensity,
                    size: geometry.size,
                    scale: scale,
                    verticalOffset: verticalOffset
                )
                .blur(radius: blur)
                .opacity(opacity)
                
                // Debug: Bottom fade gradient to blend image edge seamlessly into background
                // Fixed 300pt gradient provides consistent, smooth transition
                VStack(spacing: 0) {
                    Spacer()
                    
                    LinearGradient(
                        colors: [
                            Color.clear,                          // Transparent at top
                            Theme.background.opacity(0.2),   // Gentle start
                            Theme.background.opacity(0.5),   // Mid fade
                            Theme.background.opacity(0.8),   // Strong fade
                            Theme.background                 // Solid at bottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 300)  // Fixed 300pt gradient fade zone
                    .allowsHitTesting(false)  // Don't intercept touches
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Custom UIKit Representable Wrapper
struct CustomParallaxImageRepresentable: UIViewRepresentable {
    let imageName: String
    let intensity: CGFloat
    let size: CGSize
    let scale: CGFloat
    let verticalOffset: CGFloat
    
    func makeUIView(context: Context) -> CustomParallaxImageUIView {
        let view = CustomParallaxImageUIView(
            imageName: imageName,
            intensity: intensity,
            scale: scale,
            verticalOffset: verticalOffset
        )
        return view
    }
    
    func updateUIView(_ uiView: CustomParallaxImageUIView, context: Context) {
        uiView.updateSize(size)
    }
}

// MARK: - Custom UIKit View with Motion Effect (loads from document directory)
class CustomParallaxImageUIView: UIView {
    private let imageView: UIImageView
    private let intensity: CGFloat
    private let scale: CGFloat
    private let verticalOffset: CGFloat
    
    init(imageName: String, intensity: CGFloat, scale: CGFloat, verticalOffset: CGFloat) {
        self.intensity = intensity
        self.scale = scale
        self.verticalOffset = verticalOffset
        
        // Debug: Load custom image from document directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(imageName)
        
        var customImage: UIImage?
        if let imageData = try? Data(contentsOf: fileURL) {
            customImage = UIImage(data: imageData)
        }
        
        self.imageView = UIImageView(image: customImage)
        
        super.init(frame: .zero)
        
        // Configure image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = false
        self.clipsToBounds = true
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
        let finalWidth = bounds.width + (intensity * 2)
        let finalHeight = (bounds.height * scale) + (intensity * 2)
        
        let xPosition = -intensity
        let yPosition = verticalOffset
        
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
    
    // MARK: - Parallax Motion Effects
    private func addParallaxMotionEffects() {
        let horizontalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.x",
            type: .tiltAlongHorizontalAxis
        )
        horizontalEffect.minimumRelativeValue = -intensity
        horizontalEffect.maximumRelativeValue = intensity
        
        let verticalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.y",
            type: .tiltAlongVerticalAxis
        )
        verticalEffect.minimumRelativeValue = -intensity
        verticalEffect.maximumRelativeValue = intensity
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [horizontalEffect, verticalEffect]
        
        imageView.addMotionEffect(motionEffectGroup)
    }
}

