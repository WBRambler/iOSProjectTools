//
//  RTBaseTableViewCell.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/11/28.
//

import UIKit

import UIKit

class BaseTableViewCell: UITableViewCell {
    // MARK: - 类属性（子类可重写）
    /// 复用标识（默认类名）
    class var reuseIdentifier: String {
        return String(describing: self) 
    }
    
    /// Cell样式（子类可重写，默认.default）
    class var cellStyle: UITableViewCell.CellStyle {
        return .default
    }
    
    // 私有泛型方法：处理类型转换
    class func cell(with tableView: UITableView) -> Self {
        // 注意：必须用不带 for:indexPath 的 dequeue 方法！
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        
        // 若复用池无Cell，手动init创建
        if let cell = cell as? Self {
            return cell
        } else {
            // 调用子类的init(style:reuseIdentifier:)
            let newCell = self.init(style: cellStyle, reuseIdentifier: reuseIdentifier)
          return newCell
        }
    }
    
    // MARK: - 初始化
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("非注册方式不支持XIB，请勿实现init(coder:)")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
