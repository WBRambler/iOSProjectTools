import UIKit
import SnapKit

class RTAlertInputView: UIView, RTAlertContentViewProtocol, UITextViewDelegate {
    
    // MARK: - 协议属性
    var preferredSize: CGSize {
        layoutIfNeeded()
        return intrinsicContentSize
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title?.isEmpty ?? true
            updateSubviewsSpacing()
            layoutIfNeeded()
        }
    }
    
    // 复用 message 作为输入框占位提示
    var message: String? {
        didSet {
            placeholderLabel.text = message
            placeholderLabel.isHidden = !(textView.text.isEmpty && !(message?.isEmpty ?? true))
        }
    }
    
    // MARK: - 公开属性
    var inputText: String? {
        return textView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // 可自定义输入框最大高度（默认300pt，容纳更多行）
    var maxInputHeight: CGFloat = 300 {
        didSet {
            updateTextViewHeight()
        }
    }
    
    // MARK: - 私有属性
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let actionStackView = UIStackView()
    private var actions = [RTAlertAction]()
    private weak var containerDelegate: RTAlertContainerDelegate?
    
    private var textViewHeightConstraint: Constraint!
    private let minInputHeight: CGFloat = 44
    private let maxWidth: CGFloat = UIScreen.main.bounds.width - 40
    // 输入框固定宽度（确保计算高度时宽度不变）
    private var textViewFixedWidth: CGFloat {
        return maxWidth - 40 // 父视图左右内边距20*2
    }
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 核心布局（确保父视图能感知高度变化）
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        let height = actionStackView.frame.maxY + 20
        return CGSize(width: maxWidth, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 布局变化时强制更新输入框高度
        updateTextViewHeight()
    }
}

// MARK: - 核心配置
private extension RTAlertInputView {
    func commonInit() {
        backgroundColor = .white
        setupSelfConstraints()
        setupSubviews()
        setupConstraints()
        setupNotifications()
        setupTextViewDelegate()
        
        // 初始触发一次高度计算
        DispatchQueue.main.async {
            self.updateTextViewHeight()
        }
    }
    
    // 自身宽度约束（固定最大宽度，避免宽度波动）
    func setupSelfConstraints() {
        snp.makeConstraints { make in
            make.width.equalTo(maxWidth)
        }
    }
    
    func setupSubviews() {
        // 标题
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        addSubview(titleLabel)
        
        // 输入框（关键优化：简化配置，确保换行正确）
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.masksToBounds = true
        textView.returnKeyType = .done
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
//        textView.textInputMode = .byWordWrapping // 强制换行
        textView.isScrollEnabled = false // 初始禁用滚动，必须！
        addSubview(textView)
        
        // 占位符
        placeholderLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        placeholderLabel.textColor = .lightGray
        placeholderLabel.numberOfLines = 0
        placeholderLabel.lineBreakMode = .byWordWrapping
        textView.addSubview(placeholderLabel)
        
        // 按钮容器
        actionStackView.axis = .horizontal
        actionStackView.spacing = 12
        actionStackView.distribution = .fillEqually
        actionStackView.alignment = .center
        addSubview(actionStackView)
        
        setupLineSpacing(2)
    }
    private func setupLineSpacing(_ spacing: CGFloat) {
        
          // 1. 创建段落样式
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.lineSpacing = spacing // 行间距（关键属性）
          paragraphStyle.lineBreakMode = .byWordWrapping // 换行模式（可选，默认也可）
        
          // 2. 配置输入属性（确保新增文本应用行间距）
          textView.typingAttributes = [
              .paragraphStyle: paragraphStyle,
              .font: textView.font ?? UIFont.systemFont(ofSize: 14), // 同步字体（避免输入时字体变化）
              .foregroundColor: UIColor.black, // 文本颜色（可选）
              
          ]
          
          // 3. 同步已有文本的行间距（如果文本已存在）
          if let text = textView.text, !text.isEmpty {
              let attributedText = NSMutableAttributedString(string: text)
              attributedText.addAttribute(
                  .paragraphStyle,
                  value: paragraphStyle,
                  range: NSRange(location: 0, length: text.count)
              )
              textView.attributedText = attributedText
             
          }
      }
    
    func setupConstraints() {
        // 标题
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // 输入框（关键：固定宽度，高度约束动态更新）
        textView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.width.equalTo(textViewFixedWidth) // 固定宽度，确保高度计算准确
            make.height.greaterThanOrEqualTo(minInputHeight)
            make.height.lessThanOrEqualTo(maxInputHeight)
            // 保存高度约束，用于动态更新
            textViewHeightConstraint = make.height.equalTo(minInputHeight).constraint
        }
        
        // 占位符（与输入框文本位置完全一致）
        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(12)
        }
        
        // 按钮容器
        actionStackView.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(44)
            make.width.equalTo(textViewFixedWidth)
        }
    }
    
    // 动态调整子视图间距（标题隐藏时）
    func updateSubviewsSpacing() {
        let topOffset = title?.isEmpty ?? true ? 20 : 16
        textView.snp.updateConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(topOffset)
        }
    }
    
    func setupNotifications() {
        // 监听文本变化，实时更新高度
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewTextDidChange),
            name: UITextView.textDidChangeNotification,
            object: textView
        )
    }
    
    func setupTextViewDelegate() {
        textView.delegate = self
    }
}

// MARK: - 事件处理
@objc private extension RTAlertInputView {
    func textViewTextDidChange() {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateTextViewHeight() // 实时更新高度
    }
}

// MARK: - 核心修复：文本高度计算（用 sizeThatFits 替代复杂逻辑）
private extension RTAlertInputView {
    func updateTextViewHeight() {
        // 1. 确保输入框宽度已确定
        guard textViewFixedWidth > 0 else { return }
        
        // 2. 计算文本需要的实际高度（关键：用 sizeThatFits 精准计算）
        // 宽度固定为 textViewFixedWidth，高度设为最大可能值
        let textSize = textView.sizeThatFits(CGSize(
            width: textViewFixedWidth - textView.textContainerInset.left - textView.textContainerInset.right,
            height: CGFloat.greatestFiniteMagnitude
        ))
        
        // 3. 计算最终高度（包含内边距）
        var targetHeight = textSize.height + textView.textContainerInset.top + textView.textContainerInset.bottom
        
        // 4. 限制高度范围
        targetHeight = max(minInputHeight, min(targetHeight, maxInputHeight))
        
        // 5. 动态控制滚动状态
        textView.isScrollEnabled = targetHeight >= maxInputHeight
        
        // 6. 更新约束并强制刷新布局（关键：触发父视图高度更新）
        if textViewHeightConstraint.layoutConstraints.first?.constant != targetHeight {
            textViewHeightConstraint.update(offset: targetHeight)
            
            // 强制刷新自身和父视图布局
            layoutIfNeeded()
            invalidateIntrinsicContentSize()
            superview?.layoutIfNeeded() // 通知容器VC更新高度
        }
    }
}

// MARK: - UITextViewDelegate
extension RTAlertInputView {
    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    // 点击输入框时自动聚焦光标
    func textViewDidBeginEditing(_ textView: UITextView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            textView.scrollRangeToVisible(NSRange(location: textView.selectedRange.location, length: 0))
        }
    }
}

// MARK: - RTAlertContentViewProtocol 实现
extension RTAlertInputView {
    func addAction(_ action: RTAlertAction) {
        actions.append(action)
        let button = createActionButton(with: action)
        actionStackView.addArrangedSubview(button)
        actionStackView.distribution = actions.count == 1 ? .fill : .fillEqually
        layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    func bind(containerDelegate: RTAlertContainerDelegate) {
        self.containerDelegate = containerDelegate
    }
    
    private func createActionButton(with action: RTAlertAction) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.tag = actions.count - 1
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        switch action.style {
        case .cancel:
            button.setTitleColor(.systemBlue, for: .normal)
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        case .default:
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = .systemGray6
        case .destructive:
            button.setTitleColor(.systemRed, for: .normal)
            button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        }
        
        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        textView.resignFirstResponder()
        let action = actions[sender.tag]
        action.handler?(action)
        containerDelegate?.dismissAlert(completion: nil)
    }
}
