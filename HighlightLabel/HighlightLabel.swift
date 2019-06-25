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
    /// 共享数据
    lazy var share = _LabelHighlightWindow.share
    
    // MARK: - Struct Item
    
    struct Item: Equatable {
        let range: NSRange
        let hColor: UIColor?
        let bColor: UIColor?
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
    private var wholeText: NSMutableAttributedString?
    private var touchedText: NSAttributedString?
    private var touchedItem: Item?
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
        
        let item = Item(range: range, hColor: highlightColor, bColor: backgroundColor, tag: tag)
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
    
    private func getItem(at point: CGPoint) -> Item? {
        guard bounds.contains(point) else { return nil }
        guard let index = itemIndexAt(point) else { return nil }
        return items[index]
    }
    
    private func itemIndexAt(_ point: CGPoint) -> Int? {
        let colorValue = colorValueAt(point)
        return colorValue.b == 255 ? colorValue.r : nil
    }
    
    private func getColor(at index: Int) -> UIColor {
        // 最多支持 256 个高亮配置。
        return UIColor(red: CGFloat(index) / 255, green: 0, blue: 1, alpha: 1)
    }
    
    private func colorValueAt(_ point: CGPoint) -> (r: Int, g: Int, b: Int) {
        var pixel = [UInt8](repeatElement(0, count: 4))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo)!
        context.translateBy(x: -point.x, y: -point.y)
        share.labelCopy.layer.render(in: context)
        return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
    }
    
    private func convertTextToLabelCopy(_ text: NSAttributedString) -> NSAttributedString {
        setText().text = nil
        setText().text = text.string
        let attributedText = NSMutableAttributedString(attributedString: label.attributedText!)
        setText().attributedText = text
        let fullRange = NSRange(location: 0, length: text.length)
        text.enumerateAttributes(in: fullRange, options: .longestEffectiveRangeNotRequired) { (attributes, range, stop) in
            attributedText.addAttributes(attributes, range: range)
        }
        attributedText.addAttribute(.foregroundColor, value: UIColor.clear, range: fullRange)
        attributedText.addAttribute(.backgroundColor, value: UIColor.black, range: fullRange)
        items.enumerated().forEach { (offset, item) in
            let color = self.getColor(at: offset)
            attributedText.addAttribute(.backgroundColor, value: color, range: item.range)
        }
        return attributedText
    }
    
    private func prepareForTouches() {
        let text = label.attributedText!
        wholeText = NSMutableAttributedString(attributedString: text)
        share.labelCopy.numberOfLines = label.numberOfLines
        share.labelCopy.frame = bounds.offsetBy(dx: UIScreen.main.bounds.width, dy: 0)
        share.labelCopy.attributedText = convertTextToLabelCopy(text)
    }
    
    private func showHighlight(_ item: Item) {
        if isHighlighting { return }
        isHighlighting = true
        let text = NSMutableAttributedString(attributedString: touchedText!)
        if let hColor = (item.hColor ?? highlight.highlightColor) {
            text.addAttribute(.foregroundColor, value: hColor, range: NSRange(location: 0, length: text.length))
        }
        if let bColor = (item.bColor ?? highlight.backgroundColor) {
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
        getItem(at: point) == item ? showHighlight(item) : hideHighlight(item)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        tapGesture.isEnabled = false
        guard let item = touchedItem else {
            super.touchesEnded(touches, with: event)
            return
        }
        hideHighlight(item)
        let point = touches.first!.location(in: label)
        guard getItem(at: point) == item else { return }
        highlight.tapAction?(label, touchedText!, item.range, item.tag)
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

fileprivate class _LabelHighlightWindow: UIWindow {
    private static weak var instance: _LabelHighlightWindow?
    static var share: _LabelHighlightWindow {
        if let i = instance {
            return i
        } else {
            let wd = self.init()
            wd.isHidden = false
            wd.frame = .zero
            let label = UILabel()
            label.backgroundColor = .black
            label.tag = 1
            wd.addSubview(label)
            instance = wd
            return wd
        }
    }
    var labelCopy: UILabel {
        return viewWithTag(1) as! UILabel
    }
}
