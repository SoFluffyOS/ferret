import Cocoa
import FlutterMacOS
import Network

/// Reports wake from sleep and network changes on macOS, so Ferret reconnects
/// right away, and when the screen locks or another account takes over the
/// screen, so private things stop showing. The Android-only calls do nothing
/// here.
public class FerretSystemPlugin: NSObject, FlutterPlugin, SystemHostApi {
    private let flutterApi: SystemFlutterApi
    private var monitor: NWPathMonitor?
    private var lastPath: PathSnapshot?
    private var wakeObserver: NSObjectProtocol?
    private var sessionObservers: [NSObjectProtocol] = []
    private var screenLocked = false
    private var sessionInFront = true

    init(flutterApi: SystemFlutterApi) {
        self.flutterApi = flutterApi
        super.init()
        let session = CGSessionCopyCurrentDictionary() as? [String: Any]
        screenLocked = session?["CGSSessionScreenIsLocked"] as? Bool ?? false
        sessionInFront = session?[kCGSessionOnConsoleKey as String] as? Bool ?? true
        watchSession()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FerretSystemPlugin(flutterApi: SystemFlutterApi(binaryMessenger: registrar.messenger))
        SystemHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
    }

    func isScreenSessionActive() throws -> Bool {
        !screenLocked && sessionInFront
    }

    /// The screen lock comes as a distributed notification; fast user
    /// switching as the workspace's session notifications.
    private func watchSession() {
        let distributed = DistributedNotificationCenter.default()
        let workspace = NSWorkspace.shared.notificationCenter
        sessionObservers = [
            distributed.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
                self?.screenLocked = true
                self?.sendSession()
            },
            distributed.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
                self?.screenLocked = false
                self?.sendSession()
            },
            workspace.addObserver(forName: NSWorkspace.sessionDidResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.sessionInFront = false
                self?.sendSession()
            },
            workspace.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.sessionInFront = true
                self?.sendSession()
            },
        ]
    }

    private func sendSession() {
        let active = !screenLocked && sessionInFront
        Task { @MainActor in
            try? await flutterApi.onScreenSessionChanged(active: active)
        }
    }

    func setNetworkWatching(watching: Bool) throws {
        if watching {
            startWatching()
            return
        }

        stopWatching()
    }

    private func startWatching() {
        if monitor != nil {
            return
        }

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let snapshot = PathSnapshot(path)
            DispatchQueue.main.async { self?.onPath(snapshot) }
        }
        monitor.start(queue: DispatchQueue(label: "ferret_system.network"))
        self.monitor = monitor

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.send(.wake)
        }
    }

    private func stopWatching() {
        monitor?.cancel()
        monitor = nil
        lastPath = nil
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        wakeObserver = nil
    }

    /// The first update describes the current network; only later ones are changes.
    private func onPath(_ snapshot: PathSnapshot) {
        guard let previous = lastPath else {
            lastPath = snapshot
            return
        }

        lastPath = snapshot
        if snapshot == previous {
            return
        }

        if !snapshot.isConnected {
            send(.lost)
            return
        }

        send(previous.isConnected ? .changed : .available)
    }

    private func send(_ change: NetworkChange) {
        Task { @MainActor in
            try? await flutterApi.onNetworkChange(change: change)
        }
    }

    func acquireMulticastLock() throws {}

    func releaseMulticastLock() throws {}

    func isMulticastLockHeld() throws -> Bool { false }

    func listenForActions() throws {}

    func startService() throws {}

    func stopService() throws {}

    func isServiceRunning() throws -> Bool { false }

    func setStartOnBoot(enabled: Bool) throws {}

    func updateStatus(connectedDevices: [String]) throws {}

    func setPause(pause: PauseMessage) throws {}

    func pauseState() throws -> PauseMessage { PauseMessage(paused: false) }

    func isIgnoringBatteryOptimizations() throws -> Bool { true }

    func requestIgnoreBatteryOptimizations() throws -> Bool { false }

    func manufacturer() throws -> String { "apple" }

    func openMakerBatterySettings() throws -> Bool { false }

    func recentServiceStops() throws -> [Int64] { [] }

    func canRequestAddTile() throws -> Bool { false }

    func requestAddTile() async throws -> AddTileResult { .unsupported }

    func areNotificationsAllowed() throws -> Bool { true }

    func requestNotificationPermission() async throws -> Bool { true }
}

/// What identifies a network: whether it's up, through which interfaces,
/// and behind which routers (switching Wi-Fi keeps `en0` but changes these).
private struct PathSnapshot: Equatable {
    let isConnected: Bool
    let interfaces: [String]
    let gateways: [String]

    init(_ path: NWPath) {
        isConnected = path.status == .satisfied
        interfaces = path.availableInterfaces.map(\.name).sorted()
        gateways = path.gateways.map { "\($0)" }.sorted()
    }
}
