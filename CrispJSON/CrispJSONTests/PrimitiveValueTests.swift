//
//  PrimitiveTests.swift
//  CrispJSON Project
//
//  Created by Terry Stillone on 11/09/2016.
//  Copyright (c) 2016 Originware. All rights reserved.
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

class PrimitiveValueTests: XCTestCase {
    
    override func setUp()       { super.setUp() }
    override func tearDown()    { super.tearDown() }
    
    func runParseThrowsRig(_ jsonTestData : String, expectThrow : Bool, expectParseClosureToRun : Bool)
    {
        var didThrow = false
        var didRunClosure = false
        
        do {
            
            try CrispJSON.JParser(CrispJSON.JDataSource(jsonTestData)!).parseThrows({ (json) in
                
                didRunClosure = true
            })
            
            XCTFail("Expected parser to throw exception")
            
        } catch {
            
            didThrow = true
        }
        
        XCTAssertTrue(expectParseClosureToRun == didRunClosure, "Expected clousure not to be run")
        XCTAssertTrue(expectThrow == didThrow, "Expected exception to be thrown")
    }
    
    func runParseRig(_ jsonTestData : String, expectError : Bool, expectParseClosureToRun : Bool)
    {
        var didRunClosure = false
        
        let error = CrispJSON.JParser(CrispJSON.JDataSource(jsonTestData)!).parseGivingError({ (json) in
            
            didRunClosure = true
        })
        
        let haveError = error != nil
        
        XCTAssertTrue(expectParseClosureToRun == didRunClosure, "Expected clousure not to be run")
        XCTAssertNotNil(expectError == haveError, "Expected parsing to fail")
    }
    
    
    func testParsingJSONWithRootAsString() {

        var value : Int? = nil
        let error = CrispJSON.JParser(CrispJSON.JDataSource("{ \"one\" : 1 }")!).parseGivingError({ (json) in
            
            value = json ->> "one" ->> JValue<Int>.value
        })
        
        XCTAssertNil(error, "Expected parsing to succeed")
        XCTAssertTrue(value == 1)
    }
    
    func testParsingJSONWithNonRootAsString() {
        
        var value : Int? = nil
        let error = CrispJSON.JParser(CrispJSON.JDataSource("[{ \"one\" : 1 }]")!).parseGivingError({ (json) in
            
            json.forArray({ (valueObject) in
              
                value = valueObject ->> "one" ->> JValue<Int>.value
            })
        })
        
        XCTAssertNil(error, "Expected parsing to succeed")
        XCTAssertTrue(value == 1)
    }
    
    func testParsingJSONWithNonValidString() {
        
        let jsonTestData = "xxxx"
        
        runParseRig(jsonTestData, expectError: true, expectParseClosureToRun: false)
        runParseThrowsRig(jsonTestData, expectThrow: true, expectParseClosureToRun: false)
    }
    
    func testParsingJSONWithEmptyString() {
        
        let jsonTestData = ""
        
        runParseRig(jsonTestData, expectError: true, expectParseClosureToRun: false)
        runParseThrowsRig(jsonTestData, expectThrow: true, expectParseClosureToRun: false)
    }

    func testParsingNullValueFromStringDataSource() {

        let jsonTestData = "{ \"one\" : null }"

        var didRunClosure = false
        let error = CrispJSON.JParser(CrispJSON.JDataSource(jsonTestData)!).parseGivingError({ (json) in

            didRunClosure = true

            let nullValue = json["one"]
            let intValue  = json["one"] ->> JValue<Int>.value

            XCTAssertTrue(nullValue!.dataType == .null, "expected null primitive value to be JDataType.null data type" )
            XCTAssertNil(intValue, "expected null to Int casting to be null" )
            XCTAssertTrue(didRunClosure, "Expected clousure not to be run")
        })

        XCTAssertTrue(didRunClosure, "expected closure to be run" )
        XCTAssertNil(error, "expected error to be nil" )
    }

    func testParsingNullValueFromDictDataSource() {

        let jsonTestData : [String : Any] = [ "one" : NSNull() ]

        var didRunClosure = false
        let error = CrispJSON.JParser(CrispJSON.JDataSource(jsonTestData)!).parseGivingError({ (json) in

            didRunClosure = true

            let nullValue = json["one"]
            let intValue  = json["one"] ->> JValue<Int>.value

            XCTAssertTrue(nullValue!.dataType == .null, "expected null primitive value to be JDataType.null data type" )
            XCTAssertNil(intValue, "expected null to Int casting to be null" )
            XCTAssertTrue(didRunClosure, "Expected clousure not to be run")
        })

        XCTAssertTrue(didRunClosure, "expected closure to be run" )
        XCTAssertNil(error, "expected error to be nil" )
    }
}
