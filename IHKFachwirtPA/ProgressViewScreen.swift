import SwiftUI

struct ProgressViewScreen: View {
    @Environment(LearningStore.self) private var store
    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                summaryGrid
                achievementSection
                topicProgressSection
                focusCard
                recentSessions
                resetButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Fortschritt")
        .confirmationDialog("Fortschritt wirklich zurücksetzen?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) { store.resetProgress() }
            Button("Abbrechen", role: .cancel) { }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Beantwortet", value: "\(store.totalAnswered)", icon: "questionmark.circle.fill")
            StatCard(title: "Trefferquote", value: "\(Int(store.accuracy * 100))%", icon: "scope")
            StatCard(title: "Streak", value: "\(store.streak) Tage", icon: "flame.fill")
            StatCard(title: "Heute", value: "\(store.answeredToday)/\(store.dailyGoal)", icon: "calendar")
        }
    }

    private var achievementSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Erfolge", systemImage: "medal.fill")
                        .font(.title3.bold())
                    Spacer()
                    Text("\(store.unlockedAchievementCount)/\(store.achievements.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(store.achievements) { badge in
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: badge.unlocked ? badge.icon : "lock.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.hierarchical)
                                Text(badge.title)
                                    .font(.subheadline.bold())
                                Text(badge.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(width: 150, alignment: .leading)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .opacity(badge.unlocked ? 1 : 0.55)
                            .accessibilityElement(children: .combine)
                            .accessibilityValue(badge.unlocked ? "Freigeschaltet" : "Gesperrt")
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var topicProgressSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Lernstand nach Themen")
                    .font(.title3.bold())
                ForEach(store.topics) { topic in
                    HStack(spacing: 12) {
                        SymbolBadge(systemName: topic.icon)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(topic.title)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(store.progress(for: topic.id) * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: store.progress(for: topic.id))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var focusCard: some View {
        if let focus = store.weakestTopics.first {
            AppCard {
                HStack(spacing: 12) {
                    SymbolBadge(systemName: "scope")
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Nächster Fokus")
                            .font(.headline)
                        Text(focus.title)
                            .font(.subheadline.weight(.semibold))
                        Text("Dieser Bereich hat aktuell den niedrigsten kombinierten Lernwert.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentSessions: some View {
        if !store.sessions.isEmpty {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Letzte Lernblöcke")
                        .font(.title3.bold())
                    ForEach(store.sessions.suffix(5).reversed()) { session in
                        HStack {
                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            Text("\(session.correct)/\(session.answered)")
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }

    private var resetButton: some View {
        Button("Lernfortschritt zurücksetzen", role: .destructive) {
            showResetConfirmation = true
        }
        .font(.footnote)
        .padding(.top, 8)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SymbolBadge(systemName: icon)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.quaternary) }
    }
}
