//
//  ViewController.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/23.
//

import UIKit
import SnapKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        cell.textLabel?.text = "menuBtn"
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            menu.showView(from: cell)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
//        tableView.delegate = self
//        tableView.dataSource = self
//        view.addSubview(tableView)
//        tableView.snp.makeConstraints { make in
//            make.top.equalTo(88)
//            make.left.bottom.right.equalToSuperview()
//        }
        
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.orange
        button.setTitle("menuBtn", for: .normal)
        button.addTarget(
            self,
            action: #selector(buttonDidClick(sender:)),
            for: .touchUpInside
        )
        view.addSubview(button)
        button.frame = CGRect(x: 10, y: 88, width: 100, height: 50)
    }

    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.rowHeight = 44
        table.register(UITableViewCell.self, forCellReuseIdentifier: "myCell")
        return table
    }()

    lazy var menu: RTMenu = {
        let menu = RTMenu()
        menu.menuPosition = .bottomRight // 显示位置：view右下
        menu.menuWidth = 180 // 菜单宽度
        menu.rowHeight = 48 // 行高
        menu.cornerRadius = 20 // 圆角
        menu.spacing = 10
        menu.titleEdge = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
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
        return menu
    }()

    @objc func buttonDidClick(sender: UIButton) {
        menu.showView(from: sender)
    }
}
