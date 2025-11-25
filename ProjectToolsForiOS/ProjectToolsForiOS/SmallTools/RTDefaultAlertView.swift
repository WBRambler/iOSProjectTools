//
//  RTDefaultAlertView.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/25.
//

import UIKit

// MARK: - 默认弹窗内容 View（支持1/2/3+按钮，3+时滑动）
class RTDefaultAlertView: UIView, RTAlertContentViewProtocol {
    
    // 协议属性
    var preferredSize: CGSize {
        systemLayoutSizeFitting(UIView.layoutFittingCompressedSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }
    
    var title: String? {
        didSet { titleLabel.text = title }
    }
    
    var message: String? {
        didSet { messageLabel.text = message }
    }
    
    // 私有属性
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let buttonStackView = UIStackView()
    private let buttonScrollView = UIScrollView()
    private var actions: [RTAlertAction] = []
    weak var containerDelegate: RTAlertContainerDelegate?
    
    // 布局常量
    private enum LayoutConstant {
        static let contentInset: CGFloat = 20
        static let buttonHeight: CGFloat = 44
        static let buttonSpacing: CGFloat = 1
        static let maxScrollHeight: CGFloat = 200
        static let mainSpacing: CGFloat = 16
    }
    
    // 动态约束引用
    private var scrollViewHeightConstraint: NSLayoutConstraint!
    private var buttonStackWidthConstraint: NSLayoutConstraint!
    
    // 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 1. 初始化视图
    private func setupViews() {
        backgroundColor = .white
        
        // 标题标签
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 消息标签
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textColor = .darkGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 按钮StackView
        buttonStackView.spacing = LayoutConstant.buttonSpacing
        buttonStackView.backgroundColor = .lightGray
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 滚动容器
        buttonScrollView.backgroundColor = .lightGray
        buttonScrollView.showsVerticalScrollIndicator = false
        buttonScrollView.bounces = true
        buttonScrollView.translatesAutoresizingMaskIntoConstraints = false
        buttonScrollView.addSubview(buttonStackView)
        
        // 主容器
        let mainStackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel, buttonScrollView])
        mainStackView.axis = .vertical
        mainStackView.spacing = LayoutConstant.mainSpacing
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)
    }
    
    // 2. 规范约束
    private func setupConstraints() {
        let mainStackView = (subviews.first as! UIStackView)
        
        // 主容器约束
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: LayoutConstant.contentInset),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: LayoutConstant.contentInset),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -LayoutConstant.contentInset),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -LayoutConstant.contentInset)
        ])
        
        // 滚动容器约束
        scrollViewHeightConstraint = buttonScrollView.heightAnchor.constraint(equalToConstant: LayoutConstant.buttonHeight)
        NSLayoutConstraint.activate([
            scrollViewHeightConstraint,
            buttonScrollView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor)
        ])
        
        // 按钮StackView约束
        buttonStackWidthConstraint = buttonStackView.widthAnchor.constraint(equalTo: buttonScrollView.widthAnchor)
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: buttonScrollView.topAnchor),
            buttonStackView.leadingAnchor.constraint(equalTo: buttonScrollView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonScrollView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonScrollView.bottomAnchor),
            buttonStackWidthConstraint
        ])
    }
    
    // 协议方法：绑定代理
    func bind(containerDelegate: RTAlertContainerDelegate) {
        self.containerDelegate = containerDelegate
    }
    
    // 协议方法：添加按钮
    func addAction(_ action: RTAlertAction) {
        actions.append(action)
        let button = createActionButton(action: action)
        buttonStackView.addArrangedSubview(button)
        updateDynamicLayout()
    }
    
    // 3. 动态布局（核心修改：滚动条件改为 >3 个按钮）
    private func updateDynamicLayout() {
        switch actions.count {
        case 1:
            // 1个按钮：垂直分布，不滚动
            buttonStackView.axis = .vertical
            buttonStackView.distribution = .fill
            scrollViewHeightConstraint.constant = LayoutConstant.buttonHeight
            buttonScrollView.isScrollEnabled = false
            
        case 2:
            // 2个按钮：左右布局，不滚动
            buttonStackView.axis = .horizontal
            buttonStackView.distribution = .fillEqually
            scrollViewHeightConstraint.constant = LayoutConstant.buttonHeight
            buttonScrollView.isScrollEnabled = false
            
        case 3:
            // 3个按钮：垂直分布，不滚动（关键修改：3个按钮不滚动）
            buttonStackView.axis = .vertical
            buttonStackView.distribution = .fillEqually
            // 计算3个按钮总高度：3*按钮高度 + 2*间距
            let totalHeight = (LayoutConstant.buttonHeight * 3) + (LayoutConstant.buttonSpacing * 2)
            scrollViewHeightConstraint.constant = totalHeight
            buttonScrollView.isScrollEnabled = false
            
        default:
            // 4个及以上按钮：垂直分布+滚动（关键修改：>3才滚动）
            buttonStackView.axis = .vertical
            buttonStackView.distribution = .fillEqually
            buttonScrollView.isScrollEnabled = true
            
            // 计算总高度
            let totalStackHeight = (LayoutConstant.buttonHeight * CGFloat(actions.count)) + (LayoutConstant.buttonSpacing * CGFloat(actions.count - 1))
            scrollViewHeightConstraint.constant = min(totalStackHeight, LayoutConstant.maxScrollHeight)
        }
        
        // 强制刷新布局
        DispatchQueue.main.async { [weak self] in
            self?.layoutIfNeeded()
        }
    }
    
    // 4. 创建按钮
    private func createActionButton(action: RTAlertAction) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 按钮样式
        switch action.style {
        case .cancel:
            button.setTitleColor(.systemBlue, for: .normal)
        case .default:
            button.setTitleColor(.black, for: .normal)
        case .destructive:
            button.setTitleColor(.systemRed, for: .normal)
        }
        
        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        button.tag = actions.count - 1
        
        // 垂直分布时固定按钮高度
        if actions.count != 2 { // 只有2个按钮（左右布局）不需要固定高度
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: LayoutConstant.buttonHeight)
            ])
        }
        
        return button
    }
    
    // 按钮点击回调
    @objc private func actionButtonTapped(_ button: UIButton) {
        guard button.tag < actions.count else { return }
        let action = actions[button.tag]
        action.handler?(action)
        containerDelegate?.dismissAlert(completion: nil)
    }
}
