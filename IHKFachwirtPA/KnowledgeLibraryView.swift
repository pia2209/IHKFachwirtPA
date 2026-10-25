import SwiftUI

struct KnowledgeLibraryView: View {
    @Environment(LearningStore.self) private var store
    @State private var query = ""
    @State private var selectedPart: ExamPart?

    private var filteredQuestions: [QuizQuestion] {
        store.quizQuestions.filter { question in
            let topic = store.topic(for: question.topicID)
            let matchesPart = selectedPart == nil || topic?.part == selectedPart
            let text = [question.question, question.explanation, topic?.title ?? ""].joined(separator: " ")
            let matchesQuery = query.isEmpty || text.localizedCaseInsensitiveContains(query)
            return matchesPart && matchesQuery
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Prüfungsbereich", selection: $selectedPart) {
                    Text("Alle").tag(Optional<ExamPart>.none)
                    ForEach(ExamPart.allCases) { part in
                        Text(part.shortTitle).tag(Optional(part))
                    }
                }
                .pickerStyle(.segmented)
            }

            if filteredQuestions.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(filteredQuestions) { question in
                    NavigationLink {
                        KnowledgeDetailView(question: question)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            SymbolBadge(systemName: store.topic(for: question.topicID)?.icon ?? "book.closed")
                            VStack(alignment: .leading, spacing: 5) {
                                Text(question.question)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(3)
                                Text(store.topic(for: question.topicID)?.title ?? "Thema")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 4)
                            if store.isFavorite(question.id) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .accessibilityLabel("Favorit")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Fragen, Begriffe und Themen")
        .navigationTitle("Wissensbibliothek")
    }
}

private struct KnowledgeDetailView: View {
    @Environment(LearningStore.self) private var store
    let question: QuizQuestion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label(store.topic(for: question.topicID)?.title ?? "Thema", systemImage: store.topic(for: question.topicID)?.icon ?? "book.closed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(question.question)
                    .font(.title2.bold())

                AppCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Richtige Antwort")
                            .font(.headline)
                        Text(question.answers[question.correctIndex])
                        Divider()
                        Text(question.explanation)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    store.toggleFavorite(question.id)
                } label: {
                    Label(
                        store.isFavorite(question.id) ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen",
                        systemImage: store.isFavorite(question.id) ? "star.slash" : "star"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Lernwissen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FavoritesView: View {
    @Environment(LearningStore.self) private var store

    var body: some View {
        List {
            if store.favoriteQuestions.isEmpty {
                ContentUnavailableView(
                    "Noch keine Favoriten",
                    systemImage: "star",
                    description: Text("Markiere wichtige Fragen in der Wissensbibliothek oder während eines Quiz.")
                )
            } else {
                ForEach(store.favoriteQuestions) { question in
                    NavigationLink {
                        FavoriteQuestionDetail(question: question)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(question.question)
                                .font(.subheadline.weight(.medium))
                            Text(store.topic(for: question.topicID)?.title ?? "Thema")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favoriten")
    }
}

private struct FavoriteQuestionDetail: View {
    @Environment(LearningStore.self) private var store
    let question: QuizQuestion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(question.question)
                    .font(.title2.bold())
                AppCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.answers[question.correctIndex])
                            .font(.headline)
                        Text(question.explanation)
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Favorit entfernen", role: .destructive) {
                    store.toggleFavorite(question.id)
                }
            }
            .padding()
        }
        .navigationTitle("Favorit")
        .navigationBarTitleDisplayMode(.inline)
    }
}
