//
//  InterationTests.swift
//  CrispJSON Project
//
//  Created by Terry Stillone on 28/09/2016.
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

import XCTest
@testable import CrispJSON

/// Exceptions (if required)
public enum eError : Error, Equatable
{
    case nsError(NSError)
    case dataTypeFail(String)
}

public func ==(lhs: eError, rhs: eError) -> Bool
{
    switch (lhs, rhs)
    {
        case (.nsError(let lhsNSError), .nsError(let rhsNSError)):

            return lhsNSError == rhsNSError

        case (.dataTypeFail(let lhsFail), .dataTypeFail(let rhsFail)):

            return lhsFail == rhsFail

        default:

            return false
    }
}

class IteratorTests: XCTestCase
{
    override func setUp()       { super.setUp() }
    override func tearDown()    { super.tearDown() }

    func testForArray() {

        var results = [Int]()

        let _ = CrispJSON.JParser(CrispJSON.JDataSource("[ 1, 2, 3 ]")!).parse({ (json) in

            json.forArray({ (array) in

                if let value = array ->> JValue<Int>.value
                {
                    results.append(value)
                }
            })
        })

        XCTAssertTrue([1, 2, 3] == results, "Expected [1, 2, 3] but got: \(results)")
    }

    func testForArrayOnEmpty() {

        var results = [Int]()

        let _ = CrispJSON.JParser(CrispJSON.JDataSource("[ ]")!).parse({ (json) in

            json.forArray({ (array) in

                if let value = array ->> JValue<Int>.value
                {
                    results.append(value)
                }
            })
        })

        XCTAssertTrue([] == results, "Expected [1, 2, 3] but got: \(results)")
    }

    func testForArrayThrows() {

        var results = [Int]()
        var gotError : eError? = nil

        do
        {
            try CrispJSON.JParser(CrispJSON.JDataSource("[ { \"one\" : 1 }, {\"two\" : 2}, {\"three\" : 3} ]")!).parseThrows({ (json) in

                try json.forArrayThrows({ (array) in

                    if let value = array ->> "one" ->> JValue<Int>.value
                    {
                        results.append(value)
                    }

                    if let value = array ->> "two" ->> JValue<String>.value
                    {
                        results.append(Int(value)!)
                    }
                    else
                    {
                        throw(eError.dataTypeFail("two data type is incorrect"))
                    }

                    if let value = array ->> "three" ->> JValue<Int>.value
                    {
                        results.append(value)
                    }
                })
            })

        }
        catch let error as eError
        {
            gotError = error
        }
        catch let error
        {
            XCTFail("Unexpected exception: \(error)")
        }

        XCTAssertTrue([1] == results, "Expected [1] but got: \(results)")
        XCTAssertTrue(gotError == eError.dataTypeFail("two data type is incorrect"), "Expected [1] but got: \(results)")
    }

    func testForObjectValues() {

        let expect = [("one", 1), ("three", 3), ("two", 2)]
        var results = [(String, Int)]()

        let _ = CrispJSON.JParser(CrispJSON.JDataSource("{ \"results\" : { \"one\" : 1, \"two\" : 2, \"three\" : 3 }}")!).parse({ (json) in

            var mutatingJSON = json

            mutatingJSON.sortFunc = (<)
            (mutatingJSON ->> "results")?.forObjectValues({ (name, object) in

                let value = object ->> JValue<Int>.value

                results.append((name, value!))
            })
        })

        XCTAssertTrue(isEqual(expect, results), "Expected \(expect) but got: \(results)")
    }

    func testForObjectValuesThrows() {

        var results = [Int]()
        var gotError : eError? = nil

        do
        {
            try CrispJSON.JParser(CrispJSON.JDataSource("{ \"results\" : { \"one\" : 1, \"two\" : 2, \"three\" : 3 }}")!).parseThrows({ (json) in

                try json.forObjectValuesThrows({ (name, object) in

                    if let value = object ->> "one" ->> JValue<Int>.value
                    {
                        results.append(value)
                    }

                    if let value = object ->> "two" ->> JValue<String>.value
                    {
                        results.append(Int(value)!)
                    }
                    else
                    {
                        throw(eError.dataTypeFail("two data type is incorrect"))
                    }

                    if let value = object ->> "three" ->> JValue<Int>.value
                    {
                        results.append(value)
                    }
                })
            })

        }
        catch let error as eError
        {
            gotError = error
        }
                catch let error
        {
            XCTFail("Unexpected exception: \(error)")
        }

        XCTAssertTrue([1] == results, "Expected [1] but got: \(results)")
        XCTAssertTrue(gotError == eError.dataTypeFail("two data type is incorrect"), "Expected [1] but got: \(results)")
    }

    func testForAll_Values() {

        let expect = [("one", 1), ("two", 2), ("three", 3)]
        var results = [(String, Int)]()

        let _ = CrispJSON.JParser(CrispJSON.JDataSource("[ { \"one\" : 1 }, {\"two\" : 2}, {\"three\" : 3} ]")!).parse({ (json) in

            json.forAll(matchingDataTypes: JDataTypeOptionSet.AllValues, { (name, object) in

                let value = object ->> JValue<Int>.value

                results.append((name!, value!))
            })
        })

        XCTAssertTrue(isEqual(expect, results), "Expected \(expect) but got: \(results)")
    }

    func testForAll_Dictionaries() {

        let expect : [(String, eJDataType)] = [("/array", .object), ("/array", .object), ("/array", .object), ("/array/three", .object)]
        var results = [(String, eJDataType)]()

        let context = JContextWithPath()
        let _ = CrispJSON.JParser(CrispJSON.JDataSource("[ { \"one\" : 1 }, {\"two\" : 2}, {\"three\" : { \"four\" : 4 } }]")!, context : context).parse({ (json) in

            json.forAll(matchingDataTypes: JDataTypeOptionSet.oObject, { (name, object) in

                results.append((name!, object.dataType))
            })
        })

        XCTAssertTrue(isEqual(expect, results), "Expected \(expect) but got: \(results)")
    }

    func testForAll_ValuesThrows() {

        let expect = [("one", 1)]
        var results = [(String, Int)]()
        var gotError : eError? = nil

        do
        {
            try CrispJSON.JParser(CrispJSON.JDataSource("[ { \"one\" : 1 }, {\"two\" : \"two\"}, {\"three\" : 3} ]")!).parseThrows({ (json) in

                try json.forAllThrows(matchingDataTypes: JDataTypeOptionSet.AllValues, { (name, object) in

                    if let value = object ->> JValue<Int>.value
                    {
                        results.append((name!, value))
                    }
                    else
                    {
                        throw(eError.dataTypeFail("two data type is incorrect"))
                    }
                })
            })
        }
        catch let error as eError
        {
            gotError = error
        }
        catch let error
        {
            XCTFail("Unexpected exception: \(error)")
        }

        XCTAssertTrue(isEqual(expect, results), "Expected \(expect) but got: \(results)")
        XCTAssertTrue(gotError == eError.dataTypeFail("two data type is incorrect"), "Expected [1] but got: \(results)")
    }

    func isEqual<T : Equatable>(_ lhs : [(String, T)], _ rhs: [(String, T)]) -> Bool
    {
        guard lhs.count == rhs.count else { return false }

        for i in 0..<lhs.count
        {
            if lhs[i] != rhs[i] { return false }
        }

        return true
    }
}
