import SwiftUI
import UIKit

// MARK: - Export Function
@MainActor
func exportViewAsPDF<V: View>(view: V, suggestedName: String) async throws -> URL {
    // Create renderer for any SwiftUI view
    let renderer = ImageRenderer(content: view)
    let data = await renderer.pdfData()

    // Save to Documents folder
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let url = documents.appendingPathComponent("\(suggestedName).pdf")

    try data.write(to: url, options: .atomic)
    return url
}

// MARK: - ImageRenderer Extension
@MainActor
extension ImageRenderer {
    /// Cross-platform PDF from a SwiftUI view.
    func pdfData() async -> Data {
        #if os(iOS)
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let format = UIGraphicsPDFRendererFormat()

        let data = UIGraphicsPDFRenderer(bounds: pageBounds, format: format).pdfData { ctx in
            self.render { size, renderer in
                ctx.beginPage()

                // margins + draw rect
                let margin: CGFloat = 24
                let drawRect = CGRect(
                    x: margin,
                    y: margin,
                    width: max(0, pageBounds.width  - margin * 2),
                    height: max(0, pageBounds.height - margin * 2)
                )

                // scale to fit and center
                ctx.cgContext.saveGState()
                let scale = min(drawRect.width / size.width, drawRect.height / size.height)
                ctx.cgContext.translateBy(x: drawRect.minX, y: drawRect.minY)
                ctx.cgContext.scaleBy(x: scale, y: scale)
                let offsetX = max(0, (drawRect.width  / scale - size.width)  / 2)
                let offsetY = max(0, (drawRect.height / scale - size.height) / 2)
                ctx.cgContext.translateBy(x: offsetX, y: offsetY)

                // ✅ renderer expects a CGContext
                renderer(ctx.cgContext)

                ctx.cgContext.restoreGState()
            }
        }
        return data
        #else
        // macOS CoreGraphics PDF
        let data = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard
            let consumer = CGDataConsumer(data: data as CFMutableData),
            let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { return Data() }

        self.render { size, renderer in
            ctx.beginPDFPage(nil)

            let margin: CGFloat = 24
            let drawRect = CGRect(
                x: margin,
                y: margin,
                width: max(0, mediaBox.width  - margin * 2),
                height: max(0, mediaBox.height - margin * 2)
            )

            ctx.saveGState()
            let scale = min(drawRect.width / size.width, drawRect.height / size.height)
            ctx.translateBy(x: drawRect.minX, y: drawRect.minY)
            ctx.scaleBy(x: scale, y: scale)
            let offsetX = max(0, (drawRect.width  / scale - size.width)  / 2)
            let offsetY = max(0, (drawRect.height / scale - size.height) / 2)
            ctx.translateBy(x: offsetX, y: offsetY)

            renderer(ctx)
            ctx.restoreGState()
            ctx.endPDFPage()
        }

        ctx.closePDF()
        return data as Data
        #endif
    }
}
