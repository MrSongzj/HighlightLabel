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
    
//    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        view.addSubview(label)
        label.frame = CGRect(x: 0, y: 80, width: view.bounds.width, height: 121.7)

        label.backgroundColor = .orange
//        label.text = "这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。欢迎使用。"
        let attText = NSMutableAttributedString(string: "这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。欢迎使用。")
        attText.addAttribute(.backgroundColor, value: UIColor.purple, range: NSRange(location: 30, length: 1))
        attText.addAttribute(.backgroundColor, value: UIColor.red, range: NSRange(location: 32, length: 1))
        label.attributedText = attText
        label.numberOfLines = 0
        label.hl.color = .blue
        label.hl.highlightColor = UIColor.blue.withAlphaComponent(0.5)
        label.hl.backgroundColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 35)
        label.hl.set(string: "使用", at: 0)
        label.hl.set(string: "。", at: 8)
        label.hl.setTapAction { (lb, string, range, tag) in
            print(string.string)
        }
    }
}

