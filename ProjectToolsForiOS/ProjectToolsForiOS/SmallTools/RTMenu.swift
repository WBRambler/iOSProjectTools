//
//  RTMenu.swift
//  XRIntegrated
//
//  Created by WuBo on 2025/11/23.
//

import UIKit

// MARK: - 菜单选项模型

struct RTMenuItem {
    let title: String // 选项标题
    let image: UIImage? // 选项图片（可选）
    let action: (() -> Void)? // 选中回调（可选）
    init(title: String, image: UIImage? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.image = image
        self.action = action
    }
}

// MARK: - 自定义菜单视图（RTMenu）

class RTMenu: UIView {
    enum MenuPosition: Int {
        case topLeft // 菜单右下对齐按钮左上
        case bottomLeft // 菜单右上对齐按钮左下
        case topRight // 菜单左下对齐按钮右上
        case bottomRight // 菜单左上对齐按钮右下
    }

    // MARK: - 可配置属性（外部可动态修改）

    /// 显示位置（默认右下）
    var menuPosition: MenuPosition = .bottomLeft
    /// 菜单宽度（默认 160pt）
    var menuWidth: CGFloat = 160
    /// 选项行高（默认 44pt）
    var rowHeight: CGFloat = 44
    /// 菜单与按钮的间距（默认 4pt）
    var spacing: CGFloat = 4
    /// 菜单圆角（默认 8pt）
    var cornerRadius: CGFloat = 8
    /// 菜单阴影（默认开启）
    var hasShadow: Bool = true
    /// 开启遮罩（默认关闭）
    var hasMaskView: Bool = false
    /// 文本edge（默认 top: 16, left: 0, bottom: 0, right: 16）
    var titleEdge:UIEdgeInsets = .init(top: 16, left: 0, bottom: 0, right: 16)
    /// 数据源（动态更新时直接赋值即可）
    var items: [RTMenuItem] = [] {
        didSet {
            // 刷新后重新计算菜单高度
            tableView.reloadData()
            updateMenuHeight()
            updateMenuFrame()
        }
    }

    // MARK: - 私有属性

    private let tableView = UITableView()
    /// 记录当前绑定的按钮（用于计算位置）
    private weak var targetButton: UIButton?
    /// 半透明遮罩（点击外部隐藏菜单）
    private let menuMaskView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setUpParams()
    }

    // MARK: - 外部调用方法（显示菜单）

    /// 从指定按钮显示菜单
    /// - Parameter button: 绑定的按钮（菜单位置基于该按钮计算）
    func showView(from button: UIButton) {
        if superview != nil {
            print("当前菜单已显示")
            return
        }
        // 记录目标按钮
        targetButton = button
        // 获取按钮所在控制器的view（作为菜单父视图）
        guard let parentView = getParentViewControllerView(from: targetButton)
        else {
            print("未找到按钮所在的控制器视图，菜单显示失败")
            return
        }

        // 1. 准备工作：添加到父视图、刷新数据、计算位置
        parentView.addSubview(menuMaskView)
        parentView.addSubview(self)
        menuMaskView.frame = parentView.bounds

        // 2. 显示动画（淡入 + 缩放）
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.alpha = 1
                self.transform = .identity
                self.menuMaskView.alpha = 0.1
            }
        )
    }

    /// 隐藏菜单（带动画）
    func hiddenView() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.menuMaskView.alpha = 0
        } completion: { [weak self] _ in
            self?.removeFromSuperview()
            self?.menuMaskView.removeFromSuperview()
            self?.targetButton = nil
        }
    }
}

// MARK: - 私有 UI 搭建 + 逻辑处理

private extension RTMenu {
    /// 获取当前view所在的控制器的view（用于菜单添加）
    func getParentViewControllerView(from view: UIView?) -> UIView? {
        var responder: UIResponder? = view
        while responder != nil {
            if let vc = responder as? UIViewController {
                return vc.view
            }
            responder = responder?.next
        }
        return nil
    }

    /// 初始化 UI
    func setupUI() {
        // 1. 菜单基础样式
        backgroundColor = .white
        layer.masksToBounds = true
        clipsToBounds = true

        // 3. 遮罩视图（半透明黑色，点击隐藏）
        menuMaskView.backgroundColor = .black
        menuMaskView.alpha = 0.0
        let tapMask = UITapGestureRecognizer(
            target: self,
            action: #selector(maskTapped)
        )
        menuMaskView.addGestureRecognizer(tapMask)

        // 4. 表格配置（展示菜单选项）
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(
            top: 0,
            left: 16,
            bottom: 0,
            right: 16
        )
        tableView.register(
            RTMenuItemCell.self,
            forCellReuseIdentifier: "RTMenuItemCell"
        )
        tableView.bounces = false
    }

    func setUpParams() {
        layer.cornerRadius = cornerRadius
        tableView.rowHeight = rowHeight
        tableView.layer.cornerRadius = cornerRadius
        // 2. 阴影配置
        if hasShadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.15
            layer.shadowOffset = .zero
            layer.shadowRadius = cornerRadius
            layer.masksToBounds = false // 阴影需关闭 clipsToBounds
            layer.shadowPath =
                UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
                    .cgPath
        }
        menuMaskView.isHidden = !hasMaskView
        updateMenuHeight() // 基于数据源计算菜单高度
        updateMenuFrame() // 基于按钮位置和枚举计算菜单frame
    }

    func addCornerAndShadow(
        conrners: UIRectCorner,
        radius: CGFloat = 8,
        shadowColor: UIColor,
        shadowOffset: CGSize,
        shadowOpacity: Float,
        shadowRadius: CGFloat = 8
    ) {
        let maskPath = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: conrners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer

        let subLayer = CALayer()
        let fixframe = frame
        subLayer.frame = fixframe
        subLayer.cornerRadius = radius
        subLayer.backgroundColor = shadowColor.cgColor
        subLayer.masksToBounds = false
        // shadowColor阴影颜色
        subLayer.shadowColor = shadowColor.cgColor
        // shadowOffset阴影偏移,x向右偏移3，y向下偏移2，默认(0, -3),这个跟shadowRadius配合使用
        subLayer.shadowOffset = shadowOffset
        // 阴影透明度，默认0
        subLayer.shadowOpacity = shadowOpacity
        // 阴影半径，默认3
        subLayer.shadowRadius = shadowRadius
        subLayer.shadowPath = maskPath.cgPath
        superview?.layer.insertSublayer(subLayer, below: layer)
    }

    /// 基于数据源更新菜单高度
    func updateMenuHeight() {
        let height = CGFloat(items.count) * rowHeight
        frame = CGRect(x: 0, y: 0, width: menuWidth, height: height)
    }

    /// 基于按钮位置和枚举，计算菜单最终frame
    func updateMenuFrame() {
        guard let button = targetButton, let parentView = superview else {
            return
        }

        // 1. 获取按钮在父视图中的绝对frame（关键：转换坐标系）
        let buttonFrame = button.convert(button.bounds, to: parentView)

        // 2. 根据枚举计算菜单的origin（x,y）
        var menuOrigin: CGPoint = .zero
        switch menuPosition {
        case .topLeft:
            // 菜单右下对齐按钮左上 → x=按钮x - 菜单宽度，y=按钮y - 菜单高度
            menuOrigin.x = buttonFrame.origin.x - menuWidth + buttonFrame.width
            menuOrigin.y = buttonFrame.origin.y - frame.height - spacing
        case .bottomLeft:
            // 菜单右上对齐按钮左下 → x=按钮x - 菜单宽度，y=按钮y + 按钮高度 + spacing
            menuOrigin.x = buttonFrame.origin.x - menuWidth + buttonFrame.width
            menuOrigin.y = buttonFrame.origin.y + buttonFrame.height + spacing
        case .topRight:
            // 菜单左下对齐按钮右上 → x=按钮x，y=按钮y - 菜单高度 - spacing
            menuOrigin.x = buttonFrame.origin.x
            menuOrigin.y = buttonFrame.origin.y - frame.height - spacing
        case .bottomRight:
            // 菜单左上对齐按钮右下 → x=按钮x，y=按钮y + 按钮高度 + spacing
            menuOrigin.x = buttonFrame.origin.x
            menuOrigin.y = buttonFrame.origin.y + buttonFrame.height + spacing
        }

        // 3. 边界适配：避免菜单超出父视图（可选优化，防止显示不全）
        let maxX = parentView.bounds.width - frame.width
        let maxY = parentView.bounds.height - frame.height
        menuOrigin.x = max(0, min(menuOrigin.x, maxX))
        menuOrigin.y = max(0, min(menuOrigin.y, maxY))

        // 4. 设置菜单最终frame
        frame = CGRect(origin: menuOrigin, size: frame.size)
    }

    /// 点击遮罩隐藏菜单
    @objc func maskTapped() {
        hiddenView()
    }
}

// MARK: - UITableView 数据源 + 代理

extension RTMenu: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RTMenuItemCell", for: indexPath)
        guard let cell = cell as? RTMenuItemCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let item = items[indexPath.row]
        cell.configItem(item: item)
        // 配置cell样式（图标+标题）
        //        cell.imageView?.image = item.image
        //        cell.imageView?.tintColor = .systemBlue
        //        cell.textLabel?.text = item.title
        //        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        //        cell.accessoryType = .disclosureIndicator // 右侧箭头（可选）
        //        cell.selectionStyle = .default

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        item.action?() // 执行选中回调
        hiddenView() // 选中后自动隐藏菜单
    }
}

private class RTMenuItemCell: UITableViewCell {
    private var titleLBConstraints: [NSLayoutConstraint] = []
    let titleLB = UILabel()
    let itemImageView = UIImageView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    func configItem(item: RTMenuItem) {
        itemImageView.image = item.image
        titleLB.text = item.title
        NSLayoutConstraint.deactivate(titleLBConstraints)
        titleLBConstraints.removeAll()

        if item.image != nil {
            itemImageView.isHidden = false
            titleLBConstraints = [
                titleLB.topAnchor.constraint(equalTo: contentView.topAnchor),
                titleLB.leftAnchor.constraint(equalTo: itemImageView.rightAnchor, constant: 8),
                titleLB.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                titleLB.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ]
        } else {
            itemImageView.isHidden = true
            titleLBConstraints = [
                titleLB.topAnchor.constraint(equalTo: contentView.topAnchor),
                titleLB.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLB.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                titleLB.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ]
        }
        NSLayoutConstraint.activate(titleLBConstraints)
    }

    func setupUI() {
        titleLB.translatesAutoresizingMaskIntoConstraints = false
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        itemImageView.contentMode = .scaleAspectFill
        titleLB.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLB.textColor = .black
        contentView.addSubview(titleLB)
        contentView.addSubview(itemImageView)

        NSLayoutConstraint.activate([
            itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            itemImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            itemImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemImageView.heightAnchor.constraint(equalTo: itemImageView.widthAnchor)
        ])
        
        titleLBConstraints = [
            titleLB.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLB.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLB.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLB.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(titleLBConstraints)
    }
}
