import WidgetKit
import SwiftUI
import NolaggyDomain
import NolaggyDesign
import NolaggyInfrastructure

/// Linha do tempo dos Widgets LagCheck.
/// Segue a diretriz "Zero Mock / Nunca uma Nota Inventada" (Decisão 75).
/// Lê dados reais via App Group; se não houver dados válidos e frescos (< 4h), apresenta estado semântico neutro.
struct LagCheckTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LagCheckWidgetEntry {
        LagCheckWidgetEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LagCheckWidgetEntry) -> Void) {
        let store = SharedAppGroupStore.shared
        let snapshot = store.loadLatestSnapshot()
        let entry = LagCheckWidgetEntry(date: Date(), snapshot: snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LagCheckWidgetEntry>) -> Void) {
        let store = SharedAppGroupStore.shared
        let snapshot = store.loadLatestSnapshot()
        let entry = LagCheckWidgetEntry(date: Date(), snapshot: snapshot)

        // Atualiza a cada 30 minutos ou sob demanda via reloadTimelines
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

/// Entrada de dados da timeline contendo snapshot real opcional.
struct LagCheckWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetTelemetrySnapshot?

    var isValidAndFresh: Bool {
        guard let snapshot = snapshot else { return false }
        return snapshot.isFresh(referenceDate: date)
    }
}

/// Visualização principal do widget adaptável aos tamanhos de Lock Screen e Home.
struct LagCheckWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: LagCheckWidgetEntry

    var body: some View {
        Group {
            if entry.isValidAndFresh, let snapshot = entry.snapshot {
                validSnapshotView(snapshot: snapshot)
            } else {
                neutralEmptyView
            }
        }
        .widgetURL(URL(string: "lagcheck://quicktest"))
        .containerBackground(NLColor.deep, for: .widget)
    }


    // MARK: - Estado Válido e Real

    @ViewBuilder
    private func validSnapshotView(snapshot: WidgetTelemetrySnapshot) -> some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 1) {
                VerdictIndicatorBadge(verdict: snapshot.verdict, size: 8)
                Text(verbatim: "\(Int(snapshot.rttMedianMs))")
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundStyle(NLColor.textPrimary)
                Text("MS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(NLColor.textTertiary)
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    VerdictIndicatorBadge(verdict: snapshot.verdict, size: 8)
                    Text(snapshot.gameName.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)
                }
                Text(verbatim: "\(Int(snapshot.rttMedianMs)) ms · \(snapshot.regionLabel)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(NLColor.textSecondary)
                Text(snapshot.verdict.defaultHeadline)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(colorForVerdict(snapshot.verdict))
            }

        case .accessoryInline:
            Text(verbatim: "\(snapshot.gameName): \(Int(snapshot.rttMedianMs))ms ● \(snapshot.verdict.defaultHeadline)")

        case .systemSmall:
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                // Header: Jogo e Região
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(snapshot.gameName.uppercased())
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(NLColor.textPrimary)
                            .lineLimit(1)
                        Text(snapshot.regionLabel)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(NLColor.textTertiary)
                    }
                    Spacer()
                    VerdictIndicatorBadge(verdict: snapshot.verdict, size: 10)
                }

                Spacer()

                // Hero RTT Monoespaçado
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(verbatim: "\(Int(snapshot.rttMedianMs))")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(NLColor.textPrimary)
                    Text("ms")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(NLColor.textTertiary)
                }

                // Veredito e Jitter
                HStack {
                    Text(snapshot.verdict.defaultHeadline)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(colorForVerdict(snapshot.verdict))
                        .lineLimit(1)
                    Spacer()
                    if let grade = snapshot.bufferbloatGrade {
                        Text(verbatim: grade)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(NLColor.textSecondary)
                    }
                }
            }
            .padding(NLSpacing.sm)

        default:
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.gameName)
                    .font(NLTypography.caption)
                Text(verbatim: "\(Int(snapshot.rttMedianMs)) ms")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
            }
            .padding()
        }
    }

    // MARK: - Estado Neutro / Sem Mock ("Nunca uma Nota Inventada")

    @ViewBuilder
    private var neutralEmptyView: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 2) {
                Image(systemName: "bolt.horizontal.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(NLColor.textSecondary)
                Text("CHECK")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(NLColor.textTertiary)
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("LAGCHECK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(NLColor.textSecondary)
                Text("SEM CHECK RECENTE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)
                Text("Toque para medir rota")
                    .font(.system(size: 9))
                    .foregroundStyle(NLColor.textTertiary)
            }

        case .accessoryInline:
            Text("LagCheck: Sem check recente · Toque para medir")

        case .systemSmall:
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                HStack {
                    Text("LAGCHECK")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(NLColor.textSecondary)
                    Spacer()
                    Circle()
                        .fill(NLColor.textTertiary)
                        .frame(width: 8, height: 8)
                }

                Spacer()

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 24))
                    .foregroundStyle(NLColor.gamerPurpleLight)

                Text("SEM CHECK RECENTE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)

                Text("Toque para medir sua conexão")
                    .font(.system(size: 10))
                    .foregroundStyle(NLColor.textTertiary)
                    .lineLimit(1)
            }
            .padding(NLSpacing.sm)

        default:
            VStack(alignment: .leading, spacing: 4) {
                Text("LAGCHECK")
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textSecondary)
                Text("Sem check recente. Abra o app para medir.")
                    .font(NLTypography.body)
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding()
        }
    }

    private func colorForVerdict(_ verdict: GameReadinessVerdict) -> Color {
        switch verdict {
        case .ready: return NLColor.semanticReady
        case .caution: return NLColor.semanticCaution
        case .notReady: return NLColor.coralSolar
        case .inconclusive: return NLColor.textSecondary
        }
    }
}

/// Definição do Widget principal LagCheck.
@main
struct LagCheckWidget: Widget {
    let kind: String = "LagCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LagCheckTimelineProvider()) { entry in
            LagCheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Status de Rota LagCheck")
        .description("Acompanhe o status e a latência da sua rota antes de abrir o jogo.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall
        ])
    }
}
