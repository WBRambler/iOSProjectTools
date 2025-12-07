//
//  ViewController.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/23.
//

import SnapKit
import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
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
        
        let s = GoToCell.cell(with: UITableView())
        
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
        
        let stackView = DoubleButtonStackView()
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(60)
        }
        
        var ss: [String: Int] = ["1": 1, "3": 3]
        for index in ss {
            print(index)
        }

        // 1. 初始化
        let orderedDict = RTOrderedDictionary<String, Int>()
        orderedDict["a"] = 1
        orderedDict["b"] = 2
        orderedDict["c"] = 3

        // 2. 字面量初始化
        let _: RTOrderedDictionary<String, Any> = ["name": "Tom", "age": 20, "gender": "male"]

        // 3. 访问元素
        print(orderedDict["b"] as Any) // 输出: Optional(2)
        print(orderedDict[1]) // 输出: Optional((key: "b", value: 2))
        print(orderedDict.allKeys) // 输出: ["a", "b", "c"]
        print(orderedDict.allValues) // 输出: [1, 2, 3]

        // 4. 遍历
        for (key, value) in orderedDict {
            print("\(key): \(value)")
        }

        // 5. 移除元素
        orderedDict.removeValue(forKey: "b")
        print(orderedDict.count) // 输出: 2
        print(orderedDict.allKeys) // 输出: ["a", "c"]

        // 6. 索引访问（Collection协议支持）
        for pair in orderedDict {
            print(pair) // 输出: (key: "a", value: 1), (key: "c", value: 3)
        }

        // 7. 检查包含关系
        print(orderedDict.containsKey("a")) // 输出: true
        print(orderedDict.containsValue(3)) // 输出: true
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
//        let sss = randomString()
//        RTToast.show(sss)

//        // 2. 自定义显示时长（3秒后消失）
//        RTToast.show("数据加载中...", duration: 3.0)
        ////
        ////        // 3. 长文本（自动换行）
//        RTToast.show("这是一个多行文本的Toast提示，测试文本长度超过屏幕宽度85%时的自动换行效果")
        
        showInputAlertView()
    }
    
    func showInputAlertView() {
        let inputView = RTAlertInputView()
        inputView.title = "请输入反馈"
        inputView.message = "请详细描述你的问题（支持多行输入）"

        // 取消按钮
        let cancelAction = RTAlertAction(title: "取消", style: .cancel) { _ in
            print("取消输入")
        }
        inputView.addAction(cancelAction)

        // 确认按钮
        let confirmAction = RTAlertAction(title: "提交", style: .default) { [weak inputView] _ in
            print("用户输入：\(inputView?.inputText ?? "无")")
        }
        inputView.addAction(confirmAction)

        // 展示弹窗
        let alertVC = RTAlertContainerViewController(contentView: inputView)
        present(alertVC, animated: true)
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
