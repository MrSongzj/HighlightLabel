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
        label.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 121.6)

        label.backgroundColor = .orange
        label.text = "这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。这是一个支持高亮的 UILabel 的扩展。欢迎使用。这是一个支持高亮的 UILabel 的扩展。欢迎使用。"
        label.numberOfLines = 0
        label.hl.color = .blue
        label.hl.highlightColor = UIColor.blue.withAlphaComponent(0.5)
        label.hl.backgroundColor = .lightGray
//        label.hl.setMany(strings: ["高亮", "使用"])
        label.hl.set(string: "亮的", at: 1)
        label.font = UIFont.systemFont(ofSize: 25)
        label.hl.setTapAction { (lb, string, range, tag) in
            print(string.string)
        }
    }
}
