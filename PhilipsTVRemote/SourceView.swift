import SwiftUI

struct SourceView: View {
    @EnvironmentObject var tv: TVClient
    @Environment(\.dismiss) var dismiss
    @AppStorage(AppLanguage.storageKey) private var lang = AppLanguage.english.rawValue

    var body: some View {
        NavigationStack {
            Group {
                if tv.sources.isEmpty {
                    ContentUnavailableView(L("No sources", "Sem fontes"),
                        systemImage: "tv.slash",
                        description: Text(L("The TV didn't respond. It must be on and on the same network.",
                                             "A TV não respondeu. Ela precisa estar ligada e na mesma rede.")))
                } else {
                    List(tv.sources) { src in
                        Button {
                            tv.setSource(src.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: icon(for: src.id))
                                    .frame(width: 28)
                                Text(src.name)
                                Spacer()
                                Text(src.id).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("Sources", "Fontes"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Close", "Fechar")) { dismiss() }
                }
            }
            .task { await tv.fetchSources() }
            .refreshable { await tv.fetchSources() }
        }
    }

    private func icon(for id: String) -> String {
        switch id {
        case let s where s.hasPrefix("hdmi"): return "cable.connector"
        case "tv": return "antenna.radiowaves.left.and.right"
        case "satellite": return "dot.radiowaves.up.forward"
        case "vga": return "display"
        case "ypbpr", "ext1", "ext2": return "cable.connector.horizontal"
        default: return "rectangle.connected.to.line.below"
        }
    }
}

#Preview {
    SourceView().environmentObject(TVClient())
}
