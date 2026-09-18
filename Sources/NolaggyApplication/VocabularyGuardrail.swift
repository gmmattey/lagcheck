import Foundation

/// Guardrail client-side para assegurar conformidade com a tabela "Evitar" de docs/07-voz-do-produto.md
public enum VocabularyGuardrail {
    /// Termos proibidos pela voz do Nolaggy
    private static let prohibitedReplacements: [(pattern: String, replacement: String)] = [
        ("zero lag", "conexão mais estável"),
        ("zero-lag", "alta estabilidade"),
        ("rede perfeita", "rede otimizada"),
        ("ping perfeito", "menor latência"),
        ("garantido", "recomendado"),
        ("garantida", "recomendada"),
        ("amassou", "bom desempenho"),
        ("gg easy", "pronto para jogar"),
        ("modo turbo", "ajuste prioritário"),
        ("domine o servidor", "melhore sua estabilidade")
    ]
    
    /// Sanitiza o texto substituindo termos exagerados ou proibidos por alternativas neutras
    public static func sanitize(_ text: String) -> String {
        var sanitized = text
        for item in prohibitedReplacements {
            let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: item.pattern))\\b", options: .caseInsensitive)
            let range = NSRange(location: 0, length: (sanitized as NSString).length)
            sanitized = regex?.stringByReplacingMatches(in: sanitized, options: [], range: range, withTemplate: item.replacement) ?? sanitized
        }
        return sanitized
    }
    
    /// Sanitiza uma lista de ações recomendadas
    public static func sanitize(items: [BoosterActionItem]) -> [BoosterActionItem] {
        items.map { item in
            BoosterActionItem(
                id: item.id,
                category: item.category,
                title: sanitize(item.title),
                detail: sanitize(item.detail)
            )
        }
    }
}
