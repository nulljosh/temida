import CoreText
import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// v11: the open case as a paginated PDF for counsel, drawn with CoreText on the device (iPhone and Mac alike).
/// It is only written when the person shares it; nothing is uploaded.
struct BriefPDF: Transferable {
    struct Section: Sendable { let heading: String; let lines: [String] }
    let title: String
    let sections: [Section]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { SentTransferredFile(try $0.write()) }
    }

    func write() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Brief.pdf")
        var box = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { throw CocoaError(.fileWriteUnknown) }
        let text = attributed
        let setter = CTFramesetterCreateWithAttributedString(text)
        let path = CGPath(rect: box.insetBy(dx: 54, dy: 54), transform: nil)
        var start = 0
        repeat {
            ctx.beginPDFPage(nil)
            let frame = CTFramesetterCreateFrame(setter, CFRange(location: start, length: 0), path, nil)
            CTFrameDraw(frame, ctx)
            ctx.endPDFPage()
            let drawn = CTFrameGetVisibleStringRange(frame).length
            if drawn == 0 { break } // ponytail: a line taller than a page would loop forever
            start += drawn
        } while start < text.length
        ctx.closePDF()
        return url
    }

    private var attributed: NSAttributedString {
        let out = NSMutableAttributedString()
        func add(_ s: String, _ size: CGFloat, bold: Bool = false) {
            let font = CTFontCreateUIFontForLanguage(bold ? .emphasizedSystem : .system, size, nil)!
            var gap: CGFloat = size * 0.5 // room between items, so each fact or witness reads as its own line
            let style = withUnsafeBytes(of: &gap) { CTParagraphStyleCreate([CTParagraphStyleSetting(spec: .paragraphSpacing, valueSize: MemoryLayout<CGFloat>.size, value: $0.baseAddress!)], 1) }
            out.append(NSAttributedString(string: s + "\n", attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font,
                                                                         NSAttributedString.Key(kCTParagraphStyleAttributeName as String): style]))
        }
        add(title, 22, bold: true)
        add(Date.now.formatted(date: .long, time: .omitted), 10)
        for s in sections where !s.lines.isEmpty {
            add("", 8)
            add(s.heading, 13, bold: true)
            s.lines.forEach { add($0, 11) }
        }
        return out
    }
}
