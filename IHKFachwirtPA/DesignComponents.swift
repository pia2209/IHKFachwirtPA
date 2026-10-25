import SwiftUI

struct AppCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay { RoundedRectangle(cornerRadius: 22).stroke(.quaternary) }
    }
}

struct SymbolBadge: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .frame(width: 36, height: 36)
            .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(Color.accentColor)
    }
}
