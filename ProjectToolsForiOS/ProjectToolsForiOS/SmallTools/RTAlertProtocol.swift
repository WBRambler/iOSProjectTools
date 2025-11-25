//
//  RTAlertProtocol.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/25.
//

import UIKit

// MARK: - 容器 VC 协议（View 触发隐藏弹窗）
protocol RTAlertContainerDelegate: AnyObject {
    func dismissAlert(completion: (() -> Void)?)
}

// MARK: - 内容 View 协议（提供配置能力）
protocol RTAlertContentViewProtocol: UIView {
    var preferredSize: CGSize { get }
    var title: String? { get set }
    var message: String? { get set }
    func addAction(_ action: RTAlertAction)
    func bind(containerDelegate: RTAlertContainerDelegate)
}


class RTAlertAction: NSObject {
    enum Style {
        case cancel        // 取消样式（蓝色文字）
        case `default`     // 默认样式（黑色文字）
        case destructive   // 危险样式（红色文字）
    }
    
    let title: String?
    let style: Style
    let handler: ((RTAlertAction) -> Void)?
    
    init(title: String?, style: Style, handler: ((RTAlertAction) -> Void)?) {
        self.title = title
        self.style = style
        self.handler = handler
        super.init()
    }
}
