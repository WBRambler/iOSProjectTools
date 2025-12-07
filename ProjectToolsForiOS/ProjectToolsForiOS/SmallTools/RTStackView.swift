//
//  RTStackView.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/27.
//

import UIKit
import SnapKit

class DoubleButtonStackView: UIStackView {
    
    // MARK: - 公开属性
    /// 左侧按钮（可自定义标题/样式）
    let leftButton = UIButton(type: .system)
    /// 右侧按钮（可自定义标题/样式）
    let rightButton = UIButton(type: .system)
    
    // MARK: - 私有属性
    /// 中间分割线
    private let dividerView = UIView()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // MARK: - 核心配置
    private func commonInit() {
        // 1. StackView 基础配置
        axis = .horizontal          // 水平排列
        spacing = 5                 // 子视图间距0（分割线单独控制位置）
        alignment = .center         // 子视图垂直居中
        distribution = .fill        // 填充模式
        
        // 2. 分割线样式配置
        dividerView.backgroundColor = .lightGray // 分割线颜色（可自定义）
        
        // 3. 添加子视图到StackView
        addArrangedSubview(leftButton)
        addArrangedSubview(dividerView)
        addArrangedSubview(rightButton)
        
        // 4. 设置约束（核心逻辑）
        setupConstraints()
        
        // 5. 按钮默认样式（可外部自定义）
        setupDefaultButtonStyle()
    }
    
    // MARK: - 约束配置（SnapKit）
    private func setupConstraints() {
        // ========== 左侧按钮约束 ==========
        leftButton.snp.makeConstraints { make in
            make.width.equalTo(100)                  // 宽度固定200
            make.height.equalToSuperview()           // 高度与StackView一致
        }
        
        // ========== 右侧按钮约束 ==========
        rightButton.snp.makeConstraints { make in
            make.width.equalTo(100)                  // 宽度固定200
            make.height.equalToSuperview()           // 高度与StackView一致
        }
        
        // ========== 分割线约束 ==========
        dividerView.snp.makeConstraints { make in
            make.width.equalTo(1)                    // 宽度固定1
            make.height.equalToSuperview().multipliedBy(0.5) // 高度为StackView的一半
            make.centerY.equalToSuperview()          // 垂直居中
        }
        
    }
    
    // MARK: - 按钮默认样式（可外部重写）
    private func setupDefaultButtonStyle() {
        // 左侧按钮
        leftButton.setTitle("左侧按钮", for: .normal)
        leftButton.setTitleColor(.systemBlue, for: .normal)
        leftButton.backgroundColor = .systemGray6
        leftButton.layer.cornerRadius = 8
        leftButton.clipsToBounds = true
        
        // 右侧按钮
        rightButton.setTitle("右侧按钮", for: .normal)
        rightButton.setTitleColor(.systemBlue, for: .normal)
        rightButton.backgroundColor = .systemGray6
        rightButton.layer.cornerRadius = 8
        rightButton.clipsToBounds = true
    }
}

