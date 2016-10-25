//
//  DataTypeTests.swift
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

class DataTypeTests: XCTestCase {

    override func setUp()       { super.setUp() }
    override func tearDown()    { super.tearDown() }

    func testPrimitiveDataTyping()
    {
        let dataSource = CrispJSON.JDataSource("{ \"true\" : true, \"false\" : true, \"int\" : 1, \"double\" : 9.3, \"string\" : \"string\" }")!
        
        let error : Error? = CrispJSON.JParser(dataSource).parseGivingError({ (json) in
            
            func check(_ name : String, _ expectedDataType : eJDataType)
            {
                guard let anyObject = json ->> name ->> JValue<Any>.value
                else { XCTFail("Could not get JTree for item named: \(name)"); return }
                
                let dataType = CrispJSON.JTree.getDataType(anyObject)
                    
                XCTAssertTrue(dataType == expectedDataType, "Expected data type \(expectedDataType) for value with name \(name)")
            }
            
            check("true", eJDataType.boolean)
            check("false", eJDataType.boolean)
            check("int", eJDataType.number)
            check("double", eJDataType.number)
            check("string", eJDataType.string)
        })
        
        XCTAssertNil(error, "Expected parsing to succeed")
    }
    
    func testStructuredDataTyping()
    {
        let dataSource = CrispJSON.JDataSource("{ \"dict\" : { \"one\" : 1, \"two\" : 2 }, \"array\" : [ 1, 2, 3, 4] }")!
        
        let error = CrispJSON.JParser(dataSource).parseGivingError({ (json) in
            
            func check(_ name : String, _ expectedDataType : eJDataType)
            {
                guard let anyObject = json ->> name ->> JValue<Any>.value
                else { XCTFail("Could not get JTree for item named: \(name)"); return }
                
                let dataType = CrispJSON.JTree(anyObject).dataType
                
                XCTAssertTrue(dataType == expectedDataType, "Expected data type \(expectedDataType) for value with name \(name)")
            }
            
            check("dict", eJDataType.object)
            check("array", eJDataType.array)
        })
        
        XCTAssertNil(error, "Expected parsing to succeed")
    }
}
