//
//  RTAlertContainerViewController.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/25.
//

import UIKit

class RTAlertContainerViewController: UIViewController, RTAlertContainerDelegate {
    
    // 内容 View（遵守协议）
    private let contentView: RTAlertContentViewProtocol
    // 背景遮罩
    private let backgroundView = UIView()
    
    // MARK: - 初始化
    init(contentView: RTAlertContentViewProtocol) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindContentView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showAnimation()
    }
    
    // MARK: - UI 配置（原生 AutoLayout）
    private func setupUI() {
        // 背景遮罩
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.alpha = 0
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        
        // 内容 View
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = .zero
        contentView.layer.shadowRadius = 8
        view.addSubview(contentView)
        
        // 激活约束
        NSLayoutConstraint.activate([
            // 背景遮罩占满屏幕
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 内容 View 居中，左右边距20，上下边距40（最大宽度/高度限制）
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 40),
            contentView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - 绑定 ContentView 和 VC
    private func bindContentView() {
        contentView.bind(containerDelegate: self)
    }
    
    // MARK: - 弹出动画
    private func showAnimation() {
        contentView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        contentView.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.backgroundView.alpha = 1
            self.contentView.transform = .identity
            self.contentView.alpha = 1
        }
    }
    
    // MARK: - 隐藏动画（实现 AlertContainerDelegate）
    func dismissAlert(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.25) {
            self.backgroundView.alpha = 0
            self.contentView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
            completion?()
        }
    }
}

