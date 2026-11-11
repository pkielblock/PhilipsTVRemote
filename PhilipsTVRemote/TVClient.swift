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
    func sendKey(_ key: TVKey) {
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

    // MARK: - Discovery

    struct FoundTV: Identifiable, Hashable, Sendable {
        let host: String
        let name: String
        var id: String { host }
    }

    @Published var found: [FoundTV] = []
    @Published var scanning = false

    /// Use the saved TV if it answers; otherwise search the Wi-Fi and pick the TV
    /// when exactly one is found (the IP can change with DHCP).
    func autoConnect() async {
        if !host.isEmpty {
            await refreshVolume()
            if online { return }
        }
        await scan()
        if found.count == 1, found[0].host != host {
            host = found[0].host
            await refreshVolume()
        }
    }

    /// Asks every address in the phone's Wi-Fi subnet for JointSpace's /1/system on port 1925.
    /// Plain unicast HTTP: SSDP multicast would need Apple's multicast entitlement.
    func scan() async {
        guard !scanning else { return }
        // Self-check of the address math: 192.168.1.50/24 → 253 peers, /16 → its /24, /30 → 1 peer.
        assert(Self.hosts(ip: 0xC0A8_0132, mask: 0xFFFF_FF00).count == 253
               && Self.hosts(ip: 0xC0A8_0132, mask: 0xFFFF_0000).first == "192.168.1.1"
               && Self.hosts(ip: 0x0A00_0001, mask: 0xFFFF_FFFC) == ["10.0.0.2"])
        scanning = true
        defer { scanning = false }
        guard let net = Self.wifiSubnet() else { found = []; return }
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 2
        cfg.waitsForConnectivity = false
        let probeSession = URLSession(configuration: cfg)
        defer { probeSession.invalidateAndCancel() }
        found = await withTaskGroup(of: FoundTV?.self) { group in
            for h in Self.hosts(ip: net.ip, mask: net.mask) {
                group.addTask { await Self.probe(h, probeSession) }
            }
            var out: [FoundTV] = []
            for await tv in group { if let tv { out.append(tv) } }
            return out.sorted { $0.host.localizedStandardCompare($1.host) == .orderedAscending }
        }
    }

    nonisolated private static func probe(_ host: String, _ session: URLSession) async -> FoundTV? {
        guard let url = URL(string: "http://\(host):1925/1/system"),
              let (data, resp) = try? await session.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let name = obj["name"] as? String ?? obj["model"] as? String else { return nil }
        return FoundTV(host: host, name: name)
    }

    /// The phone's Wi-Fi (en0) IPv4 address and netmask, host byte order.
    nonisolated static func wifiSubnet() -> (ip: UInt32, mask: UInt32)? {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return nil }
        defer { freeifaddrs(list) }
        for p in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let i = p.pointee
            guard String(cString: i.ifa_name) == "en0",
                  let addr = i.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET),
                  let mask = i.ifa_netmask else { continue }
            func v4(_ s: UnsafeMutablePointer<sockaddr>) -> UInt32 {
                s.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { UInt32(bigEndian: $0.pointee.sin_addr.s_addr) }
            }
            return (v4(addr), v4(mask))
        }
        return nil
    }

    /// Every host in the subnet except the network, broadcast and the phone itself.
    /// shortcut: subnets wider than /24 scan only the phone's /24; widen if a TV sits outside it.
    nonisolated static func hosts(ip: UInt32, mask: UInt32) -> [String] {
        let mask = max(mask, 0xFFFF_FF00)
        let net = ip & mask, broadcast = net | ~mask
        guard broadcast > net &+ 1 else { return [] }
        return (net + 1 ..< broadcast).filter { $0 != ip }.map {
            "\($0 >> 24).\($0 >> 16 & 0xFF).\($0 >> 8 & 0xFF).\($0 & 0xFF)"
        }
    }

    // MARK: - Power

    /// Eco "screen off": Adjust > Eco settings > Screen off. Panel goes dark
    /// but Wi-Fi stays up, so any key (see screenOn()) brings it back.
    /// Real standby isn't used: it drops Wi-Fi and the set ignores Wake-on-LAN.
    /// Delays give the on-screen menu time to open between keys.
    func screenOff() {
        let keys: [TVKey] = [.adjust, .cursorRight, .confirm, .cursorDown, .confirm]
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
