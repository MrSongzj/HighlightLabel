//
//  ViewController.swift
//  HighlightLabelDemo
//
//  Created by MrSong on 2019/6/18.
//  Copyright © 2019 MrSong. All rights reserved.
//

import UIKit
import HighlightLabel

class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapView))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
        
        label.backgroundColor = .groupTableViewBackground
        label.numberOfLines = 0
        // 必须先设置 text 或者 attributedText，因为高亮文本是基于完整文本的
        label.text = "爱的魔力转圈圈。爱的魔力转圈圈。爱的魔力转圈圈。爱的魔力转圈圈。"
        // 设置全局样式
        label.hl.color = .blue
        label.hl.highlightColor = .red
        label.hl.backgroundColor = .yellow
        // 设置高亮对象的多种姿势
        label.hl.set(range: NSRange(location: 0, length: 2), color: .brown, highlightColor: .orange, backgroundColor: .clear, tag: 100)
        // 如果有多个相同的文本，可以同过 at 参数指定具体的位置
        label.hl.set(string: "转圈圈", color: .magenta, highlightColor: .red, backgroundColor: .clear, at: 3)
        // 相同的标签可以使用 tag 来区分
        label.hl.setMany(strings: ["魔力", "魔力"], tags: [0, 1])
        // 设置点击事件
        label.hl.setTapAction { (lb, attributedString, range, tag) in
            print("文案:\(attributedString.string) 位置:\(range) 标签:\(tag)")
        }
    }
    
    @objc func tapView() {
        print("妈妈再也不用担心我们会冲突了😄\nMom doesn't have to worry we will conflict anymore😄")
    }
}
