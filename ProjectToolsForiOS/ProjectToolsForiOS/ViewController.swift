//
//  ViewController.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.red
        button.addTarget(
            self,
            action: #selector(buttonDidClick(sender:)),
            for: .touchUpInside
        )
        view.addSubview(button)
        button.frame = CGRect(x: 10, y: 88, width: 100, height: 50)
    }

    @objc func buttonDidClick(sender:UIButton) {
        // 1. 创建菜单并配置属性
        let menu = RTMenu()
        menu.menuPosition = .bottomLeft // 显示位置：按钮右下
        menu.menuWidth = 180 // 菜单宽度
        menu.rowHeight = 48 // 行高
        menu.cornerRadius = 20 // 圆角
        menu.spacing = 20
        // 2. 配置数据源（支持动态修改：后续直接给 menu.items 赋值即可）
        menu.items = [
            RTMenuItem(title: "选项1", image: UIImage(systemName: "house")) {
                print("选中选项1")
                // 你的业务逻辑...
            },
            RTMenuItem(title: "选项2", image: UIImage(systemName: "person")) {
                print("选中选项2")
            },
            RTMenuItem(title: "选项3（无图）") {
                print("选中选项3")
            }
        ]
        
        // 3. 从按钮显示菜单
        menu.showView(from: sender)
    }
}

