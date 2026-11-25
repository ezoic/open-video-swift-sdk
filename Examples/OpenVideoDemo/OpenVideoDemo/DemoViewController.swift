import EzoicAdsSDK
import OpenVideo
import UIKit

/// Configures OpenVideo and presents consent before starting playback.
final class DemoViewController: UIViewController, OpenVideoPlayerDelegate {
    private let status = UILabel()
    private let videoButton = UIButton(type: .system)
    private let playlistButton = UIButton(type: .system)
    private let playerHost = UIView()
    private var playerView: OpenVideoPlayerView?
    private var didStartSetup = false
    private var configured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildChrome()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStartSetup else { return }
        didStartSetup = true
        Task { await configureSDK() }
    }

    @MainActor
    private func configureSDK() async {
        status.text = "Configuring hackasaur.us…"
        do {
            try await OpenVideo.configure(domain: "hackasaur.us")
            let consent = await EzoicAds.shared.presentConsentIfRequired(from: self)
            if case .failed(let error) = consent {
                print("OpenVideoDemo: consent presentation failed (playback continues): \(error)")
            }
            configured = true
            status.text = "Ready OpenVideo \(OpenVideo.version)"
            videoButton.isEnabled = true
            playlistButton.isEnabled = true
            playVideo()
        } catch {
            status.text = "Error \(error.localizedDescription)"
        }
    }

    @objc private func playVideo() {
        guard configured else { return }
        showPlayer(OpenVideoPlayerView(videoId: "DdXGnZvrBZu"))
        status.text = "Video DdXGnZvrBZu"
    }

    @objc private func playPlaylist() {
        guard configured else { return }
        showPlayer(OpenVideoPlayerView(playlistId: "5tXyasXrAIp"))
        status.text = "Playlist 5tXyasXrAIp"
    }

    private func showPlayer(_ next: OpenVideoPlayerView) {
        playerView?.delegate = nil
        playerView?.removeFromSuperview()
        next.delegate = self
        next.translatesAutoresizingMaskIntoConstraints = false
        playerHost.addSubview(next)
        NSLayoutConstraint.activate([
            next.leadingAnchor.constraint(equalTo: playerHost.leadingAnchor),
            next.trailingAnchor.constraint(equalTo: playerHost.trailingAnchor),
            next.topAnchor.constraint(equalTo: playerHost.topAnchor),
            next.bottomAnchor.constraint(equalTo: playerHost.bottomAnchor),
        ])
        playerView = next
    }

    func openVideoPlayerDidStartContent(_ player: OpenVideoPlayerView) {
        status.text = "Playing"
    }

    func openVideoPlayer(_ player: OpenVideoPlayerView, didFail error: Error) {
        status.text = "Error \(error.localizedDescription)"
    }

    func openVideoPlayerDidHitPreviewLimit(_ player: OpenVideoPlayerView, watchURL: URL) {
        status.text = "Preview \(watchURL.absoluteString)"
    }

    private func buildChrome() {
        status.textColor = .white
        status.numberOfLines = 0
        status.font = .preferredFont(forTextStyle: .footnote)
        status.text = "Starting…"

        videoButton.setTitle("Play video", for: .normal)
        playlistButton.setTitle("Play playlist", for: .normal)
        videoButton.isEnabled = false
        playlistButton.isEnabled = false
        videoButton.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        playlistButton.addTarget(self, action: #selector(playPlaylist), for: .touchUpInside)

        playerHost.backgroundColor = .darkGray

        let buttons = UIStackView(arrangedSubviews: [videoButton, playlistButton])
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 12

        let stack = UIStackView(arrangedSubviews: [status, buttons, playerHost])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            playerHost.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
        ])
    }
}
