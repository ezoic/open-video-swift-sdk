import AVFoundation
import Foundation
import OpenVideoCore
import UIKit

/// Native player: HLS from `videosvc.ezoic.com/play`, IMA preroll, publisher pixels, 30s Premium preview.
public final class OpenVideoPlayerView: UIView {
    public weak var delegate: OpenVideoPlayerDelegate?

    private let initialVideoId: String?
    private let playlistId: String?
    private let api = OpenVideoAPIClient()
    private let player = AVPlayer()
    private let playerLayer = AVPlayerLayer()
    private var instream: InstreamIMAController?
    private var timeObserver: Any?
    private var previewWork: DispatchWorkItem?
    private var firedQuartiles = Set<Int>()
    private var pixelSession: PixelContract.Session?
    private var currentVideoId: String?
    private var playlistQueue: [String] = []
    private var contentStarted = false

    public convenience init(videoId: String) {
        self.init(videoId: videoId, playlistId: nil)
    }

    public convenience init(playlistId: String) {
        self.init(videoId: nil, playlistId: playlistId)
    }

    private init(videoId: String?, playlistId: String?) {
        self.initialVideoId = videoId
        self.playlistId = playlistId
        super.init(frame: .zero)
        backgroundColor = .black
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    deinit {
        previewWork?.cancel()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        NotificationCenter.default.removeObserver(self)
        instream?.destroy()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        instream?.layoutAdContainer(in: bounds)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, currentVideoId == nil else { return }
        Task { @MainActor in
            await start()
        }
    }

    @MainActor
    private func start() async {
        do {
            let runtime = try OpenVideo.requireState()
            if let playlistId {
                playlistQueue = try await api.fetchPlaylistVideoIds(playlistId: playlistId)
                guard let first = playlistQueue.first else { throw OpenVideoCoreError.emptyPlaylist }
                try await loadVideo(id: first, runtime: runtime, playlistItem: true)
            } else if let initialVideoId {
                try await loadVideo(id: initialVideoId, runtime: runtime, playlistItem: false)
            } else {
                throw OpenVideoCoreError.missingVideoId
            }
        } catch {
            delegate?.openVideoPlayer(self, didFail: error)
        }
    }

    @MainActor
    private func loadVideo(id: String, runtime: OpenVideo.RuntimeState, playlistItem: Bool) async throws {
        currentVideoId = id
        firedQuartiles.removeAll()
        contentStarted = false
        let preview = runtime.config.isPreviewCTA
        let stream = try await api.fetchPlay(videoId: id, preview: preview)
        let pageURL = PixelContract.watchOnSiteURL(hostname: runtime.hostname, videoId: id).absoluteString
        pixelSession = PixelContract.Session(
            domainId: runtime.config.domainId,
            insertMethod: runtime.config.iosInsertMethod,
            visitUUID: runtime.visitUUID,
            pageviewId: UUID().uuidString,
            videoImpressionId: UUID().uuidString,
            contentId: id,
            mediaSrc: stream.src.absoluteString,
            videoTitle: id,
            videoLengthSeconds: stream.durationMs / 1000,
            pageURL: pageURL,
            width: Int(bounds.width),
            height: Int(bounds.height),
            isPlaylistItem: playlistItem,
            isAutoplay: true
        )
        let item = AVPlayerItem(url: stream.src)
        player.replaceCurrentItem(with: item)
        attachTimeObserver()
        instream?.destroy()
        instream = InstreamIMAController(
            hostView: self,
            player: player,
            contentURL: stream.src,
            adsEnabled: runtime.config.ads.enabled,
            onAdEvent: { [weak self] name in
                self?.fireAdPixel(name)
            },
            onContentShouldPlay: { [weak self] in
                self?.beginContent(preview: preview, videoId: id, hostname: runtime.hostname)
            }
        )
        instream?.start()
    }

    private func beginContent(preview: Bool, videoId: String, hostname: String) {
        player.play()
        if !contentStarted {
            contentStarted = true
            fireContentPixel(PixelContract.ContentEvent.videoStart.rawValue)
            fireContentPixel(PixelContract.ContentEvent.viewedStart.rawValue)
            delegate?.openVideoPlayerDidStartContent(self)
        }
        previewWork?.cancel()
        if preview {
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.player.pause()
                let url = PixelContract.watchOnSiteURL(hostname: hostname, videoId: videoId)
                self.delegate?.openVideoPlayerDidHitPreviewLimit(self, watchURL: url)
            }
            previewWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: work)
        }
    }

    private func attachTimeObserver() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleProgress(time)
        }
    }

    private func handleProgress(_ time: CMTime) {
        guard let item = player.currentItem else { return }
        let duration = item.duration.seconds
        let elapsed = time.seconds
        guard duration.isFinite, duration > 0, elapsed.isFinite else { return }
        let ratio = elapsed / duration
        if ratio >= 0.25 { fireQuartile(25, event: .viewedFirstQuartile) }
        if ratio >= 0.50 { fireQuartile(50, event: .viewedMiddle) }
        if ratio >= 0.75 { fireQuartile(75, event: .viewedThirdQuartile) }
    }

    private func fireQuartile(_ mark: Int, event: PixelContract.ContentEvent) {
        guard !firedQuartiles.contains(mark) else { return }
        firedQuartiles.insert(mark)
        fireContentPixel(event.rawValue)
    }

    @objc private func itemDidEnd() {
        fireContentPixel(PixelContract.ContentEvent.viewedEnd.rawValue)
        fireContentPixel(PixelContract.ContentEvent.completed.rawValue)
        guard let runtime = try? OpenVideo.requireState() else { return }
        if !playlistQueue.isEmpty, let current = currentVideoId,
           let idx = playlistQueue.firstIndex(of: current),
           idx + 1 < playlistQueue.count
        {
            let next = playlistQueue[idx + 1]
            Task { @MainActor in
                try? await loadVideo(id: next, runtime: runtime, playlistItem: true)
            }
        }
    }

    private func fireContentPixel(_ name: String) {
        guard let session = pixelSession else { return }
        Task {
            if let vid = try? PixelContract.vidURL(session: session) {
                await api.getPixel(url: vid)
            }
            if let g = try? PixelContract.grapefruitURL(
                domainId: session.domainId,
                impressionId: session.videoImpressionId,
                eventName: name
            ) {
                await api.getPixel(url: g)
            }
        }
    }

    private func fireAdPixel(_ name: String) {
        guard let session = pixelSession else { return }
        Task {
            if let g = try? PixelContract.grapefruitURL(
                domainId: session.domainId,
                impressionId: session.videoImpressionId,
                eventName: name
            ) {
                await api.getPixel(url: g)
            }
        }
    }
}
