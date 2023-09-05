import AppKit
import OSLog

final class TextViewController: NSViewController {
	let textView: NSTextView
	let scrollView: NSScrollView
	let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TextViewController")
	let signposter: OSSignposter

	static func withScrollableTextView() -> TextViewController {
		let scrollView = NSTextView.scrollableTextView()
		let textView = scrollView.documentView as! NSTextView

		return TextViewController(textView: textView, scrollView: scrollView)
	}

	static func withTextKitOneView() -> TextViewController {
		let textView = NSTextView(usingTextLayoutManager: false)

		textView.isVerticallyResizable = true
		textView.isHorizontallyResizable = true
		textView.textContainer?.widthTracksTextView = true
		textView.layoutManager?.allowsNonContiguousLayout = true

		let max = CGFloat.greatestFiniteMagnitude
		let size = NSSize(width: max, height: max)

		textView.textContainer?.size = size
		textView.maxSize = size

		let scrollView = NSScrollView()

		scrollView.documentView = textView

		return TextViewController(textView: textView, scrollView: scrollView)
	}

	static func withManualTextKitTwoConfiguration() -> TextViewController {
		let textView = NSTextView(usingTextLayoutManager: true)

		textView.isVerticallyResizable = true
		textView.isHorizontallyResizable = true
		textView.textContainer?.widthTracksTextView = true

		let max = CGFloat.greatestFiniteMagnitude
		let size = NSSize(width: max, height: max)

		textView.textContainer?.size = size
		textView.maxSize = size

		let scrollView = NSScrollView()

		scrollView.documentView = textView

		return TextViewController(textView: textView, scrollView: scrollView)
	}

	init(textView: NSTextView, scrollView: NSScrollView) {
		self.signposter = OSSignposter(logger: logger)
		self.textView = textView
		self.scrollView = scrollView

		super.init(nibName: nil, bundle: nil)

		textView.delegate = self
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		scrollView.hasHorizontalScroller = true
		scrollView.hasVerticalScroller = true

		precondition(scrollView.documentView != nil)

		NSLayoutConstraint.activate([
			scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 400.0),
			scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300.0),
		])

		self.view = scrollView
	}

	func loadData() throws {
		guard let path = UserDefaults.standard.string(forKey: "testFileURL") else {
			return
		}

		let url = URL(filePath: path, directoryHint: .notDirectory)

		let attrs: [NSAttributedString.Key : Any] = [
			.font: NSFont.monospacedSystemFont(ofSize: 12.0, weight: .regular),
			.foregroundColor: NSColor.textColor,
		]

		let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
			.defaultAttributes: attrs,
		]

		let storage = try signposter.withIntervalSignpost(OSSignposter.loadStorageName) {
			try NSTextStorage(url: url, options: options, documentAttributes: nil)
		}

		signposter.withIntervalSignpost(OSSignposter.installStorageName) {
			textView.layoutManager!.replaceTextStorage(storage)
		}
	}
}

extension TextViewController: NSTextViewDelegate {
	func textView(_ aTextView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		switch commandSelector {
		case #selector(NSTextView.moveToEndOfDocument(_:)):
			signposter.withIntervalSignpost(OSSignposter.moveToEndOfDocumentName) {
				textView.moveToEndOfDocument(self)
			}
			return true
		default:
			return false
		}
	}
}