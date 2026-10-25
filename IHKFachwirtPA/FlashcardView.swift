import SwiftUI

struct FlashcardView: View {
    @Environment(LearningStore.self) private var store
    @State private var selectedTopicID: String?
    @State private var index = 0
    @State private var showAnswer = false
    @State private var dueOnly = true

    private var cards: [Flashcard] {
        var result = dueOnly ? store.dueFlashcards : store.flashcards
        if let selectedTopicID {
            result = result.filter { $0.topicID == selectedTopicID }
        }
        return result
    }

    private var card: Flashcard? {
        guard !cards.isEmpty else { return nil }
        return cards[index % cards.count]
    }

    var body: some View {
        VStack(spacing: 18) {
            filters

            if let card {
                cardHeader(card)
                flashcard(card)

                if showAnswer {
                    ratingButtons(card)
                }
            } else {
                ContentUnavailableView(
                    "Keine Karten fällig",
                    systemImage: "checkmark.circle",
                    description: Text(dueOnly ? "Für diesen Filter sind gerade keine Wiederholungen fällig." : "Keine Karten in diesem Themenbereich gefunden.")
                )
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Karteikarten")
        .onChange(of: selectedTopicID) { _, _ in resetPosition() }
        .onChange(of: dueOnly) { _, _ in resetPosition() }
    }

    private var filters: some View {
        VStack(spacing: 10) {
            Picker("Thema", selection: $selectedTopicID) {
                Text("Alle Themen").tag(Optional<String>.none)
                ForEach(store.topics) { topic in
                    Text(topic.title).tag(Optional(topic.id))
                }
            }
            .pickerStyle(.menu)

            Toggle("Nur fällige Karten", isOn: $dueOnly)
                .font(.subheadline)
        }
    }

    private func cardHeader(_ card: Flashcard) -> some View {
        HStack {
            Text(store.topic(for: card.topicID)?.title ?? "Thema")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text("Stufe \(card.mastery)/5")
                .font(.subheadline.monospacedDigit())
        }
    }

    private func flashcard(_ card: Flashcard) -> some View {
        Button {
            withAnimation(.snappy) { showAnswer.toggle() }
        } label: {
            VStack(spacing: 20) {
                Image(systemName: showAnswer ? "lightbulb.fill" : "questionmark.circle.fill")
                    .font(.largeTitle)
                Text(showAnswer ? "Antwort" : "Frage")
                    .font(.caption.bold())
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(showAnswer ? card.answer : card.question)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                Text("Tippen zum Umdrehen")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 360)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28))
        }
        .buttonStyle(.plain)
    }

    private func ratingButtons(_ card: Flashcard) -> some View {
        HStack(spacing: 12) {
            Button {
                rate(false, card: card)
            } label: {
                Label("Nochmal", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                rate(true, card: card)
            } label: {
                Label("Gewusst", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func rate(_ knewIt: Bool, card: Flashcard) {
        store.updateMastery(cardID: card.id, knewIt: knewIt)
        index += 1
        showAnswer = false
    }

    private func resetPosition() {
        index = 0
        showAnswer = false
    }
}
