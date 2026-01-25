//
//  LandingVideoPlayer.swift
//  StockmansWallet
//
//  Custom video player for landing page animation
//  Debug: Plays video once and freezes on last frame, no visible controls
//

import SwiftUI
import AVKit
import AVFoundation
import Combine

// MARK: - Landing Video Player
// Debug: Seamless video playback that appears as animated background
struct LandingVideoPlayer: View {
    let videoName: String
    let videoExtension: String
    @Binding var isPlaying: Bool
    
    @StateObject private var playerManager: VideoPlayerManager
    
    init(videoName: String, videoExtension: String, isPlaying: Binding<Bool>) {
        self.videoName = videoName
        self.videoExtension = videoExtension
        self._isPlaying = isPlaying
        
        // Debug: Create player manager and setup immediately
        let manager = VideoPlayerManager()
        manager.setupPlayer(videoName: videoName, extension: videoExtension)
        self._playerManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        ZStack {
            if let player = playerManager.player {
                // Debug: Use custom video layer view for proper aspect ratio
                VideoPlayerLayerView(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        if isPlaying && !UIAccessibility.isReduceMotionEnabled {
                            playerManager.play()
                        }
                    }
                    .onDisappear {
                        playerManager.pause()
                    }
                    .onChange(of: isPlaying) { _, newValue in
                        if newValue && !UIAccessibility.isReduceMotionEnabled {
                            playerManager.play()
                        } else {
                            playerManager.pause()
                        }
                    }
            } else {
                // Debug: Show black screen while loading
                Color.black
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Video Player Layer View
// Debug: Custom UIViewRepresentable for AVPlayerLayer with proper aspect fill
struct VideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = VideoPlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill // Debug: Fill screen maintaining aspect ratio
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Debug: Update player if needed
        if let videoView = uiView as? VideoPlayerUIView {
            videoView.playerLayer.player = player
        }
    }
}

// MARK: - Video Player UI View
// Debug: Custom UIView with AVPlayerLayer
class VideoPlayerUIView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
}

// MARK: - Video Player Manager
// Debug: Manages AVPlayer lifecycle, playback, and freeze on last frame
class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: AnyCancellable?
    
    deinit {
        cleanup()
    }
    
    // Debug: Setup player with video file from bundle
    func setupPlayer(videoName: String, extension: String) {
        // Debug: List all video files in bundle for troubleshooting
        if let bundlePath = Bundle.main.resourcePath {
            print("📦 Bundle path: \(bundlePath)")
            
            // Try to find video files
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: bundlePath) {
                let videoFiles = files.filter { $0.hasSuffix(".mp4") || $0.hasSuffix(".mov") }
                print("🎥 Video files in bundle: \(videoFiles)")
            }
        }
        
        // Try multiple search methods
        var videoURL: URL?
        
        // Method 1: Direct resource lookup
        videoURL = Bundle.main.url(forResource: videoName, withExtension: `extension`)
        
        // Method 2: Try path lookup if first method fails
        if videoURL == nil {
            if let path = Bundle.main.path(forResource: videoName, ofType: `extension`) {
                videoURL = URL(fileURLWithPath: path)
                print("📍 Found via path: \(path)")
            }
        }
        
        // Method 3: Try common variations
        if videoURL == nil {
            let variations = [
                videoName,
                videoName.lowercased(),
                videoName.uppercased()
            ]
            
            for variant in variations {
                if let url = Bundle.main.url(forResource: variant, withExtension: `extension`) {
                    videoURL = url
                    print("📍 Found via variant: \(variant)")
                    break
                }
            }
        }
        
        guard let finalURL = videoURL else {
            print("❌ Video file not found: \(videoName).\(`extension`)")
            print("❌ Tried: \(videoName).\(`extension`)")
            print("💡 Make sure the video is added to the Xcode project target")
            return
        }
        
        print("✅ Video URL found: \(finalURL)")
        
        let playerItem = AVPlayerItem(url: finalURL)
        player = AVPlayer(playerItem: playerItem)
        
        // Debug: Disable audio (no sound for landing animation)
        player?.isMuted = true
        
        // Debug: Observer to freeze on last frame
        setupPlaybackObserver()
        
        print("✅ Video player setup complete: \(videoName).\(`extension`)")
    }
    
    // Debug: Monitor playback and freeze on last frame
    private func setupPlaybackObserver() {
        guard let player = player else { return }
        
        // Debug: Observe when video reaches the end
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            // Debug: Seek to last frame and pause
            self?.freezeOnLastFrame()
        }
    }
    
    // Debug: Freeze video on the last frame
    private func freezeOnLastFrame() {
        guard let player = player,
              let duration = player.currentItem?.duration else { return }
        
        // Debug: Seek to very end (last frame) and pause
        let endTime = CMTimeSubtract(duration, CMTime(seconds: 0.01, preferredTimescale: 600))
        player.seek(to: endTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            player.pause()
        }
        
        print("🎬 Video frozen on last frame")
    }
    
    // Debug: Start playback from beginning
    func play() {
        guard let player = player else { return }
        
        // Debug: If already at end, restart from beginning
        if let duration = player.currentItem?.duration,
           CMTimeCompare(player.currentTime(), duration) == 0 {
            player.seek(to: .zero)
        }
        
        player.play()
        print("▶️ Video playback started")
    }
    
    // Debug: Pause playback
    func pause() {
        player?.pause()
        print("⏸️ Video playback paused")
    }
    
    // Debug: Clean up observers and player
    private func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        statusObserver?.cancel()
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
        print("🧹 Video player cleaned up")
    }
}
