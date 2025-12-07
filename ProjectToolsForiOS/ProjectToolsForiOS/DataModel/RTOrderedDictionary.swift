//
//  RTOrderedDictionry.swift
//  ProjectToolsForiOS
//
//  Created by WuBo on 2025/12/7.
//

import Foundation

class RTOrderedDictionary<Key: Hashable, Value>: ExpressibleByDictionaryLiteral
{
    /// 维护键的插入顺序
    private var keys: [Key]
    /// 存储键值对（保证查找效率）
    private var values: [Key: Value]

    init() {
        keys = []
        values = [:]
    }

    required convenience init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(orderedPairs: elements)
    }

    init(dictionary: [Key: Value]) {
        keys = dictionary.keys.map { $0 }
        values = dictionary
    }

    init(orderedPairs: [(Key, Value)]) {
        keys = []
        values = [:]
        orderedPairs.forEach { key, value in
            self[key] = value
        }
    }

    // MARK: - 基础属性
    /// 元素数量
    var count: Int { keys.count }

    /// 是否为空
    var isEmpty: Bool { keys.isEmpty }

    /// 有序的键数组
    var allKeys: [Key] { keys }

    /// 有序的值数组
    var allValues: [Value] { keys.compactMap { values[$0] } }

    /// 有序的键值对数组
    var allPairs: [(key: Key, value: Value)] {
        keys.compactMap { key in
            guard let value = values[key] else { return nil }
            return (key, value)
        }
    }

    /// 下标访问（支持读写）
    subscript(key: Key) -> Value? {
        get { values[key] }
        set {
            if let newValue = newValue {
                // 存在则更新值，不存在则添加键和值
                if !values.keys.contains(key) {
                    keys.append(key)
                }
                values[key] = newValue
            } else {
                // nil表示删除
                removeValue(forKey: key)
            }
        }
    }

    /// 通过索引访问键值对
    subscript(index index: Int) -> (key: Key, value: Value)? {
        guard index >= 0, index < keys.count else { return nil }
        let key = keys[index]
        guard let value = values[key] else { return nil }
        return (key, value)
    }

    /// 添加/更新键值对
    func setValue(_ value: Value, forKey key: Key) {
        self[key] = value
    }

    /// 根据键删除值
    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        guard let removedValue = values.removeValue(forKey: key) else {
            return nil
        }
        keys.removeAll { $0 == key }
        return removedValue
    }

    /// 根据索引删除值
    @discardableResult
    func removeValue(at index: Int) -> (key: Key, value: Value)? {
        guard index >= 0, index < keys.count else { return nil }
        let key = keys.remove(at: index)
        guard let value = values.removeValue(forKey: key) else { return nil }
        return (key, value)
    }

    /// 移除所有元素
    func removeAll(keepingCapacity: Bool = false) {
        keys.removeAll(keepingCapacity: keepingCapacity)
        values.removeAll(keepingCapacity: keepingCapacity)
    }

    /// 检查是否包含指定键
    func containsKey(_ key: Key) -> Bool {
        values.keys.contains(key)
    }

    /// 检查是否包含指定值（通过Equatable判断）
    func containsValue(_ value: Value) -> Bool where Value: Equatable {
        allValues.contains(value)
    }

    /// 遍历有序键值对
    func forEach(_ body: (Key, Value) throws -> Void) rethrows {
        try keys.forEach { key in
            guard let value = values[key] else { return }
            try body(key, value)
        }
    }
}

// MARK: - 遵循Collection协议（支持下标、遍历、切片等）
extension RTOrderedDictionary: Collection {
    typealias Index = Int
    typealias Element = (key: Key, value: Value)

    /// 起始索引
    var startIndex: Int { 0 }

    /// 结束索引
    var endIndex: Int { keys.count }

    /// 索引偏移
    func index(after i: Int) -> Int {
        i + 1
    }

    /// 集合元素访问
    subscript(position: Int) -> Element {
        guard position >= 0, position < keys.count else {
            fatalError("Index out of bounds")
        }
        let key = keys[position]
        guard let value = values[key] else {
            fatalError("Key \(key) has no corresponding value")
        }
        return (key, value)
    }
}

// MARK: - 自定义调试描述
extension RTOrderedDictionary: CustomDebugStringConvertible {
    var debugDescription: String {
        let pairs = allPairs.map { "\($0.key): \($0.value)" }.joined(
            separator: ", "
        )
        return "RTOrderedDictionary([\(pairs)])"
    }
}
