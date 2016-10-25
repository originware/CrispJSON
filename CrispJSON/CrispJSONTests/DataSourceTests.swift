//
//  DataSourceTests.swift
//  CrispJSON Project
//
//  Created by Terry Stillone on 30/09/2016.
//  Copyright 2016 Originware
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

class DataSourceTests: XCTestCase
{
    override func setUp()       { super.setUp() }
    override func tearDown()    { super.tearDown() }

    func testValidUTF8DataSource()
    {
        var results = [Int]()
        let expected = [1, 2, 3]

        let dataSource = CrispJSON.JDataSource("[ 1, 2, 3 ]")
        let _ = CrispJSON.JParser(dataSource!).parse({ (json) in

            json.forArray({ (array) in

                if let value = array ->> JValue<Int>.value
                {
                    results.append(value)
                }
            })
        })

        XCTAssertTrue(expected == results, "Expected \(expected) but got: \(results)")
    }

    func testEmptyDataSource()
    {
        var results = [Int]()
        let dataSource = CrispJSON.JDataSource("")
        let _ = CrispJSON.JParser(dataSource!).parse({ (json) in

            json.forArray({ (array) in

                if let value = array ->> JValue<Int>.value
                {
                    results.append(value)
                }
            })
        })

        XCTAssertTrue([] == results, "Expected [] but got: \(results)")
    }

    func testInvalidUTF8DataSource()
    {
        let dataPtr = UnsafePointer<UInt8>([49, 50, 51, 250, 128])
        let string : String = dataPtr.withMemoryRebound(to: String.self, capacity: 5)
        {
            return String(describing: $0)
        }

        let dataSource = CrispJSON.JDataSource(string)
        let error = CrispJSON.JParser(dataSource!).parseGivingError({ (_) in })

        XCTAssertNotNil(error, "Expected parser to raise error")
    }

    func testDictionarySource()
    {
        let dict : [String : Any] = [ "results" : [

                "address" : "3 Bridge St, Sydney NSW 2000, Australia",
                "id" : "7cc9df1247348a54523b0cb74bff6636dd447daf",
                "array" : [
                        "entry0",
                        "entry1",
                        "entry2",
                ],
                "japanese" : [
                        "日本語" : "日本語"
                ],
        ]]

        var results = [String]()
        let expected = ["7cc9df1247348a54523b0cb74bff6636dd447daf", "entry0", "entry1", "日本語"]
        let dataSource = CrispJSON.JDataSource(dict)

        let _ = CrispJSON.JParser(dataSource!).parse({ (json) in

            if let value = json ->> "results" ->> "id" ->> JValue<String>.value
            {
                results.append(value)
            }

            if let types = json ->> "results" ->> JMatch.regex("arra") ->> JValue<[String]>.value
            {
                results.append(types[0])
            }

            if let types = json["results"]?[JMatch.regex("^ar.*")] ->> JValue<[String]>.value
            {
                results.append(types[1])
            }

            if let japaneseText = json["results"]?["japanese"]?["日本語"] ->> JValue<String>.value
            {
                results.append(japaneseText)
            }
        })

        XCTAssertTrue(expected == results, "Expected \(expected) but got: \(results)")
    }

    func testEmptyDictionarySource()
    {
        let dict = [String : Any]()

        var results = [String]()
        let expected = [String]()
        let dataSource = CrispJSON.JDataSource(dict)

        let _ = CrispJSON.JParser(dataSource!).parse({ (json) in

            if let value = json ->> "results" ->> "id" ->> JValue<String>.value
            {
                results.append(value)
            }

            if let value = json ->> "results" ->> "types" ->> JMatch.regex("a") ->> JValue<String>.value
            {
                results.append(value)
            }
        })

        XCTAssertTrue(expected == results, "Expected \(expected) but got: \(results)")
    }

    func testStreamDataSource()
    {
        func createDataSource() -> InputStream
        {
            let jsonAsDict : [String : Any] = [ "results" : [

                    "address" : "3 Bridge St, Sydney NSW 2000, Australia",
                    "id" : "7cc9df1247348a54523b0cb74bff6636dd447daf",
                    "array" : [
                            "entry0",
                            "entry1",
                            "entry2",
                    ],
                    "japanese" : [
                            "日本語" : "日本語"
                    ],
            ]]

            let data = try? JSONSerialization.data(withJSONObject: jsonAsDict, options: JSONSerialization.WritingOptions.prettyPrinted)
            return InputStream(data: data!)
        }

        let expected = ["3 Bridge St, Sydney NSW 2000, Australia", "entry2"]
        let stream = createDataSource()
        let dataSource = CrispJSON.JDataSource(stream)
        let results : [String] = CrispJSON.JParser(dataSource).parse({ (json) in

            var extracted = [String]()

            if let results = json ->> "results"
            {
                if let value = results ->> "address" ->> JValue<String>.value
                {
                    extracted.append(value)
                }

                if let array2 = results ->> "array" ->> JValue<[String]>.value
                {
                    extracted.append(array2[2])
                }
            }

            return extracted
        })!

        XCTAssertTrue(expected == results, "Expected \(expected) but got: \(results)")
    }

    func testInvalidDataSource()
    {
        let dict : [String : Any] = [ "results" : [

                "address" : "3 Bridge St, Sydney NSW 2000, Australia",
                "icon" : "https://maps.gstatic.com/mapfiles/place_api/icons/restaurant-71.png",
                "id" : "7cc9df1247348a54523b0cb74bff6636dd447daf",
                "name" : "Mr. Wong",
                "types" : [
                        "cafe",
                        "bar",
                        "restaurant",
                        "food",
                        "point_of_interest",
                        "establishment"
                ],
                "geometry" : [
                        "location" : [
                                "lat" : -33.864072,
                                "lng" : 151.20802
                        ],
                ],
        ]]

        let invalidData = NSKeyedArchiver.archivedData(withRootObject: dict)
        let dataSource = CrispJSON.JDataSource(invalidData)
        let error = CrispJSON.JParser(dataSource).parseGivingError({ (_) in })

        XCTAssertNotNil(error, "Expected data source give parsing error")
    }

    func testDataSets()
    {
        for label in [ "twitter", "google places", "facebook", "colors" ]
        {
            let dataSource = CrispJSON.dataSet(named: label)

            CrispJSON.JParser(dataSource).parse({ (_) in })
        }
    }
}
