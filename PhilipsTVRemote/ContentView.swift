import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tv: TVClient
    @State private var showSettings = false
    @State private var showSources = false
    @State private var taps = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Kiel.Space.s4) {
                    statusBar
                    powerRow
                    transportRows
                    toolRow
                    guideRow
                    smartRow
                    colorRow
                    dpadCluster
                    volumeChannelRow
                    sourcesButton
                    numberPad
                }
                .padding(Kiel.Space.s4)
            }
            .background(Kiel.bg.ignoresSafeArea())
            .toolbarBackground(Kiel.bg, for: .navigationBar)
            .navigationTitle("Philips TV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel(String(localized: "Settings"))
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: taps)
            .sensoryFeedback(.error, trigger: tv.online) { wasOnline, isOnline in wasOnline && !isOnline }
            .sheet(isPresented: $showSettings) { SettingsView().environmentObject(tv) }
            .sheet(isPresented: $showSources) { SourceView().environmentObject(tv) }
            .task {
                await tv.autoConnect()
                // None found, or several and none chosen yet: let the user pick or type the IP.
                if tv.host.isEmpty { showSettings = true }
            }
        }
    }

    // MARK: - Sections

    private var statusBar: some View {
        RemoteStatusBar(
            connected: tv.online,
            message: tv.scanning ? String(localized: "Searching for your TV…")
                : tv.host.isEmpty ? String(localized: "No TV found. Open settings")
                : tv.online ? String(localized: "Connected") : String(localized: "No response"),
            volume: tv.volume,
            isMuted: tv.muted)
    }

    private var powerRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            bigButton(String(localized: "Turn on"), "power") { tv.screenOn() }
            bigButton(String(localized: "Screen off"), "poweroff") { tv.screenOff() }
        }
    }

    private var transportRows: some View {
        VStack(spacing: Kiel.Space.s2) {
            HStack(spacing: Kiel.Space.s3) {
                key("", "stop.fill", .stop)
                key("", "pause.fill", .pause)
                key("", "record.circle", .record)
            }
            HStack(spacing: Kiel.Space.s3) {
                key("", "backward.fill", .rewind)
                key("", "play.fill", .play)
                key("", "forward.fill", .fastForward)
            }
        }
    }

    private var toolRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            key(String(localized: "Adjust"), "gearshape", .adjust)
            key(String(localized: "Search"), "magnifyingglass", .find)
            key(String(localized: "Format"), "aspectratio", .viewmode)
        }
    }

    private var guideRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            key(String(localized: "Guide"), "list.bullet.rectangle", .guide)
            key(String(localized: "List"), "list.bullet", .list)
            key(String(localized: "Sources"), "cable.connector", .source)
        }
    }

    private var smartRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            key("Smart TV", "square.grid.2x2", .online)
            key(String(localized: "Home"), "house.fill", .home)
            key(String(localized: "TV / Exit"), "tv", .watchTV)
        }
    }

    private var colorRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            colorKey(.red, .red, String(localized: "Red"))
            colorKey(.green, .green, String(localized: "Green"))
            colorKey(.yellow, .yellow, String(localized: "Yellow"))
            colorKey(.blue, .blue, String(localized: "Blue"))
        }
    }

    /// D-pad with Info/Options above and Back/Multiview below, as on the remote.
    private var dpadCluster: some View {
        VStack(spacing: Kiel.Space.s2) {
            HStack {
                key("Info", "info.circle", .info).frame(width: 104)
                Spacer()
                key(String(localized: "Options"), "slider.horizontal.3", .options).frame(width: 104)
            }
            DPad { k in
                switch k {
                case .up: press(.cursorUp)
                case .down: press(.cursorDown)
                case .left: press(.cursorLeft)
                case .right: press(.cursorRight)
                case .ok: press(.confirm)
                }
            }
            HStack {
                key(String(localized: "Back"), "arrow.uturn.backward", .back).frame(width: 104)
                Spacer()
                key("Multiview", "rectangle.on.rectangle", .multiview).frame(width: 104)
            }
        }
    }

    private var volumeChannelRow: some View {
        HStack(spacing: Kiel.Space.s4) {
            rocker("Vol", up: .volumeUp, down: .volumeDown, mid: ("speaker.slash", .mute))
            rocker(String(localized: "Channel"), up: .channelUp, down: .channelDown, mid: nil)
        }
    }

    private var sourcesButton: some View {
        Button { showSources = true } label: {
            Label(String(localized: "Source list (HDMI, TV…)"),
                  systemImage: "rectangle.connected.to.line.below")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(KielButtonStyle(kind: .secondary, size: .large, capsule: true))
    }

    private var numberPad: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: Kiel.Space.s3), count: 3)
        return LazyVGrid(columns: cols, spacing: Kiel.Space.s3) {
            ForEach(1...9, id: \.self) { digit($0) }
            Button { press(.subtitle) } label: {
                Image(systemName: "captions.bubble").font(.system(size: 20, weight: .medium))
            }
            .buttonStyle(KielKeyStyle(height: Kiel.Size.key))
            .accessibilityLabel(String(localized: "Subtitles"))
            digit(0)
            Button { press(.dot) } label: {
                Text(".").font(Kiel.Font.h1)
            }
            .buttonStyle(KielKeyStyle(height: Kiel.Size.key))
        }
    }

    // MARK: - Builders

    /// Every key press taps the haptic engine once.
    private func press(_ k: TVKey) {
        taps += 1
        tv.sendKey(k)
    }

    /// Same look as Kiel's RemoteKey, but icon-only keys keep the SF Symbol's spoken name.
    private func key(_ title: String, _ icon: String, _ k: TVKey) -> some View {
        Button { press(k) } label: {
            VStack(spacing: Kiel.Space.s1) {
                Image(systemName: icon).font(.system(size: 20, weight: .medium))
                if !title.isEmpty { Text(title).font(Kiel.Font.caption).lineLimit(1) }
            }
        }
        .buttonStyle(KielKeyStyle(height: title.isEmpty ? 64 : 72))
    }

    private func rocker(_ label: String, up: TVKey, down: TVKey,
                        mid: (String, TVKey)?) -> some View {
        VStack(spacing: Kiel.Space.s2) {
            Button { press(up) } label: { Image(systemName: "plus").font(.system(size: 20, weight: .medium)) }
                .buttonStyle(KielKeyStyle(height: Kiel.Size.key))
            if let mid {
                // Accent marks the active (muted) state.
                Button { press(mid.1) } label: { Image(systemName: mid.0).font(.system(size: 20, weight: .medium)) }
                    .buttonStyle(KielKeyStyle(height: Kiel.Size.key, tint: tv.muted ? Kiel.accentText : Kiel.text))
            } else {
                Text(label).font(Kiel.Font.footnote).foregroundStyle(Kiel.text3).frame(minHeight: Kiel.Size.key)
            }
            Button { press(down) } label: { Image(systemName: "minus").font(.system(size: 20, weight: .medium)) }
                .buttonStyle(KielKeyStyle(height: Kiel.Size.key))
        }
    }

    private func colorKey(_ k: TVKey, _ c: Color, _ name: String) -> some View {
        // The TV's colour keys keep their colour as content, on a neutral key.
        Button { press(k) } label: {
            Capsule().fill(c.opacity(0.8)).frame(width: 32, height: 8)
        }
        .buttonStyle(KielKeyStyle(height: Kiel.Size.controlLG))
        .accessibilityLabel(name)
    }

    private func digit(_ n: Int) -> some View {
        Button { if let k = TVKey.digit(n) { press(k) } } label: {
            Text("\(n)").font(Kiel.Font.title.monospacedDigit())
        }
        .buttonStyle(KielKeyStyle(height: Kiel.Size.key))
    }

    private func bigButton(_ title: String, _ icon: String,
                           action: @escaping () -> Void) -> some View {
        Button { taps += 1; action() } label: {
            Label(title, systemImage: icon).frame(maxWidth: .infinity)
        }
        .buttonStyle(KielButtonStyle(kind: .secondary, size: .large, capsule: true))
    }
}

struct SettingsView: View {
    @EnvironmentObject var tv: TVClient
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(tv.found) { found in
                        Button {
                            tv.host = found.host
                            Task { await tv.refreshVolume() }
                        } label: {
                            HStack(spacing: Kiel.Space.s3) {
                                Image(systemName: "tv").foregroundStyle(Kiel.text2).frame(width: 32)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(found.name).font(Kiel.Font.body.weight(.medium)).foregroundStyle(Kiel.text)
                                    Text(found.host).font(Kiel.Font.caption).foregroundStyle(Kiel.text3)
                                }
                                Spacer()
                                if found.host == tv.host {
                                    Image(systemName: "checkmark").foregroundStyle(Kiel.accentText)
                                        .accessibilityLabel(String(localized: "Selected"))
                                }
                            }
                        }
                    }
                    Button { Task { await tv.scan() } } label: {
                        HStack {
                            Text(tv.scanning ? String(localized: "Searching…") : String(localized: "Search again"))
                            Spacer()
                            if tv.scanning { ProgressView() }
                        }
                    }
                    .foregroundStyle(Kiel.accentText)
                    .disabled(tv.scanning)
                    if tv.online {
                        KielBadge(text: String(localized: "Connected"), tone: .pos)
                    }
                } header: {
                    Text(String(localized: "TVs on your Wi-Fi"))
                } footer: {
                    if tv.found.isEmpty && !tv.scanning {
                        Text(String(localized: "No TV found. The TV must be on and on the same Wi-Fi as this iPhone"))
                            .foregroundStyle(Kiel.text3)
                    }
                }
                .listRowBackground(Kiel.surface)
                .animation(Kiel.Motion.standard, value: tv.found)
                Section {
                    LabeledContent(String(localized: "IP address")) {
                        TextField("192.168.1.50", text: $tv.host)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Button(String(localized: "Test connection")) { Task { await tv.refreshVolume() } }
                        .foregroundStyle(Kiel.accentText)
                    if !tv.online, let e = tv.lastError {
                        Text(e).foregroundStyle(Kiel.neg).font(Kiel.Font.footnote)
                    }
                } header: {
                    Text(String(localized: "Enter the IP yourself"))
                } footer: {
                    Text(String(localized: "On the TV: Home > Setup > Network settings > View network settings shows the IP. The IP can change (DHCP); reserve a fixed IP for the TV in your router"))
                        .foregroundStyle(Kiel.text3)
                }
                .listRowBackground(Kiel.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Kiel.bg.ignoresSafeArea())
            .navigationTitle(String(localized: "Settings"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(String(localized: "Done")) { dismiss() } }
            }
            .task { if tv.found.isEmpty { await tv.scan() } }
        }
    }
}

#Preview {
    ContentView().environmentObject(TVClient())
}
