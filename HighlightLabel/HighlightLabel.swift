//
//  HighlightLabel.swift
//  HighlightLabel
//
//  Created by MrSong on 2019/6/13.
//  Copyright © 2019 MrSong. All rights reserved.
//

import Foundation
import UIKit

public typealias LabelHighlightTapAction = (UILabel, NSAttributedString, NSRange, Int) -> Void

// MARK: - Class LabelHighlight

public class LabelHighlight {
    public var color: UIColor? {
        didSet { control.updateColor() }
    }
    public var highlightColor: UIColor?
    public var backgroundColor: UIColor?
    
    fileprivate unowned var control: _LabelHighlightControl!
    
    public var tapAction: LabelHighlightTapAction?
    public func setTapAction(_ action: LabelHighlightTapAction?) {
        tapAction = action
    }
    
    public func set(range: NSRange,
                    color: UIColor? = nil,
                    highlightColor: UIColor? = nil,
                    backgroundColor: UIColor? = nil,
                    tag: Int = 0) {
        control.set(range: range, color: color, highlightColor: highlightColor, backgroundColor: backgroundColor, tag: tag)
    }
    
    public func setMany(ranges: [NSRange],
                        colors: [UIColor?]? = nil,
                        highlightColors: [UIColor?]? = nil,
                        backgroundColors: [UIColor?]? = nil,
                        tags: [Int]? = nil) {
        ranges.enumerated().forEach { (index, range) in
            let color = index < (colors?.count ?? 0) ? colors?[index] : nil
            let hColor = index < (highlightColors?.count ?? 0) ? highlightColors?[index] : nil
            let bColor = index < (backgroundColors?.count ?? 0) ? backgroundColors?[index] : nil
            let tag = index < (tags?.count ?? 0) ? tags![index] : 0
            set(range: range, color: color, highlightColor: hColor, backgroundColor: bColor, tag: tag)
        }
    }
    
    public func remove() {
        control.removeFromSuperview()
    }
}

// MARK: - Extension LabelHighlight

public extension LabelHighlight {
    func set(string: String,
             color: UIColor? = nil,
             highlightColor: UIColor? = nil,
             backgroundColor: UIColor? = nil,
             tag: Int = 0,
             at index: Int = 0) {
        guard let text = control.label.text else { return }
        let range = search(string: text, key: string, at: index)
        set(range: range, color: color, highlightColor: highlightColor, backgroundColor: backgroundColor, tag: tag)
    }
    
    func setMany(strings: [String],
                 colors: [UIColor?]? = nil,
                 highlightColors: [UIColor?]? = nil,
                 backgroundColors: [UIColor?]? = nil,
                 tags: [Int]? = nil) {
        if control.label.text == nil { return }
        var indexMap = [String: Int]()
        strings.enumerated().forEach { (i, string) in
            let color = i < (colors?.count ?? 0) ? colors?[i] : nil
            let hColor = i < (highlightColors?.count ?? 0) ? highlightColors?[i] : nil
            let bColor = i < (backgroundColors?.count ?? 0) ? backgroundColors?[i] : nil
            let tag = i < (tags?.count ?? 0) ? tags![i] : 0
            let index = indexMap[string] ?? 0
            set(string: string, color: color, highlightColor: hColor, backgroundColor: bColor, tag: tag , at: index)
            indexMap[string] = index + 1
        }
    }
    
    private func search(string: String, key: String, at index: Int) -> NSRange {
        let notFound = NSMakeRange(NSNotFound, NSNotFound)
        guard index > -1 else { return notFound }
        var components = string.components(separatedBy: key)
        guard index < components.count else { return notFound }
        components.removeSubrange((index + 1)..<components.count)
        let len = key.count
        let loc = components.reduce(-len) { $0 + $1.count + len }
        return NSMakeRange(loc, len)
    }
}

// MARK: - Extension UILabel

extension UILabel {
    
    public var hl: LabelHighlight {
        return (_ms_control ?? _ms_init()).highlight
    }
    
    private var _ms_control: _LabelHighlightControl? {
        return subviews.filter { $0 is _LabelHighlightControl }.first as? _LabelHighlightControl
    }
    
    private func _ms_init() -> _LabelHighlightControl {
        let control = _LabelHighlightControl(frame: bounds)._init()
        control.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addObserver(control, forKeyPath: "text", options: .new, context: nil)
        addObserver(control, forKeyPath: "attributedText", options: .new, context: nil)
        isUserInteractionEnabled = true
        addSubview(control)
        return control
    }
}


// MARK: - Class _LabelHighlightControl

fileprivate class _LabelHighlightControl: UIView {
    
    // MARK: - Struct Item
    
    struct Item: Equatable {
        let range: NSRange
        let highlightColor: UIColor?
        let backgroundColor: UIColor?
        let tag: Int
        
        static func == (lhs: Item, rhs: Item) -> Bool {
            return NSEqualRanges(lhs.range, rhs.range)
        }
    }
    
    // MARK: - Public Properties
    
    var highlight = LabelHighlight()
    var label: UILabel { return superview as! UILabel }
    
    // MARK: - Private Properties
    
    private var items = [Item]()
    private var isHighlighting = false
    private var isChangeSelf = false
    private let textStorage = NSTextStorage()
    private var wholeText: NSMutableAttributedString?
    private var touchedText: NSAttributedString?
    private var touchedItem: Item?
    private var textBounds: CGRect = .zero
    private var tapGesture: UITapGestureRecognizer {
        return gestureRecognizers!.first as! UITapGestureRecognizer
    }
    private var touchesTimestamp = 0.0
    
    
    // MARK: - Public Methods
    
    func set(range: NSRange,
             color: UIColor? = nil,
             highlightColor: UIColor? = nil,
             backgroundColor: UIColor? = nil,
             tag: Int) {
        guard let text = label.attributedText else { return }
        let attributedText = NSMutableAttributedString(attributedString: text)
        if let color = (color ?? highlight.color) {
            attributedText.addAttribute(.foregroundColor, value: color, range: range)
        }
        setText().attributedText = attributedText
        
        let item = Item(range: range, highlightColor: highlightColor, backgroundColor: backgroundColor, tag: tag)
        items.removeAll { $0 == item }
        items.append(item)
    }
    
    func updateColor() {
        guard items.count > 0 else { return }
        let text = NSMutableAttributedString(attributedString: label.attributedText!)
        if let color = highlight.color {
            items.forEach {
                text.addAttribute(.foregroundColor, value: color, range: $0.range)
            }
        } else {
            items.forEach {
                text.removeAttribute(.foregroundColor, range: $0.range)
            }
        }
        setText().attributedText = text
    }
    
    func _init() -> _LabelHighlightControl {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        highlight = LabelHighlight()
        highlight.control = self
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesBegan = false
        tapGesture.isEnabled = false
        addGestureRecognizer(tapGesture)
        return self
    }
    
    // MARK: - Private Methods
    
    private func setText() -> UILabel {
        isChangeSelf = true
        return label
    }
    
    private func prepareForTouches() {
        let layoutManager = textStorage.layoutManagers.first!
        let textContainer = layoutManager.textContainers.first!
        /*
         textContainer.size 的设置，我看过的所有开源框架都是使用 bounds.size，因为绝大部分框架都是自己渲染文本，所以没有问题，但是我发现有些文案的渲染使用 layoutManager 和 UILabel 显示的不一样。比如：模拟器 iPhone 6, label frame （0，0，view.width，200），numberOfLines = 0， text = "这是一个支持高亮的 UILabel 的扩展。欢迎使用。" 时，UILabel 的“使用。”会换行，左边的空间还很多，而 layoutManager 的“用。”会换行。
         目前没有找到原因。不过找了一个可能的解决方案：
         size 的设置使用 UILabel 的 textRect 的size 就可以了。
         简单的测试了一下没有发现问题。
         */
        /*
         单纯的使用 textRect 还是有问题，当 label 的高度固定，装不下全部的 text 时，最后一行会出现问题。因为最后一行一般都需要显示 ...。所以需要区分两种情况：1. 当 label 的内容可以全部显示时使用 textRect，显示不全时使用 bounds
         */
        /*
         无法精准区分显示全或不全的情况，所以该方案暂时放弃！！！！！
         */
        let textWidth = label.textRect(forBounds: bounds, limitedToNumberOfLines: label.numberOfLines).width
        textContainer.size = CGSize(width: textWidth, height: bounds.height)
//        if textRect.origin.y.sign == .plus {
//            textContainer.size = textRect.size
//        } else {
//            textContainer.size = bounds.size
//        }
//        print(textRect)
//        print(bounds)
        textContainer.maximumNumberOfLines = label.numberOfLines
        // 设置这里的 lineMode 是有效的，不会按照 attributedString 里的来，不知道为啥。
        textContainer.lineBreakMode = label.lineBreakMode
        // 设置字符串前先设置 textContainer，这样 layoutManager 才会在计算布局时把 textContainer 的配置计算进去
        textStorage.setAttributedString(convertLabelTextToLayout())
        textBounds = layoutManager.usedRect(for: textContainer)
        wholeText = NSMutableAttributedString(attributedString: label.attributedText!)
    }
    
    private func convertLabelTextToLayout() -> NSAttributedString {
        let text = label.attributedText!
        setText().text = nil
        setText().text = text.string
        let attributedText = NSMutableAttributedString(attributedString: label.attributedText!)
        setText().attributedText = text
        let fullRange = NSRange(location: 0, length: text.length)
        text.enumerateAttributes(in: fullRange, options: .longestEffectiveRangeNotRequired) { (attributes, range, stop) in
            attributedText.addAttributes(attributes, range: range)
        }
        NSAttributedString(attributedString: attributedText).enumerateAttribute(.paragraphStyle, in: fullRange, options: .longestEffectiveRangeNotRequired) { (p, range, stop) in
            let p = p as! NSParagraphStyle
            /* 关于 lineBreakMode。
             当为除了CharWrapping 和 WordWrapping 的其他 mode 时，使用 layoutManager 只能渲染一行。不知道为什么会这样！！！！
             目前只能暂时把其他 mode 都改为 WordWrapping。
             这样可能会导致最后一行显示不全时，出现 ... 时会出现位置计算不精确的问题。不过这种情况不多见。
             */
            switch p.lineBreakMode {
            case .byCharWrapping, .byWordWrapping: return
            default:
                let newP = NSMutableParagraphStyle()
                newP.setParagraphStyle(p)
                newP.lineBreakMode = .byWordWrapping
                attributedText.addAttribute(.paragraphStyle, value: newP, range: range)
            }
        }
        return attributedText
    }
    
    private func getItem(at point: CGPoint) -> Item? {
        let point = convertPointToLayout(point)
        guard textBounds.contains(point) else { return nil }
        let layoutManager = textStorage.layoutManagers.first!
        let index = layoutManager.glyphIndex(for: point, in: layoutManager.textContainers.first!)
        for item in items.reversed() {
            if item.range.contains(index) { return item }
        }
        return nil
    }
    
    private func convertPointToLayout(_ point: CGPoint) -> CGPoint {
        let textOffsetY = (bounds.height - textBounds.height) / 2
        return CGPoint(x: point.x, y: point.y - textOffsetY)
    }
    
    private func showHighlight(_ item: Item) {
        if isHighlighting { return }
        isHighlighting = true
        let text = NSMutableAttributedString(attributedString: touchedText!)
        if let hColor = (item.highlightColor ?? highlight.highlightColor) {
            text.addAttribute(.foregroundColor, value: hColor, range: NSRange(location: 0, length: text.length))
        }
        if let bColor = (item.backgroundColor ?? highlight.backgroundColor) {
            text.addAttribute(.backgroundColor, value: bColor, range: NSRange(location: 0, length: text.length))
        }
        wholeText!.replaceCharacters(in: item.range, with: text)
        UIView.transition(with: label, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.setText().attributedText = self.wholeText
        })
    }
    
    private func hideHighlight(_ item: Item) {
        if isHighlighting == false { return }
        isHighlighting = false
        wholeText!.replaceCharacters(in: item.range, with: touchedText!)
        UIView.transition(with: label, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.setText().attributedText = self.wholeText
        })
    }
    
    private func reset() { items.removeAll() }
    
    // MARK: - Touches Events
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // hitTest 会调用多次。。。原因：
        // https://lists.apple.com/archives/cocoa-dev/2014/Feb/msg00118.html
        let view = super.hitTest(point, with: event)
        if touchesTimestamp == event!.timestamp  { return view }
        touchesTimestamp = event!.timestamp
        if self == view {
            touchedItem = nil
            if items.count > 0 {
                prepareForTouches()
                let point = convert(point, from: superview)
                if let item = getItem(at: point) {
                    touchedText = wholeText!.attributedSubstring(from: item.range)
                    touchedItem = item
                    tapGesture.isEnabled = true
                }
            }
        }
        return view
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let item = touchedItem else {
            super.touchesBegan(touches, with: event)
            return
        }
        showHighlight(item)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let item = touchedItem else {
            super.touchesMoved(touches, with: event)
            return
        }
        let point = touches.first!.location(in: label)
        print(point.debugDescription + "\(getItem(at: point) == item)")
        getItem(at: point) == item ? showHighlight(item) : hideHighlight(item)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        tapGesture.isEnabled = false
        guard let item = touchedItem else {
            super.touchesEnded(touches, with: event)
            return
        }
        let point = touches.first!.location(in: label)
        guard getItem(at: point) == item else { return }
        highlight.tapAction?(label, touchedText!, item.range, item.tag)
        hideHighlight(item)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        tapGesture.isEnabled = false
        guard let item = touchedItem else {
            super.touchesCancelled(touches, with: event)
            return
        }
        hideHighlight(item)
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        isChangeSelf ? isChangeSelf = false : reset()
    }
}
