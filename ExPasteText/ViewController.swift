//
//  ViewController.swift
//  ExPasteText
//
//  Created by 김종권 on 2023/09/12.
//

import UIKit

class ViewController: UIViewController {
    private let scrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let stackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    private let textView = {
        let view = UITextView()
        view.textColor = .black
        view.backgroundColor = .lightGray
        view.isScrollEnabled = false
        view.font = .systemFont(ofSize: 34)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let label: UILabel = {
        let label = UILabel()
        label.text = "0/0"
        label.textColor = .blue
        label.font = .systemFont(ofSize: 24, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let maxCount = 1000
    private var textCount = 0 {
        didSet { label.text = "\(textCount)/\(maxCount)" }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(textView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
        ])
    }
}

extension ViewController: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let lastNSString = textView.text as NSString
        let allText = lastNSString.replacingCharacters(in: range, with: text)
        
        let overSize = allText.utf16Size <= maxCount
        let isPasted = 1 < text.utf16Size
        
        if isPasted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.scrollView.scrollToCursor(in: textView)
            }
        }
        
        guard !overSize else {
            textCount = allText.utf16Size
            return true
        }
        guard isPasted else {
            textCount = textView.text?.utf16Size ?? 0
            return false
        }
        
        if textView.text.utf16Size < maxCount {
            let isLastCursor = range.lowerBound >= textView.text.utf16Size
            
            /// "abc{붙여넣기}def" -> "abc{초과한 만큼 잘린 문자열}def"
            let utf16Index = (maxCount - textView.text.utf16Size)
            let index = text.index(utf16Index: utf16Index)
            let appendingText = text.substring(from: 0, to: index - 1)
            textView.text = textView.text.inserted(string: appendingText, utf16Index: range.lowerBound)
            
            /// 커서
            let movingCursorPosition = isLastCursor ? maxCount : (range.lowerBound + appendingText.utf16Size)
            let selectedRange = NSMakeRange(movingCursorPosition, 0)
            DispatchQueue.main.async {
                textView.selectedRange = selectedRange
            }
        } else {
            /// 이전에 입력된 문자열이 maxCount 넘을 때, 붙여넣기 시도한 경우 > 새로운 문자열이 입력되 않지만 커서가 뒤로 이동 > 다시 이전 위치로 커서 이동
            let selectedRange = NSMakeRange(range.lowerBound, 0)
            DispatchQueue.main.async {
                textView.selectedRange = selectedRange
            }
        }
        
        textCount = textView.text.utf16Size
        return false
    }
}

extension String {
    var utf16Size: Int {
        utf16.count
    }
    
    func substring(from: Int, to: Int) -> String {
        guard from < count, to >= 0, to - from >= 0 else { return "" }
        let startIndex = index(startIndex, offsetBy: from)
        let endIndex = index(startIndex, offsetBy: to + 1)
        return String(self[startIndex ..< endIndex])
    }
    
    func inserted(string: String, utf16Index: Int) -> String {
        let startIndex = index(utf16Index: utf16Index)
        guard 0 <= count - startIndex else { return string }
        return String(prefix(startIndex)) + string + String(suffix(count - startIndex))
    }
    
    func index(utf16Index: Int) -> Int {
        var ret = 0
        var count = 0
        
        for (i, v) in enumerated() {
            guard count <= utf16Index else { break }
            count += v.utf16.count
            ret = i
        }
        return ret
    }
}

extension UIScrollView {
    func scrollToCursor(in textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange else { return }
        
        // 커서 위치를 화면 좌표로 변환
        let cursorRect = textView.caretRect(for: selectedRange.start)
        
        // 커서 위치가 화면에 보이도록 스크롤
        let cursorRectInScrollView = textView.convert(cursorRect, to: self)
        let visibleRect = CGRect(x: 0, y: contentOffset.y, width: bounds.size.width, height: bounds.size.height)
        
        if !visibleRect.contains(cursorRectInScrollView.origin) {
            // 커서 위치가 화면에 보이지 않으면 스크롤
            scrollRectToVisible(cursorRectInScrollView, animated: true)
        }
    }
}
