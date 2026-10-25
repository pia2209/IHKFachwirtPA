import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Heute", systemImage: "house.fill") }

            NavigationStack { FlashcardView() }
                .tabItem { Label("Karten", systemImage: "rectangle.stack.fill") }

            NavigationStack { QuizView() }
                .tabItem { Label("Quiz", systemImage: "checkmark.circle.fill") }

            NavigationStack { ExamView() }
                .tabItem { Label("Prüfung", systemImage: "doc.text.fill") }

            NavigationStack { ProgressViewScreen() }
                .tabItem { Label("Fortschritt", systemImage: "chart.bar.fill") }
        }
    }
}
