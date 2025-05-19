import Foundation

extension String {
    //HTML formatlı string’i düz yazıya çevir
    func htmlToPlainText() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil) {
            return attributed.string
        }
        return self
    }
}
