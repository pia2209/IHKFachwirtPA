import SwiftUI

struct FormulaSheetView: View {
    private struct Formula: Identifiable {
        let id: String
        let title: String
        let expression: String
        let detail: String
    }

    private let formulas: [Formula] = [
        .init(id: "db", title: "Stückdeckungsbeitrag", expression: "db = Preis − variable Kosten", detail: "Der Deckungsbeitrag trägt zuerst die Fixkosten und danach den Gewinn."),
        .init(id: "be", title: "Break-even-Menge", expression: "Menge = Fixkosten / db", detail: "An diesem Punkt ist der Gewinn 0."),
        .init(id: "gewinn", title: "Gewinn", expression: "Gewinn = Menge × db − Fixkosten", detail: "Positiv, sobald die Break-even-Menge überschritten ist."),
        .init(id: "sk", title: "Selbstkosten je Stück", expression: "k = variable Stückkosten + Fixkosten / Menge", detail: "Fixkosten verteilen sich auf die hergestellte Menge."),
        .init(id: "eta", title: "Wirkungsgrad", expression: "η = Nutzleistung / zugeführte Leistung", detail: "Als Prozentwert: das Verhältnis mit 100 multiplizieren."),
        .init(id: "p", title: "Elektrische Leistung", expression: "P = U × I", detail: "Watt = Volt × Ampere."),
        .init(id: "r", title: "Ohmsches Gesetz", expression: "R = U / I", detail: "Ohm = Volt / Ampere."),
        .init(id: "rho", title: "Dichte", expression: "ρ = Masse / Volumen", detail: "Einheiten von Masse und Volumen müssen zusammenpassen."),
        .init(id: "melde", title: "Meldebestand", expression: "Verbrauch je Tag × Lieferzeit + Sicherheitsbestand", detail: "Bei Erreichen wird nachbestellt, damit der Bestand bis zur Lieferung reicht."),
        .init(id: "rw", title: "Lagerreichweite", expression: "Bestand / Verbrauch je Tag", detail: "Ergebnis in Tagen."),
        .init(id: "kap", title: "Schichtkapazität", expression: "verfügbare Minuten / Zeit je Stück", detail: "Erst Stunden in Minuten umrechnen."),
        .init(id: "abw", title: "Relative Abweichung", expression: "(Ist − Soll) / Soll × 100", detail: "Prozentuale Planabweichung."),
        .init(id: "nutz", title: "Nutzungsgrad", expression: "Istzeit / Sollzeit × 100", detail: "Zeigt, wie viel der geplanten Zeit genutzt wurde."),
        .init(id: "strom", title: "Stromkosten", expression: "Leistung in kW × Stunden × Preis je kWh", detail: "Leistung von Watt nach Kilowatt umrechnen, bevor du multiplizierst.")
    ]

    var body: some View {
        List {
            Section {
                Text("Kurzübersicht für das Rechentraining. In der Prüfung können die gegebenen Größen anders heißen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(formulas) { formula in
                VStack(alignment: .leading, spacing: 6) {
                    Text(formula.title)
                        .font(.headline)
                    Text(formula.expression)
                        .font(.body.monospaced())
                    Text(formula.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Formelsammlung")
    }
}
