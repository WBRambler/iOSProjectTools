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
  
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(88)
            make.left.bottom.right.equalToSuperview()
        }
        
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
    
//    func randomString(length: Int = 6) -> String {
//        // 可选字符集：大小写字母 + 数字
//        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
//        // 转为字符数组，便于随机取值
//        let characterArray = Array(characters)
//        // 生成指定长度的随机字符串
//        return (0..<length).map { _ in
//            characterArray[Int.random(in: 0..<characterArray.count)]
//        }.joined()
//    }
    
    func randomString(length: Int = 6) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let characterArray = Array(characters)
        return (0..<length).map { _ in
            String(characterArray[Int.random(in: 0..<characterArray.count)]) // 字符转字符串
        }.joined()
    }

    @objc func buttonDidClick(sender: UIButton) {
//        menu.showView(from: sender)
//        showTwoButtonAlert()
//        showScrollableAlert()
        // 1. 基础使用（默认2秒消失）
        let sss = randomString()
        RTToast.show(sss)

//        // 2. 自定义显示时长（3秒后消失）
//        RTToast.show("数据加载中...", duration: 3.0)
////
////        // 3. 长文本（自动换行）
//        RTToast.show("这是一个多行文本的Toast提示，测试文本长度超过屏幕宽度85%时的自动换行效果")
    }
    
    func showTwoButtonAlert() {
        let alertView = RTDefaultAlertView()
           alertView.title = "确认操作"
           alertView.message = "是否删除该文件？删除后无法恢复"
           
           // 取消按钮（蓝色）
           let cancelAction = RTAlertAction(title: "取消", style: .cancel) { _ in
               print("点击了取消按钮")
           }
           // 删除按钮（红色）
           let deleteAction = RTAlertAction(title: "删除", style: .destructive) { _ in
               print("点击了删除按钮")
           }
           
           alertView.addAction(cancelAction)
           alertView.addAction(deleteAction)
           
           let alertVC = RTAlertContainerViewController(contentView: alertView)
           present(alertVC, animated: true)
    }

    func showScrollableAlert() {
        let alertView = RTDefaultAlertView()
        alertView.title = "选择选项"
        alertView.message = "请选择一个操作（超过3个按钮将支持滑动）范德萨范德萨范德萨范德萨发大沙发打撒"
        
        // 添加4个按钮
        let action1 = RTAlertAction(title: "选项1", style: .default) { _ in print("选择选项1") }
        let action2 = RTAlertAction(title: "选项2", style: .default) { _ in print("选择选项2") }
        let action3 = RTAlertAction(title: "选项3", style: .default) { _ in print("选择选项3") }
        let action4 = RTAlertAction(title: "取消", style: .cancel) { _ in print("点击取消") }
        let action5 = RTAlertAction(title: "选项3", style: .default) { _ in print("选择选项3") }
//        let action6 = RTAlertAction(title: "取消", style: .cancel) { _ in print("点击取消") }
        
        alertView.addAction(action1)
        alertView.addAction(action2)
        alertView.addAction(action3)
//        alertView.addAction(action4)
//        alertView.addAction(action5)
//        alertView.addAction(action6)
        
        let alertVC = RTAlertContainerViewController(contentView: alertView)
        present(alertVC, animated: true)
    }
}
