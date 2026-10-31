import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tv: TVClient
    @AppStorage(AppLanguage.storageKey) private var lang = AppLanguage.english.rawValue
    @State private var showSettings = false
    @State private var showSources = false
    @State private var taps = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Philips TV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: taps)
            .sensoryFeedback(.error, trigger: tv.online) { wasOnline, isOnline in wasOnline && !isOnline }
            .sheet(isPresented: $showSettings) { SettingsView().environmentObject(tv) }
            .sheet(isPresented: $showSources) { SourceView().environmentObject(tv) }
            .task {
                if tv.host.isEmpty { showSettings = true }
                await tv.refreshVolume()
            }
        }
    }

    // MARK: - Sections

    private var statusBar: some View {
        HStack {
            Circle().fill(tv.online ? Color.accentColor : .secondary).frame(width: 8, height: 8)
            Text(tv.host.isEmpty ? L("Set the TV IP in settings", "Defina o IP da TV nos ajustes")
                 : tv.online ? L("Connected", "Conectada") : L("No response", "Sem resposta"))
                .font(.caption).foregroundStyle(.secondary)
                .contentTransition(.opacity)
            Spacer()
            if let v = tv.volume {
                Label("\(v)", systemImage: tv.muted ? "speaker.slash" : "speaker.wave.2")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(v)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: tv.online)
        .animation(.snappy, value: tv.volume)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white.opacity(0.04), in: Capsule())
    }

    private var powerRow: some View {
        HStack(spacing: 16) {
            bigButton(L("Turn on", "Ligar"), "power") { tv.screenOn() }
            bigButton(L("Screen off", "Tela off"), "poweroff") { tv.screenOff() }
        }
    }

    private var transportRows: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                key("", "stop.fill", .stop)
                key("", "pause.fill", .pause)
                key("", "record.circle", .record)
            }
            HStack(spacing: 12) {
                key("", "backward.fill", .rewind)
                key("", "play.fill", .play)
                key("", "forward.fill", .fastForward)
            }
        }
    }

    private var toolRow: some View {
        HStack(spacing: 12) {
            key(L("Adjust", "Ajustar"), "gearshape", .adjust)
            key(L("Search", "Buscar"), "magnifyingglass", .find)
            key(L("Format", "Formato"), "aspectratio", .viewmode)
        }
    }

    private var guideRow: some View {
        HStack(spacing: 12) {
            key(L("Guide", "Guia"), "list.bullet.rectangle", .guide)
            key(L("List", "Lista"), "list.bullet", .list)
            key(L("Sources", "Fontes"), "cable.connector", .source)
        }
    }

    private var smartRow: some View {
        HStack(spacing: 12) {
            key("Smart TV", "square.grid.2x2", .online)
            key(L("Home", "Início"), "house.fill", .home)
            key(L("TV / Exit", "TV / Sair"), "tv", .watchTV)
        }
    }

    private var colorRow: some View {
        HStack(spacing: 12) {
            colorKey(.red, .red)
            colorKey(.green, .green)
            colorKey(.yellow, .yellow)
            colorKey(.blue, .blue)
        }
    }

    /// D-pad with Info/Options above and Back/Multiview below, as on the remote.
    private var dpadCluster: some View {
        VStack(spacing: 8) {
            HStack {
                key("Info", "info.circle", .info).frame(width: 104)
                Spacer()
                key(L("Options", "Opções"), "slider.horizontal.3", .options).frame(width: 104)
            }
            VStack(spacing: 4) {
                arrow("chevron.up", .cursorUp)
                HStack(spacing: 4) {
                    arrow("chevron.left", .cursorLeft)
                    Button { press(.confirm) } label: {
                        Text("OK").font(.title3.weight(.semibold)).frame(width: 64, height: 64)
                    }
                    .glassButton()
                    .buttonBorderShape(.circle)
                    arrow("chevron.right", .cursorRight)
                }
                arrow("chevron.down", .cursorDown)
            }
            .padding(16)
            .background(.white.opacity(0.04), in: Circle())
            HStack {
                key(L("Back", "Voltar"), "arrow.uturn.backward", .back).frame(width: 104)
                Spacer()
                key("Multiview", "rectangle.on.rectangle", .multiview).frame(width: 104)
            }
        }
    }

    private var volumeChannelRow: some View {
        HStack(spacing: 16) {
            rocker("Vol", up: .volumeUp, down: .volumeDown, mid: ("speaker.slash", .mute))
            rocker(L("Channel", "Canal"), up: .channelUp, down: .channelDown, mid: nil)
        }
    }

    private var sourcesButton: some View {
        Button { showSources = true } label: {
            Label(L("Source list (HDMI, TV…)", "Lista de fontes (HDMI, TV…)"),
                  systemImage: "rectangle.connected.to.line.below")
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .glassButton()
    }

    private var numberPad: some View {
        let cols = Array(repeating: GridItem(.flexible()), count: 3)
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(1...9, id: \.self) { digit($0) }
            Button { press(.subtitle) } label: {
                Image(systemName: "captions.bubble").frame(maxWidth: .infinity, minHeight: 48)
            }.glassButton()
            digit(0)
            Button { press(.dot) } label: {
                Text(".").font(.title.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 48)
            }.glassButton()
        }
    }

    // MARK: - Builders

    /// Every key press taps the haptic engine once.
    private func press(_ k: RemoteKey) {
        taps += 1
        tv.sendKey(k)
    }

    private func key(_ title: String, _ icon: String, _ k: RemoteKey) -> some View {
        Button { press(k) } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                if !title.isEmpty { Text(title).font(.caption2).lineLimit(1) }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .glassButton()
    }

    private func arrow(_ icon: String, _ k: RemoteKey) -> some View {
        Button { press(k) } label: {
            Image(systemName: icon).font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 64, height: 64)
                .contentShape(Rectangle())
        }
    }

    private func rocker(_ label: String, up: RemoteKey, down: RemoteKey,
                        mid: (String, RemoteKey)?) -> some View {
        VStack(spacing: 8) {
            Button { press(up) } label: {
                Image(systemName: "plus").frame(maxWidth: .infinity, minHeight: 44)
            }.glassButton()
            if let mid {
                Button { press(mid.1) } label: {
                    // Accent marks the active (muted) state.
                    Image(systemName: mid.0).foregroundStyle(tv.muted ? Color.accentColor : .primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.glassButton()
            } else {
                Text(label).font(.caption).foregroundStyle(.secondary).frame(minHeight: 44)
            }
            Button { press(down) } label: {
                Image(systemName: "minus").frame(maxWidth: .infinity, minHeight: 44)
            }.glassButton()
        }
    }

    private func colorKey(_ k: RemoteKey, _ c: Color) -> some View {
        // The TV's colour keys keep their colour as content, on a neutral key.
        Button { press(k) } label: {
            Capsule().fill(c.opacity(0.8)).frame(width: 32, height: 8)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .glassButton()
    }

    private func digit(_ n: Int) -> some View {
        Button { if let k = RemoteKey.digit(n) { press(k) } } label: {
            Text("\(n)").font(.title3.monospacedDigit()).frame(maxWidth: .infinity, minHeight: 48)
        }.glassButton()
    }

    private func bigButton(_ title: String, _ icon: String,
                           action: @escaping () -> Void) -> some View {
        Button { taps += 1; action() } label: {
            Label(title, systemImage: icon).font(.body.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .glassButton()
    }
}

struct SettingsView: View {
    @EnvironmentObject var tv: TVClient
    @Environment(\.dismiss) var dismiss
    @AppStorage(AppLanguage.storageKey) private var lang = AppLanguage.english.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent(L("IP address", "Endereço IP")) {
                        TextField("192.168.1.50", text: $tv.host)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Button(L("Test connection", "Testar conexão")) { Task { await tv.refreshVolume() } }
                    if tv.online {
                        Label(L("Connected", "Conectada"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor).font(.caption)
                    } else if let e = tv.lastError {
                        Text(e).foregroundStyle(Color(red: 240 / 255, green: 92 / 255, blue: 92 / 255)).font(.caption)
                    }
                } header: {
                    Text("TV")
                } footer: {
                    Text(L("On the TV: Home > Setup > Network settings > View network settings shows the IP. "
                           + "The IP can change (DHCP); reserve a fixed IP for the TV in your router",
                           "Na TV: Início > Configuração > Configurações de rede > Visualizar configurações de rede mostra o IP. "
                           + "O IP pode mudar (DHCP); reserve um IP fixo para a TV no roteador"))
                }
                .listRowBackground(Color.white.opacity(0.04))
                Section(L("Language", "Idioma")) {
                    Picker(L("Language", "Idioma"), selection: $lang) {
                        ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.white.opacity(0.04))
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(L("Settings", "Ajustes"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
            }
        }
    }
}

extension View {
    /// Liquid Glass button on iOS 26+, bordered style before that.
    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26, *) { buttonStyle(.glass) } else { buttonStyle(.bordered) }
    }
}

#Preview {
    ContentView().environmentObject(TVClient())
}
