import SwiftUI

struct StudyPlanView: View {
    @Environment(LearningStore.self) private var store

    var body: some View {
        List {
            Section("Heute") {
                planRow("Fällige Karteikarten", detail: "\(store.dueFlashcards.count) Karten", icon: "rectangle.stack")
                planRow("Quizblock", detail: "10 Fragen", icon: "checkmark.circle")
                if let weak = store.weakestTopics.first {
                    planRow("Schwerpunkt", detail: weak.title, icon: "scope")
                }
            }

            Section("7-Tage-Rhythmus") {
                day("Montag", "Wirtschaft + Rechnungswesen")
                day("Dienstag", "Technische Grundlagen")
                day("Mittwoch", "Recht + Unternehmensführung")
                day("Donnerstag", "Fertigung + Produktion")
                day("Freitag", "Logistik + Qualitätsmanagement")
                day("Samstag", "Führung + gemischtes Fehlertraining")
                day("Sonntag", "Prüfungssimulation + Auswertung")
            }

            Section("Prüfungsstrategie") {
                Text("Arbeite zuerst deine schwächsten Themen ab. Wiederhole Fehlerfragen, bis sie aus der Fehlerliste verschwinden. Nutze sonntags die Simulation, um Zeitdruck und Themenwechsel zu trainieren.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Lernplan")
    }

    private func planRow(_ title: String, detail: String, icon: String) -> some View {
        Label { VStack(alignment: .leading) { Text(title); Text(detail).font(.caption).foregroundStyle(.secondary) } } icon: { Image(systemName: icon) }
    }

    private func day(_ name: String, _ focus: String) -> some View {
        HStack { Text(name).fontWeight(.semibold).frame(width: 82, alignment: .leading); Text(focus).foregroundStyle(.secondary) }
    }
}
