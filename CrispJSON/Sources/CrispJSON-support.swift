//
//  CrispJSON-support.swift
//  CrispJSON Project
//
// Created by Terry Stillone on 30/09/2016.
// Copyright (c) 2016 Originware. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
///
/// ITraceable: Tracing of internal operations.
///

public protocol IJTraceable
{
    /// Tracing title (nil indicates tracing disabled).
    var traceTitle: String? { get set }

    /// Tracing indent level
    var indent:     Int   { get }
}

extension IJTraceable
{
    // Print a trace message to the console.
    public func trace(_ message : String)
    {
        guard let traceTitle = traceTitle else { return }

        let padding = String(repeating: " ", count: indent * 4)

        print("\(traceTitle) \(padding) \(message)")
    }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
///
/// IJContext: User state context to deliver state and operational control.
///

public protocol IJContext : IJTraceable
{
    var jtreeLevelTag: String { get }

    /// Turn tracing on.
    func traceOn(_ title: String?) -> IJContext

    /// Turn tracing off.
    func traceOff() -> IJContext

    /// Push a tree level.
    func pushLevel(_ tag : String) -> IJContext

    /// Pop a tree level.
    func popLevel() -> IJContext
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
///
/// JContext: User state context. Modify, extend, inherit as required.
///

public struct JContext : IJContext
{
    /// The current JTree level.
    public let jtreeLevel:    Int

    /// The current JTree level tag.
    public let jtreeLevelTag: String

    /// The tracing enabler with tracing title.
    public var traceTitle:    String? = nil

    /// The tracing indent level.
    public var indent :       Int { return jtreeLevel
    }

    public init()
    {
        self.jtreeLevel = 0
        self.jtreeLevelTag = ""
    }

    /// initialise with JTree level and trace enabling.
    public init(jtreeLevel: Int, levelTag: String, traceTitle : String? = nil)
    {
        self.jtreeLevel = jtreeLevel
        self.traceTitle = traceTitle
        self.jtreeLevelTag = levelTag
    }

    public func traceOn(_ title: String? = "trace >>") -> IJContext
    {
        return JContext(jtreeLevel: jtreeLevel, levelTag: jtreeLevelTag, traceTitle : title ?? "trace >>")
    }

    public func traceOff() -> IJContext
    {
        return JContext(jtreeLevel: jtreeLevel, levelTag: jtreeLevelTag, traceTitle : nil)
    }

    public func pushLevel(_ tag : String) -> IJContext
    {
        return JContext(jtreeLevel: jtreeLevel + 1, levelTag: tag, traceTitle : traceTitle)
    }

    public func popLevel() -> IJContext
    {
        return self
    }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
///
/// JContextWithPath: User state context that includes the JSON path of the JTree.
///

public struct JContextWithPath : IJContext
{
    /// The current JTree level.
    public let jtreeLevel:    Int

    /// The current JTree level tag.
    public let jtreeLevelTag: String

    /// The tracing enabler with tracing title.
    public var traceTitle:    String? = nil

    /// The tracing indent level.
    public var indent :       Int { return jtreeLevel
    }

    public init()
    {
        self.jtreeLevel = 0
        self.jtreeLevelTag = ""
    }

    /// initialise with JTree level and trace enabling.
    public init(jtreeLevel: Int, levelTag: String, traceTitle : String? = nil)
    {
        self.jtreeLevel = jtreeLevel
        self.traceTitle = traceTitle
        self.jtreeLevelTag = levelTag
    }

    public func traceOn(_ title: String? = "trace >>") -> IJContext
    {
        return JContextWithPath(jtreeLevel: jtreeLevel, levelTag: jtreeLevelTag, traceTitle : title ?? "trace >>")
    }

    public func traceOff() -> IJContext
    {
        return JContextWithPath(jtreeLevel: jtreeLevel, levelTag: jtreeLevelTag, traceTitle : nil)
    }

    public func pushLevel(_ tag : String) -> IJContext
    {
        let subTag = jtreeLevelTag.characters.count > 1 ? jtreeLevelTag + "/" + tag : "/" + tag

        return JContextWithPath(jtreeLevel: jtreeLevel + 1, levelTag: subTag, traceTitle : traceTitle)
    }

    public func popLevel() -> IJContext
    {
        return self
    }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
///
/// eJDataType: The data types of the JSON JTree content.
///

public enum eJDataType : Int
{
    case null    = 0x1
    case boolean = 0x2
    case number  = 0x4
    case string  = 0x8
    case array   = 0x10
    case object  = 0x20
    case unknown = 0x40

    internal static let BoolTypeID   = CFBooleanGetTypeID()
    internal static let StringTypeID = CFStringGetTypeID()
    internal static let NumberTypeID = CFNumberGetTypeID()
    internal static let ArrayTypeID  = CFArrayGetTypeID()
    internal static let NullTypeID   = CFNullGetTypeID()
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
///
/// JDataTypeOptionSet: The set of data types of the JSON JTree content.
///

public struct JDataTypeOptionSet : OptionSet
{
    public static let oNull : JDataTypeOptionSet     =  JDataTypeOptionSet(rawValue : eJDataType.null.rawValue)
    public static let oBoolean :  JDataTypeOptionSet =  JDataTypeOptionSet(rawValue : eJDataType.boolean.rawValue)
    public static let oNumber :   JDataTypeOptionSet =  JDataTypeOptionSet(rawValue : eJDataType.number.rawValue)
    public static let oString :   JDataTypeOptionSet =  JDataTypeOptionSet(rawValue : eJDataType.string.rawValue)
    public static let oArray :    JDataTypeOptionSet =  JDataTypeOptionSet(rawValue : eJDataType.array.rawValue)
    public static let oObject:    JDataTypeOptionSet =  JDataTypeOptionSet(rawValue : eJDataType.object.rawValue)
    public static let oUnnown :   JDataTypeOptionSet =  JDataTypeOptionSet(rawValue : eJDataType.unknown.rawValue)
    public static let AllValues : JDataTypeOptionSet = [oNull, oBoolean, oNumber, oString]
    public static let All :       JDataTypeOptionSet = [oNull, oBoolean, oNumber, oString, oArray, oObject, oUnnown]

    public let rawValue : Int

    public init(rawValue: Int)
    {
        self.rawValue = rawValue
    }

    public init(_ dataType: eJDataType)
    {
        self.rawValue = dataType.rawValue
    }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
///
/// JValue: The JSON value extraction operator that extracts on JTrees.
///

public enum JValue<T>
{
    /// Extract the value of the JSON JTree content.
    case value

    /// Extract the value of the JSON JTree content matching the given data type.
    case valueWithType(eJDataType)

    /// Extract a custom value from the JTree content, using the given extraction closure.
    case customValue((CrispJSON.JTree) -> T?)
}


//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
///
/// JMatch: Regex JSON name matching.
///
public enum JMatch
{
    /// Match a case-dependant Regular Expression.
    case regex(String)

    /// Match a case-independant Regular Expression.
    case regexAllCase(String)

    /// Match using a String compare operation.
    case compare(String, String.CompareOptions)
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
//
// Operators: Manipulators operate on the operations of eCJValue and eCJFor to parse-extract information from a JTree.
//

precedencegroup ManipulatorPrecedence {
    higherThan: MultiplicationPrecedence
    associativity: left
}

infix operator ->> : ManipulatorPrecedence

/// JTree manipulator to parse-evaluate a eCJValue operation.
/// - Returns: The JSON parse-evaluation result.
public func ->><T>(jtree: CrispJSON.JTree?, op: JValue<T>) -> T?
{
    guard let jtree = jtree else { return nil }

    return jtree.perform(op: op)
}

public func ->>(jtree: CrispJSON.JTree?, name: String) -> CrispJSON.JTree?
{
    guard let jtree = jtree else { return nil }

    return jtree[name]
}

public func ->>(jtree: CrispJSON.JTree?, match: JMatch) -> CrispJSON.JTree?
{
    guard let jtree = jtree else { return nil }

    return jtree[match]
}

