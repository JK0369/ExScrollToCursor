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
        let lastText = textView.text as NSString
        let allText = lastText.replacingCharacters(in: range, with: text)

        let canUseInput = allText.count <= maxCount

        defer {
            if canUseInput {
                textCount = allText.count
            } else {
                textCount = textView.text.count
            }
        }
        
        guard !canUseInput else { return canUseInput }
        
            if textView.text.count < maxCount {
                /// "abc{최대글자가 넘는 문자열 붙여넣기}def"
                /// 기대결과: "abc{문자열}def"
                let appendingText = text.substring(from: 0, to: maxCount - textView.text.count - 1)
                textView.text = textView.text.inserting(appendingText, at: range.lowerBound)
                
                let isLastCursor = range.lowerBound >= textView.text.count
                let movingCursorPosition = isLastCursor ? maxCount : (range.lowerBound + appendingText.count)
                DispatchQueue.main.async {
                    textView.selectedRange = NSMakeRange(movingCursorPosition, 0)
                }
            } else {
                /// 카운트 값을 넘었을때 중간 커서에서 붙여넣기 > 커서가 문자열만큼 뒤로 가는 버그 > 다시 커서 제자리로 위치시키는 코드
                DispatchQueue.main.async {
                    textView.selectedRange = NSMakeRange(range.lowerBound, 0)
                }
            }

        return canUseInput
    }
}

extension String {
    func substring(from: Int, to: Int) -> String {
        guard from < count, to >= 0, to - from >= 0 else { return "" }
        let startIndex = index(startIndex, offsetBy: from)
        let endIndex = index(startIndex, offsetBy: to + 1)
        return String(self[startIndex ..< endIndex])
    }
    
    func inserting(_ string: String, at index: Int) -> String {
        var originalString = self
        originalString.insert(contentsOf: string, at: self.index(self.startIndex, offsetBy: index))
        return originalString
    }
}
