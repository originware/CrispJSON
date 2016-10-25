//
//  CrispJSON.swift
//  CrispJSON Project
//
//  Created by Terry Stillone on 11/09/2016.
//  Copyright © 2016 Originware. All rights reserved.
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
/// CrispJSON: The Crisp JSON Namespace.
///
public struct CrispJSON
{
    //<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    ///
    /// JDataSource: The Crisp JSON data Source.
    ///
    open class JDataSource
    {
        /// The Data Source types.
        public enum eDataSourceType
        {
            /// Non-streaming Data Source.
            case eNonStreaming(Data)

            /// Streaming Data Source,
            case eStreaming(InputStream)
        }

        /// Indicate if the given JSON as Data type is valid.
        /// Parameter json: The JSON as Data to validate.
        public static func isValidJSON(data: Any) -> Bool { return JSONSerialization.isValidJSONObject(data) }

        /// Indicate if the given JSON as a String is valid.
        /// Parameter json: The JSON as a String to validate.
        public static func isValidJSON(json: String) -> Bool
        {
            guard let data = json.data(using: String.Encoding.utf8) else { return false }

            return JSONSerialization.isValidJSONObject(data)
        }

        /// Indicate the validity of the JSON in the Data Source
        open var isValidJSON : Bool
        {
            do
            {
                let jtree = try deserialize()
                
                return JSONSerialization.isValidJSONObject(jtree.content)
            }
            catch
            {
                return false
            }
        }
        
        /// The raw JSON data (of type Data).
        open let dataSource: eDataSourceType

        /// Initialise the JSON parser from a non-streaming raw data-source.
        /// Parameter jsonAsRawData: The non-streaming JSON data source.
        public init(_ jsonAsRawData: Data)
        {
            self.dataSource = .eNonStreaming(jsonAsRawData)
        }

        /// Initialise the JSON parser from a non-streaming String data-source.
        /// Parameter jsonAsString: The non-streaming JSON data source.
        public convenience init?(_ jsonAsString: String)
        {
            guard let jsonAsData = jsonAsString.data(using: String.Encoding.utf8) else { return nil }

            self.init(jsonAsData)
        }

        /// Initialise the JSON parser from a non-streaming Dictionary ([String : Any]) data-source.
        /// Parameter jsonAsDict: The non-streaming JSON dictionary data source.
        public convenience init?(_ jsonAsDict: [String: Any])
        {
            guard let jsonAsData = try? JSONSerialization.data(withJSONObject: jsonAsDict, options: JSONSerialization.WritingOptions.prettyPrinted) else { return nil }

            self.init(jsonAsData)
        }

        /// Initialise the JSON parser from a streaming Stream data-source.
        /// Parameter jsonAsStream: The JSON streaming data source.
         public init(_ jsonAsStream: InputStream)
         {
             self.dataSource = .eStreaming(jsonAsStream)
         }

        /// Deserialise all the JSON from the data source and convert to JTree representation, throw on error.
        /// - Parameter context: The user context.
        /// - Parameter options: The JSONSerialization reading options.
        /// - Returns: JTree representation of content.
        /// - Throws: On errors raised during JSON deserialisation.
        open func deserialize(_ context : IJContext = JContext(), options opt: JSONSerialization.ReadingOptions = .allowFragments) throws -> CrispJSON.JTree
        {
            switch dataSource
            {
                case .eNonStreaming(let data):

                    let object = try JSONSerialization.jsonObject(with: data, options: opt)

                    return CrispJSON.JTree(object, context: context.pushLevel(""))

                case .eStreaming(let stream):

                    if stream.streamStatus == .notOpen
                    {
                        stream.open()
                    }

                    let object = try JSONSerialization.jsonObject(with: stream, options: opt)

                    return CrispJSON.JTree(object, context: context.pushLevel(""))
            }
        }

        /// Deserialise all the JSON from the data source and convert to String representation, throw on error.
        /// - Parameter context: The user context.
        /// - Parameter options: The JSONSerialization reading options.
        /// - Returns: String representation of content.
        /// - Throws: On errors raised during JSON deserialisation.
        open func deserializeToString(_ context : IJContext, options opt: JSONSerialization.ReadingOptions = .allowFragments) throws -> String?
        {
            return try deserialize(context).json
        }
    }

    //<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    ///
    /// JTree: The raw JSON content, in the same representation that JSONSerialization employs.
    ///

    public struct JTree
    {
        /// The raw JSON content in the JSONSerialization representation.
        public var content: Any             { return m_content }

        /// JSON context, to encsulate user state and information.
        public var context: IJContext

        /// Object sorting func.
        public var sortFunc : ((String, String) -> Bool)? = nil

        /// The backing variable for the content property.
        fileprivate var m_content: Any

        /// Initialise with the JSONSerialization content representation.
        /// - Parameter content: The raw JSON content in JSONSerialization form.
        /// - Parameter trace : Parsing trace enabler.
        public init(_ content: Any, context: IJContext = JContext())
        {
            self.m_content = content
            self.context = context
        }
    }

    //<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    ///
    /// CrispJSON: The Crisp JSON parser.
    ///
    open class JParser
    {
        /// The JSON data source.
        public let source : CrispJSON.JDataSource

        /// The user context for encapsulating user state and information.
        public var context : IJContext

        /// The pretty printed and backslash escaped JSON text.
        open var escapedJSON : String? { return m_jtree?.escapedJSON }

        /// The pretty printed JSON.
        open var json : String? { return m_jtree?.json }

        /// The parsed-processed JSON as a JTree.
        private var m_jtree: JTree? = nil

        /// Initialise the JSON parser from a non-streaming raw data-source.
        /// Parameter jsonAsRawData: The non-streaming JSON data source.
        /// Parameter context: The user context, currently used for tracing.
        public init(_ source: JDataSource, context : IJContext = JContext())
        {
            self.source = source
            self.context = context
        }

        /// Client parsing of the JSON by a given parsing closure.
        /// - Parameter withParseAction: The parsing handler.
        /// - Returns: The parsing result, nil on failure (there is no indicator of error cause).
        open func parse<T>(_ withParseAction: (JTree) -> T) -> T?
        {
            if m_jtree == nil
            {
                do
                {
                    m_jtree = try source.deserialize(context)
                }
                        catch let error
                {
                    context.trace("[data source deserialize] error: \(error)")
                    return nil
                }
            }

            guard let jtree = m_jtree else { return nil }

            return withParseAction(jtree)
        }

        /// Client parsing of the JSON by a given parsing closure.
        /// - Parameter withParseAction: The parsing handler.
        /// - Returns: An indicator of success (when nil) or failure (as the Error).
        open func parseGivingError(_ withParseAction: (JTree) -> Void) -> Error?
        {
            if m_jtree == nil
            {
                do
                {
                    m_jtree = try source.deserialize(context)
                }
                        catch let error
                {
                    context.trace("[data source deserialize] error: \(error)")
                    return error
                }
            }

            guard let jtree = m_jtree else { return nil }

            withParseAction(jtree)

            return nil
        }

        /// Client parsing of the JSON by a given parsing closure, throw on Error
        /// - Parameter withParseAction: The parsing handler.
        /// - Returns: The parsing result.
        /// - Throws: On errors thrown during preprocessing or withParseAction parsing.
        open func parseThrows<T>(_ withParseAction: (JTree) throws -> T) throws -> T
        {
            if m_jtree == nil
            {
                m_jtree = try source.deserialize(context)
            }

            guard let jtree = m_jtree
            else {
                let errorDict = [NSLocalizedDescriptionKey : "CrispJSON: Could not deserialise JSON"]

                throw NSError(domain: "CrispJSON", code: 0, userInfo: errorDict)
            }

            return try withParseAction(jtree)
        }
    }
}


//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
//
// JTree JSON representations.
//

extension CrispJSON.JTree // JSON content presentation.
{
    /// The content as non-escaped JSON text pretty printed.
    public var json : String
    {
        // Get JSONSerialization to encode to raw JSON.
        guard let jsonData = try? JSONSerialization.data(withJSONObject: m_content as Any, options: JSONSerialization.WritingOptions.prettyPrinted)
        else { return "Invalid JSON" }

        // Encode the raw JSON data as UTF8.
        guard let string = String(data: jsonData, encoding: String.Encoding.utf8) else { return "Invalid UTF8 String" }

        return string
    }

    /// The content as escaped JSON text pretty printed.
    public var escapedJSON : String?
    {
        // Get JSONSerialization to encode to raw JSON.
        guard let jsonData = try? JSONSerialization.data(withJSONObject: m_content as Any, options: JSONSerialization.WritingOptions.prettyPrinted)
        else { return nil }

        // Encode the raw JSON data as UTF8.
        guard let string = String(data: jsonData, encoding: String.Encoding.utf8) else { return nil }

        return string
    }
}

extension CrispJSON.JTree // tracing support
{
    /// Enable parsing tracing.
    public func traceOn(_ title : String? = "trace >>") -> CrispJSON.JTree
    { return CrispJSON.JTree(content, context: context.traceOn(title)) }

    /// Disable parsing tracing.
    public func traceOff() -> CrispJSON.JTree
    { return CrispJSON.JTree(content, context: context.traceOff()) }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
//
// JTree JSON data typing.
//

extension CrispJSON.JTree
{
    /// Get the content data type of the given data.
    public static func getDataType(_ data : Any) -> eJDataType
    {
        return CrispJSON.JTree(data).dataType
    }
    
    /// Get the content data type.
    public var dataType : eJDataType
    {
        switch m_content
        {
            case let nsNumber as NSNumber:

                switch CFGetTypeID(nsNumber)
                {
                    case eJDataType.BoolTypeID:     return .boolean
                    case eJDataType.StringTypeID:   return .string
                    case eJDataType.NumberTypeID:   return .number
                    case eJDataType.ArrayTypeID:    return .array
                    case eJDataType.NullTypeID:     return .null

                    default:                        return .unknown
                }

            case is String:                         return .string
            case is Array<Any>:                     return .array
            case is Dictionary<String, Any>:        return .object
            case is CFNull:                         return .null
            default:                                return .unknown
        }
    }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
//
// JTree value traversal.
//

extension CrispJSON.JTree
{
    /// Perform an eCJValue<T> operation on the content.
    /// - Parameter op: The operation to be performed on the content.
    /// - Returns: The operation result.
    public func perform<T>(op: JValue<T>) -> T?
    {
        switch op
        {
        case .value:

            // Cast the raw JSON to type T.
            guard let value = content as? T
            else {
                context.trace("[parse<\(T.self)>.value] => content type mismatch, wanted(\(T.self)).")
                return nil
            }

            context.trace("[parse<\(T.self)>.value] => \(value)")

            return value

        case .valueWithType(let wantedDataType):

            guard dataType == wantedDataType else { return nil }
            guard let value = content as? T
            else {
                context.trace("[parse<\(T.self)>.valueWithType(\(wantedDataType))] => content type mismatch, got(\(type(of: content))) wanted(\(T.self)).")
                return nil
            }

            context.trace("[parse<\(T.self)>.valueWithType(\(wantedDataType))] => \(value)")

            return value

        case .customValue(let extractFunc):

            // Cast the raw data to type T.
            let value = extractFunc(self)

            context.trace("[parse<\(T.self)>.customValue] => \(value)")

            return value
        }
    }

    /// Iterate through the array, passing the array values to a parsing action. If the content is not an array, nothing is done.
    /// - Parameter name: The array name.
    /// - Parameter parseAction: The action to pass the array elements to for client parsing.
    public func forArray( _ parseAction: @escaping (CrispJSON.JTree) -> Void)
    {
        guard let array = content as? Array<Any> else { return }

        context.trace("[forArray]")

        for entry in array
        {
            parseAction(CrispJSON.JTree(entry, context : context.pushLevel("array")))
        }
    }

    /// Iterate through the array, passing the array values to a parsing action. If the content is not an array, nothing is done. Throws exceptions.
    /// - Parameter parseAction: The action to pass the array elements to for client parsing.
    /// - Throws: On errors thrown by the parseAction closure.
    public func forArrayThrows( _ parseAction: @escaping (CrispJSON.JTree) throws -> Void) rethrows
    {
        guard let array = content as? Array<Any> else { return }

        context.trace("[forArrayThrows]")

        for entry in array
        {
            try parseAction(CrispJSON.JTree(entry, context : context.pushLevel("array")))
        }
    }

    /// Iterate through the objects values (dictionary values), passing the names and values to the parsing action.
    /// - Parameter parseAction: The action to that is executed for each object entry.
    public func forObjectValues(_ parseAction: @escaping (String, CrispJSON.JTree) -> Void)
    {
        guard let dictionary = content as? Dictionary<String, Any> else { return }

        var gaveTrace = false

        if let sortFunc = sortFunc
        {
            let names = dictionary.keys.sorted(by: sortFunc)

            for name in names
            {
                context.trace("[forObjectValues][\(name)]"); gaveTrace = true

                parseAction(name, CrispJSON.JTree(dictionary[name], context : context.pushLevel(name)))
            }
        }
        else
        {
            for (name, value) in dictionary
            {
                context.trace("[forObjectValues][\(name)]"); gaveTrace = true

                parseAction(name, CrispJSON.JTree(value, context : context.pushLevel(name)))
            }
        }

        if !gaveTrace
        {
            context.trace("[forObjectValues]")
        }
    }

    /// Iterate through the objects values (dictionary values), passing the names and values to the parsing action. Throws exceptions.
    /// - Parameter parseAction:  The action to that is executed for each object entry.
    /// - Throws: On errors thrown by the parseAction closure.
    public func forObjectValuesThrows(_ parseAction: @escaping (String, CrispJSON.JTree) throws -> Void) rethrows
    {
        guard let dictionary = content as? Dictionary<String, Any> else { return }

        var gaveTrace = false

        context.trace("[forObjectValuesThrows]")

        if let sortFunc = sortFunc
        {
            let names = dictionary.keys.sorted(by: sortFunc)

            for name in names
            {
                context.trace("[forObjectValuesThrows][\(name)]"); gaveTrace = true

                try parseAction(name, CrispJSON.JTree(dictionary[name], context : context.pushLevel(name)))
            }
        }
        else
        {
            for (name, value) in dictionary
            {
                context.trace("[forObjectValuesThrows][\(name)]"); gaveTrace = true

                try parseAction(name, CrispJSON.JTree(value, context : context.pushLevel(name)))
            }
        }

        if !gaveTrace
        {
            context.trace("[forObjectValuesThrows]")
        }
    }

    /// Iterate through all JSON objects, passing objects that match matchDataTypes to the given closure.
    /// - Parameter matchingDataTypes: The OptionSet that indicates which data types to pass to the parseAction.
    /// - Parameter parseAction: The action to pass the primitive names and values.
    public func forAll(matchingDataTypes: JDataTypeOptionSet, _ parseAction: @escaping (String?, CrispJSON.JTree) -> Void)
    {
        if matchingDataTypes.contains(JDataTypeOptionSet(dataType))
        {
            parseAction(context.jtreeLevelTag, self)
        }

        switch m_content
        {
            case let contentAsArray as Array<Any>:

                for entry in contentAsArray
                {
                    CrispJSON.JTree(entry, context : context.pushLevel("array")).forAll(matchingDataTypes: matchingDataTypes, parseAction)
                }

            case let contentAsDict as [String : Any]:

                for (name, value) in contentAsDict
                {
                    CrispJSON.JTree(value, context : context.pushLevel(name)).forAll(matchingDataTypes: matchingDataTypes, parseAction)
                }

            default: break
        }
    }

    /// Iterate through all JSON objects, passing objects that match matchDataTypes to the given closure. Throws exceptions.
    /// - Parameter matchingDataTypes: The OptionSet that indicates which data types to pass to the parseAction.
    /// - Parameter parseAction: The action to pass the primitive names and values.
    /// - Throws: On errors thrown by the parseAction closure.
    public func forAllThrows(matchingDataTypes: JDataTypeOptionSet, _ parseAction: @escaping (String?, CrispJSON.JTree) throws -> Void) rethrows
    {
        if matchingDataTypes.contains(JDataTypeOptionSet(dataType))
        {
            try parseAction(context.jtreeLevelTag, self)
        }

        switch m_content
        {
            case let contentAsArray as Array<Any>:

                for entry in contentAsArray
                {
                    try CrispJSON.JTree(entry, context : context.pushLevel("array")).forAllThrows(matchingDataTypes: matchingDataTypes, parseAction)
                }

            case let contentAsDict as [String : Any]:

                for (name, value) in contentAsDict
                {
                    try CrispJSON.JTree(value, context : context.pushLevel(name)).forAllThrows(matchingDataTypes: matchingDataTypes, parseAction)
                }

            default: break
        }
    }

    /// Set the forObjectValues sorting func.
    /// - Parameter sortFunc: The sorting func to be used when executing forDictionay-s.
    public mutating func sorted(sortFunc: @escaping (String, String) -> Bool)
    {
        self.sortFunc = sortFunc
    }

    /// Get the named content, if non-nil otherwise return m_content.
    /// - Parameter named: The named content to lookup.
    /// - Returns: The named content item or m_content if the name is nil.
    private func getContent(named: String?) -> Any?
    {
        guard let name = named else { return m_content }

        if let contentAsDict = m_content as? [String : Any], let nameValue = contentAsDict[name]
        {
            return nameValue
        }

        return nil
    }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
//
// JTree Subscripting.
//

extension CrispJSON.JTree
{
    /// Subscript object's content by equating entry name.
    /// - Parameter name: The content item name.
    /// - Returns: The objects entry content with the given name, nil if item does not exist in the object.
    public subscript(itemName: String) -> CrispJSON.JTree?
    {
        get {
            guard let contentAsDict = m_content as? [String : Any]
            else {
                context.trace("try match[\(itemName)] => fail (content is not an object)")
                return nil
            }

            guard let namedValue = contentAsDict[itemName]
            else {
                context.trace("try match[\(itemName)] => fail (no matching object entry, existing names are: \(contentAsDict.keys)")
                return nil
            }

            context.trace("try match[\(itemName)] => matched")

            return CrispJSON.JTree(namedValue, context: context.pushLevel(itemName))
        }
    }

    /// Subscript object content by matching entry name.
    /// - Parameter match: The matching criteria.
    /// - Returns: The matching object's entry content, nil if there is no match.
    public subscript(match: JMatch) -> CrispJSON.JTree?
    {
        get {
            guard let contentAsDict = m_content as? [String : Any]
            else {
                context.trace("try match[JRegex(\(match))] => fail (content is not an object)")
                return nil
            }

            let matchExpr: String!
            var options : String.CompareOptions!

            switch match
            {
                case .regex(let regexOp):

                    matchExpr = regexOp
                    options = String.CompareOptions.regularExpression

                case .regexAllCase(let regexOp):

                    matchExpr = regexOp
                    options = [String.CompareOptions.regularExpression, String.CompareOptions.caseInsensitive]
                
                case .compare(let (matchStringOp, optionsOp)):
                    
                    matchExpr = matchStringOp
                    options = optionsOp
            }

            for entryName in contentAsDict.keys
            {
                if entryName.range(of: matchExpr, options: options) != nil
                {
                    let namedValue = contentAsDict[entryName]

                    context.trace("try match[JRegex(\(match))] => matched")

                    return CrispJSON.JTree(namedValue, context: context.pushLevel(entryName))
                }
            }

            return nil
        }
    }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
//
// JTree Tracing.
//

extension CrispJSON.JParser
{
    /// Enable parsing tracing.
    open func traceOn(_ title: String? = "trace >>") -> Self
    {
        context.traceTitle = title
        return self
    }

    /// Disable parsing tracing.
    open func traceOff() -> Self
    {
        context.traceTitle = nil
        return self
    }
}

//<<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
//
// CustomStringConvertible and CustomDebugStringConvertible conformance.
//

extension CrispJSON.JParser: CustomStringConvertible, CustomDebugStringConvertible
{
    open var description : String           { return json ?? "Invalid JSON" }
    public var debugDescription: String     { return description }
}

extension CrispJSON.JTree: CustomStringConvertible, CustomDebugStringConvertible
{
    public var description : String         { return json }
    public var debugDescription: String     { return description }
}

