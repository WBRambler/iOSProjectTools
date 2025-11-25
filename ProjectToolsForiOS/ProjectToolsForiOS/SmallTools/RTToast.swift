//
//  RTToast.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/25.
//

import UIKit

class RTToast: UIView {
    // MARK: - 配置常量（可按需调整）
    private enum Config {
        static let padding: UIEdgeInsets = .init(top: 12, left: 20, bottom: 12, right: 20)
        static let bottomOffset: CGFloat = 30 // 底部偏上30pt
        static let maxWidthRatio: CGFloat = 0.85 // 最大宽度=屏幕宽度×0.85
        static let cornerRadius: CGFloat = 8
        static let bgAlpha: CGFloat = 0.8
        static let textColor: UIColor = .white
        static let font: UIFont = .systemFont(ofSize: 15)
        static let showDuration: TimeInterval = 2.0
        static let normalAnimationDuration: TimeInterval = 0.3 // 正常动画时长
        static let quickAnimationDuration: TimeInterval = 0.15 // 快速过渡动画时长
    }
    
    // MARK: - 单例（全局唯一，复用实例）
    private static let shared = RTToast()
    
    // MARK: - 子视图
    private let bgView = UIView()
    private let textLabel = UILabel()
    
    // MARK: - 约束引用
    private var centerXConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var maxWidthConstraint: NSLayoutConstraint?
    
    // MARK: - 状态变量
    private var showTimer: DispatchSourceTimer?
    private var isShowing = false
    private var currentAnimation: UIViewPropertyAnimator? // 控制动画状态，避免叠加
    
    // MARK: - 私有初始化
    private override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupInternalConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 1. 初始化UI
    private func setupUI() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        
        // 背景容器
        bgView.backgroundColor = UIColor.black.withAlphaComponent(Config.bgAlpha)
        bgView.layer.cornerRadius = Config.cornerRadius
        bgView.clipsToBounds = true
        bgView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bgView)
        
        // 文本标签
        textLabel.font = Config.font
        textLabel.textColor = Config.textColor
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        bgView.addSubview(textLabel)
    }
    
    // MARK: - 2. 内部约束（不依赖window）
    private func setupInternalConstraints() {
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: bgView.topAnchor, constant: Config.padding.top),
            textLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: Config.padding.left),
            textLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -Config.padding.right),
            textLabel.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -Config.padding.bottom),
            
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - 3. 外部约束（延迟到添加到window后）
    private func setupExternalConstraints() {
        guard let superview = superview else { return }
        
        centerXConstraint?.isActive = false
        bottomConstraint?.isActive = false
        maxWidthConstraint?.isActive = false
        
        centerXConstraint = centerXAnchor.constraint(equalTo: superview.centerXAnchor)
        bottomConstraint = bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -Config.bottomOffset)
        maxWidthConstraint = widthAnchor.constraint(lessThanOrEqualTo: superview.widthAnchor, multiplier: Config.maxWidthRatio)
        
        NSLayoutConstraint.activate([centerXConstraint!, bottomConstraint!, maxWidthConstraint!])
    }
    
    // MARK: - 4. 父视图变化时触发
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            setupExternalConstraints()
        }
    }
    
    // MARK: - 5. 动画工具方法（统一管理动画，避免叠加）
    private func runAnimation(duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        // 先停止当前正在执行的动画
        currentAnimation?.stopAnimation(true)
        currentAnimation = nil
        
        // 执行新动画
        currentAnimation = UIViewPropertyAnimator(duration: duration, curve: .easeInOut, animations: animations)
        currentAnimation?.addCompletion { [weak self] (position) in
            completion?(position == .end)
            self?.currentAnimation = nil
        }
        currentAnimation?.startAnimation()
    }
    
    // MARK: - 6. 显示动画（支持正常/快速模式）
    private func showAnimation(isQuickTransition: Bool = false) {
        let duration = isQuickTransition ? Config.quickAnimationDuration : Config.normalAnimationDuration
        
        runAnimation(duration: duration, animations: {
            self.transform = .identity
            self.alpha = 1
        }, completion: { [weak self] _ in
            self?.isShowing = true
        })
    }
    
    // MARK: - 7. 隐藏动画（支持正常/快速模式）
    private func hideAnimation(isQuickTransition: Bool = false, completion: (() -> Void)?) {
        let duration = isQuickTransition ? Config.quickAnimationDuration : Config.normalAnimationDuration
        
        runAnimation(duration: duration, animations: {
            self.transform = CGAffineTransform(translationX: 0, y: Config.bottomOffset)
            self.alpha = 0
        }, completion: { [weak self] _ in
            self?.isShowing = false
            self?.textLabel.text = nil // 重置文本
            if let completion = completion {
                completion()
            } else {
                self?.removeFromSuperview()
            }
        })
    }
    
    // MARK: - 8. 核心配置方法（复用实例，无缝更新）
    private func configure(text: String, duration: TimeInterval, isQuickTransition: Bool) {
        // 更新文本（无需重建视图）
        textLabel.text = text
        
        // 重置计时器
        showTimer?.cancel()
        
        // 添加到window（如果还没添加）
        if superview == nil {
            guard let keyWindow = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow }) else { return }
            keyWindow.addSubview(self)
        }
        
        // 执行显示动画（快速过渡模式下动画更短）
        showAnimation(isQuickTransition: isQuickTransition)
        
        // 自动消失计时器
        showTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        showTimer?.schedule(deadline: .now() + duration)
        showTimer?.setEventHandler(handler: {
            Self.dismiss(isQuickTransition: false)
        })
        showTimer?.resume()
    }
    
    // MARK: - 9. 公开类方法（外部调用入口）
    /// 显示Toast（重复调用时无缝过渡）
    class func show(_ text: String, duration: TimeInterval = Config.showDuration) {
        guard !text.isEmpty else { return }
        
        DispatchQueue.main.async {
            let shared = RTToast.shared
            if shared.isShowing {
                // 重复显示：快速隐藏旧文本，立即显示新文本（无缝衔接）
                shared.hideAnimation(isQuickTransition: true) {
                    shared.configure(text: text, duration: duration, isQuickTransition: true)
                }
            } else {
                // 首次显示：正常动画
                shared.configure(text: text, duration: duration, isQuickTransition: false)
            }
        }
    }
    
    /// 手动隐藏Toast
    class func dismiss(isQuickTransition: Bool = false) {
        DispatchQueue.main.async {
            let shared = RTToast.shared
            guard shared.isShowing else { return }
            
            shared.showTimer?.cancel()
            shared.hideAnimation(isQuickTransition: isQuickTransition) {
                shared.removeFromSuperview()
            }
        }
    }
}
