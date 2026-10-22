import Foundation

/// JointSpace v1 client for Philips NetTV sets (chassis TPM16.5L / 32PHG5201).
/// No authentication on this generation; all calls are plain HTTP on port 1925.
@MainActor
final class TVClient: ObservableObject {
    @Published var host: String {
        didSet { UserDefaults.standard.set(host, forKey: "tv.host") }
    }
    @Published var volume: Int?
    @Published var muted = false
    @Published var online = false
    @Published var lastError: String?
    @Published var sources: [Source] = []

    struct Source: Identifiable, Hashable {
        let id: String
        let name: String
    }

    private let session: URLSession

    init() {
        self.host = UserDefaults.standard.string(forKey: "tv.host") ?? ""
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 4
        cfg.waitsForConnectivity = false
        self.session = URLSession(configuration: cfg)
    }

    private func base() -> URL? {
        host.isEmpty ? nil : URL(string: "http://\(host):1925/1/")
    }

    // MARK: - Remote keys

    /// Send a remote-control key. The TV always answers 200, so success here
    /// means the request reached the set, not that the key was valid.
    func sendKey(_ key: RemoteKey) {
        guard let url = base()?.appendingPathComponent("input/key") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = #"{"key":"\#(key.rawValue)"}"#.data(using: .utf8)
        Task {
            do {
                _ = try await session.data(for: req)
                online = true
                lastError = nil
                if key == .volumeUp || key == .volumeDown || key == .mute {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await refreshVolume()
                }
            } catch {
                online = false
                lastError = L("TV not responding", "Sem resposta da TV")
            }
        }
    }

    // MARK: - Status

    func refreshVolume() async {
        guard let url = base()?.appendingPathComponent("audio/volume") else { return }
        do {
            let (data, _) = try await session.data(from: url)
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                volume = obj["current"] as? Int
                muted = obj["muted"] as? Bool ?? false
                online = true
                lastError = nil
            }
        } catch {
            online = false
        }
    }

    /// Absolute volume set (0...60 on this model).
    func setVolume(_ value: Int) {
        guard let url = base()?.appendingPathComponent("audio/volume") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = #"{"muted":false,"current":\#(value)}"#.data(using: .utf8)
        volume = value
        Task { _ = try? await session.data(for: req) }
    }

    // MARK: - Sources

    /// Fetch the input list. Order isn't defined by the API, so sort by name.
    func fetchSources() async {
        guard let url = base()?.appendingPathComponent("sources") else { return }
        do {
            let (data, _) = try await session.data(from: url)
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                sources = obj.compactMap { key, value in
                    guard let dict = value as? [String: Any],
                          let name = dict["name"] as? String else { return nil }
                    return Source(id: key, name: name)
                }.sorted { $0.name < $1.name }
                online = true
                lastError = nil
            }
        } catch {
            online = false
            lastError = L("TV not responding", "Sem resposta da TV")
        }
    }

    /// Switch the active input. On this generation the set accepts
    /// POST /1/sources/current with the source id.
    func setSource(_ id: String) {
        guard let url = base()?.appendingPathComponent("sources/current") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = #"{"id":"\#(id)"}"#.data(using: .utf8)
        Task {
            do {
                _ = try await session.data(for: req)
                online = true; lastError = nil
            } catch {
                online = false; lastError = L("TV not responding", "Sem resposta da TV")
            }
        }
    }

    // MARK: - Power

    /// Eco "screen off": Adjust > Eco settings > Screen off. Panel goes dark
    /// but Wi-Fi stays up, so any key (see screenOn()) brings it back.
    /// Real standby isn't used: it drops Wi-Fi and the set ignores Wake-on-LAN.
    /// Delays give the on-screen menu time to open between keys.
    func screenOff() {
        let keys: [RemoteKey] = [.adjust, .cursorRight, .confirm, .cursorDown, .confirm]
        Task {
            for k in keys {
                sendKey(k)
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
        }
    }

    /// Any key wakes the panel from eco screen off.
    func screenOn() { sendKey(.cursorUp) }
}
