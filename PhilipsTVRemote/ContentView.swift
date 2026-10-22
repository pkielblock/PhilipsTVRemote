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
                VStack(spacing: 22) {
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
                .padding()
            }
            .background(RemoteBackground())
            .navigationTitle("Philips TV")
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
            Circle().fill(tv.online ? .green : .secondary).frame(width: 10, height: 10)
            Text(tv.host.isEmpty ? L("Set the TV IP in settings", "Defina o IP da TV nos ajustes")
                 : tv.online ? L("Connected", "Conectada") : L("No response", "Sem resposta"))
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            if let v = tv.volume {
                Label("\(v)", systemImage: tv.muted ? "speaker.slash" : "speaker.wave.2")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .glassBackground(in: Capsule())
    }

    private var powerRow: some View {
        HStack(spacing: 16) {
            bigButton(L("Turn on", "Ligar"), "power", tint: .green) { tv.screenOn() }
            bigButton(L("Screen off", "Tela off"), "poweroff", tint: .red) { tv.screenOff() }
        }
    }

    private var transportRows: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                key("", "stop.fill", .stop)
                key("", "pause.fill", .pause)
                key("", "record.circle", .record, tint: .red)
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
        HStack(spacing: 14) {
            colorKey(.red, .red)
            colorKey(.green, .green)
            colorKey(.yellow, .yellow)
            colorKey(.blue, .blue)
        }
    }

    /// D-pad with Info/Options above and Back/Multiview below, as on the remote.
    private var dpadCluster: some View {
        VStack(spacing: 10) {
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
                        Text("OK").font(.title3.bold()).frame(width: 64, height: 64)
                    }
                    .glassButton(prominent: true)
                    .buttonBorderShape(.circle)
                    arrow("chevron.right", .cursorRight)
                }
                arrow("chevron.down", .cursorDown)
            }
            .padding(14)
            .glassBackground(in: Circle())
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
                Text(".").font(.title.bold()).frame(maxWidth: .infinity, minHeight: 48)
            }.glassButton()
        }
    }

    // MARK: - Builders

    /// Every key press taps the haptic engine once.
    private func press(_ k: RemoteKey) {
        taps += 1
        tv.sendKey(k)
    }

    private func key(_ title: String, _ icon: String, _ k: RemoteKey,
                     tint: Color? = nil) -> some View {
        Button { press(k) } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3).foregroundStyle(tint ?? .primary)
                if !title.isEmpty { Text(title).font(.caption2).lineLimit(1) }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
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
                    Image(systemName: mid.0).frame(maxWidth: .infinity, minHeight: 36)
                }.glassButton()
            } else {
                Text(label).font(.caption).foregroundStyle(.secondary).frame(minHeight: 36)
            }
            Button { press(down) } label: {
                Image(systemName: "minus").frame(maxWidth: .infinity, minHeight: 44)
            }.glassButton()
        }
    }

    private func colorKey(_ k: RemoteKey, _ c: Color) -> some View {
        Button { press(k) } label: {
            Color.clear.frame(maxWidth: .infinity, minHeight: 28)
        }
        .glassButton(prominent: true, tint: c)
    }

    private func digit(_ n: Int) -> some View {
        Button { if let k = RemoteKey.digit(n) { press(k) } } label: {
            Text("\(n)").font(.title2).frame(maxWidth: .infinity, minHeight: 48)
        }.glassButton()
    }

    private func bigButton(_ title: String, _ icon: String, tint: Color,
                           action: @escaping () -> Void) -> some View {
        Button { taps += 1; action() } label: {
            Label(title, systemImage: icon).font(.headline)
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .glassButton(prominent: true, tint: tint)
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
                            .foregroundStyle(.green).font(.caption)
                    } else if let e = tv.lastError {
                        Text(e).foregroundStyle(.red).font(.caption)
                    }
                } header: {
                    Text("TV")
                } footer: {
                    Text(L("On the TV: Home > Setup > Network settings > View network settings shows the IP. "
                           + "The IP can change (DHCP); reserve a fixed IP for the TV in your router.",
                           "Na TV: Início > Configuração > Configurações de rede > Visualizar configurações de rede mostra o IP. "
                           + "O IP pode mudar (DHCP); reserve um IP fixo para a TV no roteador."))
                }
                Section(L("Language", "Idioma")) {
                    Picker(L("Language", "Idioma"), selection: $lang) {
                        ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(L("Settings", "Ajustes"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
            }
        }
    }
}

/// Soft gradient so the glass has something to refract.
struct RemoteBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.05, green: 0.07, blue: 0.16), Color(red: 0.12, green: 0.04, blue: 0.18)]
                : [Color(red: 0.86, green: 0.91, blue: 1.0), Color(red: 0.96, green: 0.89, blue: 0.98)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        .ignoresSafeArea()
    }
}

extension View {
    /// Liquid Glass button on iOS 26+, bordered style before that.
    @ViewBuilder
    func glassButton(prominent: Bool = false, tint: Color? = nil) -> some View {
        if #available(iOS 26, *) {
            if prominent { buttonStyle(.glassProminent).tint(tint) } else { buttonStyle(.glass).tint(tint) }
        } else {
            if prominent { buttonStyle(.borderedProminent).tint(tint) } else { buttonStyle(.bordered).tint(tint) }
        }
    }

    /// Liquid Glass surface on iOS 26+, thin material before that.
    @ViewBuilder
    func glassBackground<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}

#Preview {
    ContentView().environmentObject(TVClient())
}
