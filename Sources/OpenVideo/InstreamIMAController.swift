import AVFoundation
import EzoicAdsSDK
import Foundation
import GoogleInteractiveMediaAds
import UIKit

/// Host IMA: `EzoicInstreamAd` VAST URL → `IMAAdsLoader`. No-fill → content plays.
final class InstreamIMAController: NSObject, EzoicInstreamAdDelegate, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    private weak var hostView: UIView?
    private let player: AVPlayer
    private let contentURL: URL
    private let adsEnabled: Bool
    private let onAdEvent: (String) -> Void
    private let onContentShouldPlay: () -> Void

    private let adContainer = UIView()
    private var instreamAd: EzoicInstreamAd?
    private var adsLoader: IMAAdsLoader?
    private var adsManager: IMAAdsManager?
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private var startedContent = false

    init(
        hostView: UIView,
        player: AVPlayer,
        contentURL: URL,
        adsEnabled: Bool,
        onAdEvent: @escaping (String) -> Void,
        onContentShouldPlay: @escaping () -> Void
    ) {
        self.hostView = hostView
        self.player = player
        self.contentURL = contentURL
        self.adsEnabled = adsEnabled
        self.onAdEvent = onAdEvent
        self.onContentShouldPlay = onContentShouldPlay
        super.init()
        adContainer.isUserInteractionEnabled = true
        hostView.addSubview(adContainer)
    }

    func layoutAdContainer(in bounds: CGRect) {
        adContainer.frame = bounds
    }

    func start() {
        guard adsEnabled else {
            playContent()
            return
        }
        let instream = EzoicInstreamAd(adUnitId: OpenVideo.defaultInstreamAdUnitId)
        instreamAd = instream
        instream.load(contentUrl: contentURL.absoluteString, delegate: self)
    }

    func destroy() {
        adsManager?.destroy()
        adsManager = nil
        adsLoader = nil
        instreamAd = nil
        adContainer.removeFromSuperview()
    }

    private func playContent() {
        guard !startedContent else { return }
        startedContent = true
        onContentShouldPlay()
    }

    private func requestIMA(adTagUrl: String) {
        guard let hostView, let vc = hostView.ov_nearestViewController() else {
            playContent()
            return
        }
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
        let display = IMAAdDisplayContainer(adContainer: adContainer, viewController: vc)
        let loader = IMAAdsLoader(settings: nil)
        loader.delegate = self
        adsLoader = loader
        let request = IMAAdsRequest(
            adTagUrl: adTagUrl,
            adDisplayContainer: display,
            contentPlayhead: contentPlayhead,
            userContext: nil
        )
        loader.requestAds(with: request)
    }

    // MARK: EzoicInstreamAdDelegate

    func instreamAd(_ instreamAd: EzoicInstreamAd, didReceiveAdTag adTagUrl: String) {
        requestIMA(adTagUrl: adTagUrl)
    }

    func instreamAd(_ instreamAd: EzoicInstreamAd, didFailToLoadWithError error: EzoicError) {
        playContent()
    }

    // MARK: IMAAdsLoaderDelegate

    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        adsManager?.initialize(with: nil)
    }

    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        if let next = instreamAd?.getNextAdTagUrl() {
            requestIMA(adTagUrl: next)
            return
        }
        playContent()
    }

    // MARK: IMAAdsManagerDelegate

    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        switch event.type {
        case .STARTED:
            instreamAd?.reportImpression()
            onAdEvent(PixelContract.AdEvent.adStart.rawValue)
        case .FIRST_QUARTILE:
            onAdEvent(PixelContract.AdEvent.viewedFirstQuartile.rawValue)
        case .MIDPOINT:
            onAdEvent(PixelContract.AdEvent.viewedMidpoint.rawValue)
        case .THIRD_QUARTILE:
            onAdEvent(PixelContract.AdEvent.viewedThirdQuartile.rawValue)
        case .COMPLETE, .SKIPPED:
            onAdEvent(PixelContract.AdEvent.completed.rawValue)
        default:
            break
        }
        if event.type == .LOADED {
            adsManager.start()
        }
    }

    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        onAdEvent(PixelContract.AdEvent.errored.rawValue)
        if let next = instreamAd?.getNextAdTagUrl() {
            requestIMA(adTagUrl: next)
            return
        }
        adsManager.destroy()
        playContent()
    }

    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        player.pause()
    }

    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        playContent()
    }
}

extension UIView {
    func ov_nearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let vc = current as? UIViewController { return vc }
            responder = current.next
        }
        return nil
    }
}
