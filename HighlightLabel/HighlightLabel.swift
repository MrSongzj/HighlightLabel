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

/// 高亮文本配置类
public class LabelHighlight {
    /// 高亮文本普通状态时的字体颜色
    public var color: UIColor? {
        didSet { control.updateColor() }
    }
    /// 高亮文本高亮状态时的字体颜色
    public var highlightColor: UIColor?
    /// 高亮文本高亮状态时的背景颜色
    public var backgroundColor: UIColor?
    
    /// 持有该对象的 control 对象，主要是用来和 control 对象交流。
    /// 用户通过和 LabelHighlight 对象交流，内部通过 control 对象来处理相应的业务逻辑
    fileprivate unowned var control: _LabelHighlightControl!
    
    /// 点击高亮文本回调函数
    public var tapAction: LabelHighlightTapAction?
    /// 设置点击高亮文本回调函数
    public func setTapAction(_ action: LabelHighlightTapAction?) {
        tapAction = action
    }
    
    /// 通过文本范围设置高亮文本。
    ///
    /// - Parameters:
    ///   - range: 高亮文本的范围
    ///   - color: 高亮文本普通状态时的颜色
    ///   - highlightColor: 高亮文本高亮状态时的颜色
    ///   - backgroundColor: 高亮文本高亮状态时的背景颜色
    ///   - tag: 标签
    public func set(range: NSRange,
                    color: UIColor? = nil,
                    highlightColor: UIColor? = nil,
                    backgroundColor: UIColor? = nil,
                    tag: Int = 0) {
        control.set(range: range, color: color, highlightColor: highlightColor, backgroundColor: backgroundColor, tag: tag)
    }
    
    /// 通过文本范围一次设置多个高亮文本。
    ///
    /// - Parameters:
    ///   - ranges: 高亮文本范围数组
    ///   - colors: 高亮文本普通状态时的颜色数组
    ///   - highlightColors: 高亮文本高亮状态时的颜色数组
    ///   - backgroundColors: 高亮文本高亮状态时的背景颜色数组
    ///   - tags: 标签数组
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
    
    /// 删除所有高亮文本数据
    public func remove() {
        control.removeFromSuperview()
    }
}

// MARK: - Extension LabelHighlight

public extension LabelHighlight {
    
    /// 通过指定字符串设置高亮文本
    /// 当指定字符串在完整的字符串中多个位置显示时，可以通过 index 参数精确的表达高亮文本的位置
    ///
    /// - Parameters:
    ///   - string: 高亮文本字符串
    ///   - color: 高亮文本普通状态时的颜色
    ///   - highlightColor: 高亮文本高亮状态时的颜色
    ///   - backgroundColor: 高亮文本高亮状态时的背景颜色
    ///   - tag: 标签
    ///   - index: 指定字符串在完整的字符串中匹配的位置，从 0 开始
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
    
    /// 通过多个指定字符串设置多个高亮文本
    /// 相同的字符串会依次匹配设置
    ///
    /// - Parameters:
    ///   - strings: 高亮文本字符串数组
    ///   - colors: 高亮文本普通状态时的颜色数组
    ///   - highlightColors: 高亮文本高亮状态时的颜色数组
    ///   - backgroundColors: 高亮文本高亮状态时的背景颜色数组
    ///   - tags: 标签数组
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
    
    /// 精确查找关键字的范围
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
    /// 高亮文本配置对象
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

/// 高亮文本控制中心
fileprivate class _LabelHighlightControl: UIView {
    
    // MARK: - Struct Item
    
    /// 高亮文本对象
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
    
    /// 用户通过这个对象来设置高亮文本
    var highlight = LabelHighlight()
    /// 被控制的 label
    var label: UILabel { return superview as! UILabel }
    
    // MARK: - Private Properties
    
    /// 高亮文本对象数组
    private var items = [Item]()
    /// 标记是否正在高亮状态
    private var isHighlighting = false
    /// 标记是否通过内部改动
    private var isChangeSelf = false
    /// 记录完整的属性字符串，主要是用来变换文本的高亮和普通状态
    private var wholeText: NSMutableAttributedString!
    /// 记录点击的属性字符串，主要是用来还原高亮文本普通状态时的样式
    private var touchedText: NSAttributedString!
    /// 记录点击的高亮文本对象
    private var touchedItem: Item?
    /// 点击手势，主要是用来控制是否拦截点击事件的传递，从而达到解决手势冲突的目的
    private var tapGesture: UITapGestureRecognizer {
        return gestureRecognizers!.first as! UITapGestureRecognizer
    }
    /// 记录某次点击的时间戳，用来区分每一次的点击事件
    private var touchesTimestamp = 0.0
    /// 共享数据，所有的 label 都共享一个 label 镜像，节省内存，优化性能
    private lazy var share = _LabelHighlightWindow.share
    
    // MARK: - Public Methods
    
    /// 设置高亮文本
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
    
    /// 更新高亮文本普通状态时的字体颜色
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
    
    /// 仿初始化方法，不重写 init 方法的原因是太麻烦了。还得重写 init(coder:) 方法
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
    
    /// 通过内部设置 label 的文本
    /// 用户修改了 label 的文本就需要重置高亮文本的配置，因为内部也有修改文本的需求但不需要重置，所以通过这个方法来区分这两种情况
    private func setText() -> UILabel {
        isChangeSelf = true
        return label
    }
    
    /// 通过点击位置的坐标点来获取高亮文本对象
    private func getItem(at point: CGPoint) -> Item? {
        guard bounds.contains(point) else { return nil }
        guard let index = itemIndexAt(point) else { return nil }
        return items[index]
    }
    
    /// 通过点击位置的坐标点来获取高亮文本对象的索引
    private func itemIndexAt(_ point: CGPoint) -> Int? {
        let colorValue = colorValueAt(point)
        // 只有 b == 255 时，r 的值才有效
        // 因为 apple 渲染 backgroundColor 时，边缘会有颜色的过度渐变过程，这样会导致 r 的值慢慢改变，从而无效。这个渐变过程无法确认，所以只有当 b 为255 时才能确保 r 是有效的。
        return colorValue.b == 255 ? colorValue.r : nil
    }
    
    /// 通过索引来获取对应的颜色
    private func getColor(at index: Int) -> UIColor {
        // 最多支持 256 个高亮配置。
        return UIColor(red: CGFloat(index) / 255, green: 0, blue: 1, alpha: 1)
    }
    
    /// 通过点击位置的坐标点来获取色值
    private func colorValueAt(_ point: CGPoint) -> (r: Int, g: Int, b: Int) {
        var pixel = [UInt8](repeatElement(0, count: 4))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo)!
        context.translateBy(x: -point.x, y: -point.y)
        share.labelCopy.layer.render(in: context)
        return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
    }
    
    /// 转换文本到 label 镜像中
    private func convertTextToLabelCopy(_ text: NSAttributedString) -> NSAttributedString {
        // 需要先修改 label 的 text，如果设置相同的 text 那么不会生成新的 attributedText
        setText().text = nil
        // 从新设置 text，主要是为了生成包括 label 各种设置的 attributedText
        setText().text = text.string
        let attributedText = NSMutableAttributedString(attributedString: label.attributedText!)
        // 还原 label 的文本，就当什么都没有发生过一样
        setText().attributedText = text
        let fullRange = NSRange(location: 0, length: text.length)
        // 如果用户是通过设置 label 的 attributedText 的话，那么上面拿到的 text 属性可能不全，所以还要遍历把所有属性添加进来
        /*
         给 label 设置 text 和 attributedText 是有区别的。简单说一下：
         设置 text 时，会生成 attributedText，这个 attributedText 会包含 label 的字体大小，段落等所有属性。之后再改变这些属性时都会更新到这个 attributedText 里，所以这种 attributedText 的属性是全的，其他的 label 直接设置这个 attributedText 就可以达到一样的显示效果
         设置 attributedText 时，取决于你的设置，一般不全，所以不能直接拿来使用。比如只设置了字体颜色，那么 label 在渲染时会去取 label 的字体大小等属性的值。所以不同的 label 设置这样的 attributedText 时如果 label 的属性的值不一样那么效果就不一样
         */
        text.enumerateAttributes(in: fullRange, options: .longestEffectiveRangeNotRequired) { (attributes, range, stop) in
            attributedText.addAttributes(attributes, range: range)
        }
        // 这里为所有高亮文本设置不同的背景色，把其他文本设置为黑色，方便计算
        attributedText.addAttribute(.foregroundColor, value: UIColor.clear, range: fullRange)
        attributedText.addAttribute(.backgroundColor, value: UIColor.black, range: fullRange)
        items.enumerated().forEach { (offset, item) in
            let color = self.getColor(at: offset)
            attributedText.addAttribute(.backgroundColor, value: color, range: item.range)
        }
        return attributedText
    }
    
    /// 处理点击事件前的准备
    private func prepareForTouches() {
        // 模拟 label 当前的显示效果
        share.labelCopy.numberOfLines = label.numberOfLines
        share.labelCopy.frame = bounds.offsetBy(dx: UIScreen.main.bounds.width, dy: 0)
        share.labelCopy.attributedText = convertTextToLabelCopy(label.attributedText!)
    }
    
    /// 获取高亮文本高亮状态下的 attributedString
    private func getHighlightedText(with item: Item) -> NSAttributedString {
        let text = NSMutableAttributedString(attributedString: touchedText)
        if let hColor = (item.hColor ?? highlight.highlightColor) {
            text.addAttribute(.foregroundColor, value: hColor, range: NSRange(location: 0, length: text.length))
        }
        if let bColor = (item.bColor ?? highlight.backgroundColor) {
            text.addAttribute(.backgroundColor, value: bColor, range: NSRange(location: 0, length: text.length))
        }
        return text
    }
    
    /// 控制显示高亮文本的高亮状态或普通状态
    private func showHighlight(_ show: Bool, with item: Item) {
        if isHighlighting == show { return }
        isHighlighting = show
        let text = show ? getHighlightedText(with: item) : touchedText!
        wholeText.replaceCharacters(in: item.range, with: text)
        // 渐变动画效果
        UIView.transition(with: label, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.setText().attributedText = self.wholeText
        })
    }
    
    /// 是否已经处理高亮文本的点击事件
    private func onHighlight(_ touches: Set<UITouch>) -> Bool {
        // 如果点击了高亮文本就处理
        guard let item = touchedItem else { return false }
        let touch = touches.first!
        switch touch.phase {
        case .began: showHighlight(true, with: item)
        case .moved:
            let point = touch.location(in: label)
            // 只有点击在同一个高亮文本时才显示高亮效果
            showHighlight(getItem(at: point) == item, with: item)
        case .ended:
            tapGesture.isEnabled = false
            showHighlight(false, with: item)
            let point = touch.location(in: label)
            // 如果点击结束时，点击位置在同一个高亮文本上就触发点击高亮文本回调函数
            if getItem(at: point) == item {
                highlight.tapAction?(label, touchedText, item.range, item.tag)
            }
        case .cancelled:
            tapGesture.isEnabled = false
            showHighlight(false, with: item)
        default: break
        }
        return true
    }
    
    private func reset() { items.removeAll() }
    
    // MARK: - Touches Events
    
    /*
     重写这个方法主要是为了解决手势冲突的问题。
     1. apple 处理点击事件的流程是介个样子的：1. 先找响应链（通过这个方法）2. 把事件分发给链上的手势 3. 然后走 touchesBegan 系列方法。
     2. 当有一个手势处理这个事件时，其他手势默认就不会再响应这个事件
     所以要在找响应链的过程中决定需不需要拦截事件传递给其他手势
     */
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // hitTest 会调用多次。。。原因：
        // https://lists.apple.com/archives/cocoa-dev/2014/Feb/msg00118.html
        let view = super.hitTest(point, with: event)
        // 因为这个方法会重复调用多次，而我们只需要处理一次，所以需要记录时间戳来区分
        if touchesTimestamp == event!.timestamp  { return view }
        touchesTimestamp = event!.timestamp
        // 如果点击的是这个视图就处理这次点击事件
        if self == view {
            touchedItem = nil
            if items.count > 0 {
                prepareForTouches()
                let point = convert(point, from: superview)
                // 是否点击了高亮文本
                if let item = getItem(at: point) {
                    touchedItem = item
                    // 备份当前 label 的文本，用于处理高亮文本普通状态和高亮状态的显示效果
                    wholeText = NSMutableAttributedString(attributedString: label.attributedText!)
                    touchedText = wholeText.attributedSubstring(from: item.range)
                    // 拦截点击事件，让其他手势不响应这次点击事件，就是这么简单
                    tapGesture.isEnabled = true
                }
            }
        }
        return view
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if onHighlight(touches) { return }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if onHighlight(touches) { return }
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if onHighlight(touches) { return }
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if onHighlight(touches) { return }
        super.touchesCancelled(touches, with: event)
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // 高亮文本是基于当前 label 文本的，所以只要 label 的文本改变就要重置之前的高亮文本设置
        isChangeSelf ? isChangeSelf = false : reset()
    }
}

// MARK: - _LabelHighlightWindow

/// 用于显示 label 镜像的 window
/// label 不添加到 window 上的话是不会渲染的
/// 这里用到了一个很有趣的设计模式 - 弱引用单例。可以实现存在其他对象持有时共享一个单例，没有其他对象持有时释放
fileprivate class _LabelHighlightWindow: UIWindow {
    private static weak var instance: _LabelHighlightWindow?
    static var share: _LabelHighlightWindow {
        if let i = instance {
            return i
        } else {
            let wd = _LabelHighlightWindow(frame: .zero)
            wd.isHidden = false
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
