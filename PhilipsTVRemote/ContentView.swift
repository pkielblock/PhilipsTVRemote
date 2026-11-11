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
                        .accessibilityLabel(L("Settings", "Ajustes"))
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

    /// Kiel's RemoteStatusBar layout, kept local because volume can be unknown and mute changes the icon.
    private var statusBar: some View {
        HStack(spacing: Kiel.Space.s3) {
            StatusDot(color: tv.online ? Kiel.pos : Kiel.text3, live: tv.online)
            Text(tv.scanning ? L("Searching for your TV…", "Procurando sua TV…")
                 : tv.host.isEmpty ? L("No TV found. Open settings", "Nenhuma TV encontrada. Abra os ajustes")
                 : tv.online ? L("Connected", "Conectada") : L("No response", "Sem resposta"))
                .font(Kiel.Font.footnote).foregroundStyle(Kiel.text2)
                .contentTransition(.opacity)
            Spacer()
            if let v = tv.volume {
                Image(systemName: tv.muted ? "speaker.slash" : "speaker.wave.2").foregroundStyle(Kiel.text3)
                Text("\(v)").font(Kiel.Font.footnote.weight(.semibold)).monospacedDigit()
                    .foregroundStyle(Kiel.text)
                    .contentTransition(.numericText(value: Double(v)))
            }
        }
        .animation(Kiel.Motion.standard, value: tv.online)
        .animation(Kiel.Motion.standard, value: tv.volume)
        .padding(.horizontal, Kiel.Space.s4)
        .frame(height: Kiel.Size.controlLG)
        .background(Kiel.surface, in: Capsule())
        .overlay(Capsule().stroke(Kiel.line, lineWidth: 1))
    }

    private var powerRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            bigButton(L("Turn on", "Ligar"), "power") { tv.screenOn() }
            bigButton(L("Screen off", "Tela off"), "poweroff") { tv.screenOff() }
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
            key(L("Adjust", "Ajustar"), "gearshape", .adjust)
            key(L("Search", "Buscar"), "magnifyingglass", .find)
            key(L("Format", "Formato"), "aspectratio", .viewmode)
        }
    }

    private var guideRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            key(L("Guide", "Guia"), "list.bullet.rectangle", .guide)
            key(L("List", "Lista"), "list.bullet", .list)
            key(L("Sources", "Fontes"), "cable.connector", .source)
        }
    }

    private var smartRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            key("Smart TV", "square.grid.2x2", .online)
            key(L("Home", "Início"), "house.fill", .home)
            key(L("TV / Exit", "TV / Sair"), "tv", .watchTV)
        }
    }

    private var colorRow: some View {
        HStack(spacing: Kiel.Space.s3) {
            colorKey(.red, .red, L("Red", "Vermelho"))
            colorKey(.green, .green, L("Green", "Verde"))
            colorKey(.yellow, .yellow, L("Yellow", "Amarelo"))
            colorKey(.blue, .blue, L("Blue", "Azul"))
        }
    }

    /// D-pad with Info/Options above and Back/Multiview below, as on the remote.
    private var dpadCluster: some View {
        VStack(spacing: Kiel.Space.s2) {
            HStack {
                key("Info", "info.circle", .info).frame(width: 104)
                Spacer()
                key(L("Options", "Opções"), "slider.horizontal.3", .options).frame(width: 104)
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
                key(L("Back", "Voltar"), "arrow.uturn.backward", .back).frame(width: 104)
                Spacer()
                key("Multiview", "rectangle.on.rectangle", .multiview).frame(width: 104)
            }
        }
    }

    private var volumeChannelRow: some View {
        HStack(spacing: Kiel.Space.s4) {
            rocker("Vol", up: .volumeUp, down: .volumeDown, mid: ("speaker.slash", .mute))
            rocker(L("Channel", "Canal"), up: .channelUp, down: .channelDown, mid: nil)
        }
    }

    private var sourcesButton: some View {
        Button { showSources = true } label: {
            Label(L("Source list (HDMI, TV…)", "Lista de fontes (HDMI, TV…)"),
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
            .accessibilityLabel(L("Subtitles", "Legendas"))
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
    @AppStorage(AppLanguage.storageKey) private var lang = AppLanguage.english.rawValue

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
                                        .accessibilityLabel(L("Selected", "Selecionada"))
                                }
                            }
                        }
                    }
                    Button { Task { await tv.scan() } } label: {
                        HStack {
                            Text(tv.scanning ? L("Searching…", "Procurando…") : L("Search again", "Procurar de novo"))
                            Spacer()
                            if tv.scanning { ProgressView() }
                        }
                    }
                    .foregroundStyle(Kiel.accentText)
                    .disabled(tv.scanning)
                    if tv.online {
                        KielBadge(text: L("Connected", "Conectada"), tone: .pos)
                    }
                } header: {
                    Text(L("TVs on your Wi-Fi", "TVs no seu Wi-Fi"))
                } footer: {
                    if tv.found.isEmpty && !tv.scanning {
                        Text(L("No TV found. The TV must be on and on the same Wi-Fi as this iPhone",
                               "Nenhuma TV encontrada. A TV precisa estar ligada e no mesmo Wi-Fi que este iPhone"))
                            .foregroundStyle(Kiel.text3)
                    }
                }
                .listRowBackground(Kiel.surface)
                .animation(Kiel.Motion.standard, value: tv.found)
                Section {
                    LabeledContent(L("IP address", "Endereço IP")) {
                        TextField("192.168.1.50", text: $tv.host)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Button(L("Test connection", "Testar conexão")) { Task { await tv.refreshVolume() } }
                        .foregroundStyle(Kiel.accentText)
                    if !tv.online, let e = tv.lastError {
                        Text(e).foregroundStyle(Kiel.neg).font(Kiel.Font.footnote)
                    }
                } header: {
                    Text(L("Enter the IP yourself", "Digitar o IP"))
                } footer: {
                    Text(L("On the TV: Home > Setup > Network settings > View network settings shows the IP. "
                           + "The IP can change (DHCP); reserve a fixed IP for the TV in your router",
                           "Na TV: Início > Configuração > Configurações de rede > Visualizar configurações de rede mostra o IP. "
                           + "O IP pode mudar (DHCP); reserve um IP fixo para a TV no roteador"))
                        .foregroundStyle(Kiel.text3)
                }
                .listRowBackground(Kiel.surface)
                Section(L("Language", "Idioma")) {
                    Picker(L("Language", "Idioma"), selection: $lang) {
                        ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Kiel.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Kiel.bg.ignoresSafeArea())
            .navigationTitle(L("Settings", "Ajustes"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(L("Done", "Concluído")) { dismiss() } }
            }
            .task { if tv.found.isEmpty { await tv.scan() } }
        }
    }
}

#Preview {
    ContentView().environmentObject(TVClient())
}
