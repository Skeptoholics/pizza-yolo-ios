import SwiftUI

struct ShoppingListView: View {
    let title: String
    let flour: String
    let water: String
    let salt: String
    let yeast: String
    let doughBalls: Int
    let ballWeight: String
    let flourCups: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title).bold()
            Divider()
            Text("Dough balls: \(doughBalls)")
            Text("Ball weight: \(ballWeight)")
            Divider()
            Text("Flour: \(flour)  (\(flourCups))")
            Text("Water: \(water)")
            Text("Salt: \(salt)")
            Text("Yeast: \(yeast)")
        }
        .padding(24)
        .frame(maxWidth: 500, alignment: .leading)
    }
}

@MainActor
func exportShoppingListPDF(view: ShoppingListView, suggestedName: String) async throws -> URL {
    let renderer = ImageRenderer(content: view)
    #if os(macOS)
    renderer.isOpaque = false
    #endif

    let data = renderer.pdfData()
    let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    let url = desktop.appendingPathComponent("\(suggestedName).pdf")
    try data.write(to: url, options: .atomic)
    return url
}

extension ImageRenderer {
    func pdfData() -> Data {
        #if os(iOS)
        let format = UIGraphicsPDFRendererFormat()
        let r = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792), format: format)
        return r.pdfData { ctx in
            ctx.beginPage()
            self.render { ctx2 in
                ctx2.cgContext.translateBy(x: 24, y: 24)
            }
        }
        #else
        let pdf = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(data: pdf as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }
        ctx.beginPDFPage(nil)
        self.render { _ in }
        ctx.endPDFPage()
        ctx.closePDF()
        return pdf as Data
        #endif
    }
}
