import SwiftUI

struct HomeView: View {
    @Environment(LearningStore.self) private var store
    @State private var showLearningPlan = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                hero
                quickStats
                dailyGoalCard
                recommendationCard
                quickActions
                examCard
                topicSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Heute")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showLearningPlan = true
                } label: {
                    Image(systemName: "calendar.badge.plus")
                }
                .accessibilityLabel("Lernplan einstellen")

                NavigationLink { SettingsView() } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Einstellungen")
            }
        }
        .sheet(isPresented: $showLearningPlan) {
            LearningPlanSettingsView()
                .environment(store)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Technischer Fachwirt IHK")
                        .font(.largeTitle.bold())
                    Text(heroSubtitle)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }

            if let days = store.daysUntilExam {
                Label(days == 0 ? "Prüfungstag" : "Noch \(days) Tage bis zur Prüfung", systemImage: "calendar.badge.clock")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
    }

    private var heroSubtitle: String {
        if store.goalProgress >= 1 { return "Tagesziel geschafft. Stark – jetzt Wissen festigen." }
        if store.streak >= 3 { return "\(store.streak) Tage in Folge gelernt. Bleib dran." }
        return "Heute zählt jeder Lernblock."
    }

    private var quickStats: some View {
        HStack(spacing: 10) {
            MiniMetric(title: "Streak", value: "\(store.streak)", icon: "flame.fill")
            MiniMetric(title: "Treffer", value: "\(Int(store.accuracy * 100))%", icon: "scope")
            MiniMetric(title: "Fällig", value: "\(store.dueFlashcards.count)", icon: "rectangle.stack.fill")
            MiniMetric(title: "Badges", value: "\(store.unlockedAchievementCount)", icon: "medal.fill")
        }
    }

    private var dailyGoalCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Tagesziel", systemImage: "target")
                        .font(.headline)
                    Spacer()
                    Text("\(store.answeredToday)/\(store.dailyGoal)")
                        .font(.headline.monospacedDigit())
                }

                ProgressView(value: store.goalProgress)
                    .tint(store.goalProgress >= 1 ? .green : .accentColor)

                Text(store.goalProgress >= 1 ? "Tagesziel erreicht – alles Weitere ist Bonus." : "Noch \(max(0, store.dailyGoal - store.answeredToday)) Aufgaben bis zum Tagesziel.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var recommendationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Dein nächster Lernblock")
                        .font(.title3.bold())
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundStyle(.secondary)
                }

                if let weakest = store.weakestTopics.first {
                    HStack(spacing: 12) {
                        SymbolBadge(systemName: weakest.icon)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(weakest.title)
                                .font(.headline)
                            Text("Aktuell dein stärkster Lernhebel")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 8) {
                    recommendationPill("10 Quiz", icon: "checkmark.circle")
                    recommendationPill("\(store.dueFlashcards.count) Karten", icon: "rectangle.stack")
                }
            }
        }
    }

    private func recommendationPill(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellzugriff")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HomeActionCard(title: "Wissensbibliothek", subtitle: "Fragen durchsuchen", icon: "books.vertical.fill") {
                    KnowledgeLibraryView()
                }
                HomeActionCard(title: "Favoriten", subtitle: "\(store.favoriteQuestions.count) gespeichert", icon: "star.fill") {
                    FavoritesView()
                }
                HomeActionCard(title: "Rechentraining", subtitle: "Formeln anwenden", icon: "function") {
                    CalculationView()
                }
                HomeActionCard(title: "Fokus-Timer", subtitle: "25 Minuten", icon: "timer") {
                    FocusTimerView()
                }
                HomeActionCard(title: "7-Tage-Plan", subtitle: "Lernwoche strukturieren", icon: "calendar") {
                    StudyPlanView()
                }
                HomeActionCard(title: "Formelsammlung", subtitle: "Schnell nachschlagen", icon: "sum") {
                    FormulaSheetView()
                }
            }
        }
    }

    @ViewBuilder
    private var examCard: some View {
        if let days = store.daysUntilExam, let date = store.examDate {
            AppCard {
                HStack(spacing: 14) {
                    SymbolBadge(systemName: "calendar.badge.clock")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(days == 0 ? "Heute ist Prüfungstag" : "Noch \(days) Tage")
                            .font(.headline)
                        Text(date.formatted(date: .long, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Ändern") { showLearningPlan = true }
                        .font(.subheadline)
                }
            }
        }
    }

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Prüfungsbereiche")
                .font(.title2.bold())

            ForEach(ExamPart.allCases) { part in
                AppCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(part.rawValue)
                            .font(.headline)

                        ForEach(store.topics.filter { $0.part == part }) { topic in
                            HStack(spacing: 12) {
                                SymbolBadge(systemName: topic.icon)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(topic.title)
                                            .font(.subheadline.weight(.medium))
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
        }
    }
}

private struct MiniMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.headline)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(.quaternary) }
    }
}

private struct HomeActionCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let destination: Destination

    init(title: String, subtitle: String, icon: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                SymbolBadge(systemName: icon)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).stroke(.quaternary) }
        }
        .buttonStyle(.plain)
    }
}

struct LearningPlanSettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var goal = 20
    @State private var hasExamDate = false
    @State private var examDate = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section("Tagesziel") {
                    Stepper("\(goal) Aufgaben pro Tag", value: $goal, in: 5...100, step: 5)
                }

                Section("Prüfungstermin") {
                    Toggle("Prüfungstermin verwenden", isOn: $hasExamDate)
                    if hasExamDate {
                        DatePicker("Datum", selection: $examDate, in: Date.now..., displayedComponents: .date)
                    }
                }

                Section {
                    Text("Der Termin wird lokal für Countdown und Lernplanung verwendet und kann über die Einstellungen zusätzlich in deinen Apple-Kalender übernommen werden.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Lernplan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        store.setDailyGoal(goal)
                        store.setExamDate(hasExamDate ? examDate : nil)
                        dismiss()
                    }
                }
            }
            .onAppear {
                goal = store.dailyGoal
                if let date = store.examDate {
                    hasExamDate = true
                    examDate = date
                }
            }
        }
    }
}
