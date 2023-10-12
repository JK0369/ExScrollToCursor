//
//  ViewController.swift
//  ExPasteText
//
//  Created by 김종권 on 2023/09/12.
//

import UIKit

class ViewController: UIViewController {
    private let textView = {
        let view = UITextView()
        view.textColor = .black
        view.backgroundColor = .lightGray
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
    
    private let maxCount = 300
    private var textCount = 0 {
        didSet { label.text = "\(textCount)/\(maxCount)" }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        
        view.addSubview(textView)
        view.addSubview(label)
        NSLayoutConstraint.activate([
            textView.heightAnchor.constraint(equalToConstant: 300),
            textView.widthAnchor.constraint(equalToConstant: 300),
            textView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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
