//
// Licensed under Apache License v2.0
// See the accompanying License.txt file in the packaging of this file.
//

//: ###
//: ### CrispJSON Playground, used for:
//: ### * Modelling JSON Use-Scenarios.
//: ### * Testing JSON Parsing Techniques.
//: ###

import Foundation
import CoreLocation
import CrispJSON


//: ***
//: ##### Playground Support Definitions
//: ***
/// Parsing result (if required)
enum eJResult
{
    case noResult
    case success(Int)
    case fail(NSError)
    case dataError(String)
}

/// Exceptions (if required)
enum eError : Error
{
    case noResult
    case error(NSError)
    case dataFailure(String)
}

// Parsing stats results (if required)
struct ResultWithStats
{
    let passedCount : Int
    let failedCount : Int
    let results : [Int]
}

// Print a section header.
func printHeader(_ title: String)
{
    print("\n\n ===> \(title) ===>\n")
}

// eJResult Equatability.
func ==(lhs: eJResult, rhs: eJResult) -> Bool
{
    switch (lhs, rhs)
    {
    case (.noResult, .noResult):
        return true
    case (.success(let lhsResult), .success(let rhsResult)):
        return lhsResult == rhsResult
    case (.fail(let lhsError), .fail(let rhsError)):
        return lhsError == rhsError
    case (.dataError(let lhsFailure), .dataError(let rhsFailure)):
        return lhsFailure == rhsFailure
    default:
        return false
    }
}

//: ***
//: ##### Parsing scenarios.
//: ***

printHeader("Parsing Scenarios:")

do {   // Value extraction and casting to target type using Generics.
    
    print("\t 1. Value extraction and casting.")
    
    let dataSource = CrispJSON.JDataSource("{ \"one\" : 1, \"two\" : 2 }")!
    let result : Int? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        // Print the JTree JSON for debugging.
        print(json)
        
        // Extract the value of the item named "one" to an Int.
        return json ->> "one" ->> JValue<Int>.value
    })!
    
    print("\n\t\t Result ==> ", result!)
    
    assert(1 == result!)
}

do {   // Iteration through array, matching on name.
    
    print("\n\t 2. Iteration through array, matching on name, with non root JSON object")
    
    let dataSource = CrispJSON.JDataSource("[ { \"one\" : 1 }, {\"two\" : 2}, {\"three\" : [3, 4, 5]} ]")!
    let result : [Int]? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var results = [Int]()
        
        json.forArray({ (object) in
            
            print("\nobject >> \(object)")
            
            // Use regular expression matching.
            if let intValue = object ->> JMatch.regex("(^one$)|(^two$)") ->> JValue<Int>.value
            {
                results.append(intValue)
            }
            else if let arrayValue = object ->> "three" ->> JValue<[Int]>.value
            {
                results += arrayValue
            }
        })
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert([1, 2, 3, 4, 5] == result!)
}

do {   // Iteration through object's values, matching on value type.
    
    print("\n\t 3. Iteration through object's entries, matching on value type")
    
    let dataSource = CrispJSON.JDataSource("{ \"one\" : 1 , \"two\" : \"two\", \"three\" : false }")!
    
    let result : [Bool]? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var results = [Bool]()
        
        json.forObjectValues({ (name, object) in
            
            if let value = object ->> JValue<Bool>.valueWithType(eJDataType.boolean)
            {
                results.append(value)
            }
        })
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert([false] == result!)
}

do {   // Iteration through object's values, matching on name.
    
    print("\n\t 4. Iteration through object's values, matching on name")
    
    let dataSource = CrispJSON.JDataSource("{ \"results\" : { \"one\" : 1, \"two\" : \"two\", \"three\" : 3 }}")!
    
    let result : [Int]? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var results = [Int]()
        
        json["results"]?.forObjectValues({ (name, object) in
            
            switch name
            {
            case "one", "two":
                
                if let value = object ->> JValue<Int>.value
                {
                    results.append(value)
                }
                
            default:    break
            }
        })
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert([1] == result!)
}


do {   // Recursion.
    
    print("\n\t 5. Recursion")
    
    let dataSource = CrispJSON.JDataSource("{ \"results\" : [ { \"one\" : 1 },  { \"two\" : \"two\", \"three\" : false }, { \"four\" : { \"five\" : \"string\" }}]}")!
    
    let result : [String]? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var results = [String]()
        
        json.forAll(matchingDataTypes: JDataTypeOptionSet.AllValues, { (name, jtree) in
            
            guard let name = name else { return }
            
            // Match on item name.
            switch name
            {
            case "three":
                
                guard let value = jtree ->> JValue<Bool>.value else { return }
                
                results.append(String(value ? "\(name):on" : "\(name):off"))
                
            case "one":
                
                guard let value = jtree ->> JValue<Double>.value else { return }
                
                results.append("\(name):\(value)")
                
            case "five":
                
                guard let value = jtree ->> JValue<String>.value else { return }
                
                results.append("\(name):\(value)")
                
            default:
                
                break
            }
        })
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert(["one:1.0", "three:off", "five:string"] == result!)
}

do {   // Chaining using operator manipulators.
    
    print("\n\t 6. Chaining using operator manipulators.")
    
    let dataSource = CrispJSON.JDataSource("{ \"results\" : { \"one\" : 1 , \"two\" : \"2\", \"three\" : { \"four\" : 4.1 }}}")!
    
    let result : Double? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var results : Double = 0.0
        
        if let two = json ->> "results" ->> "two" ->> JValue<String>.value, let doubleValue = Double(two)
        {
            results += doubleValue
        }
        
        if let three = json ->> "results" ->> "three" ->> "four" ->> JValue<Double>.value
        {
            results += three
        }
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert(6.1 == result!)
}

do {   // Chaining using optional subscripting.
    
    print("\n\t 7. Chaining using optional subscripting")
    
    let dataSource = CrispJSON.JDataSource("{ \"results\" : { \"one\" : 1 , \"two\" : \"2\", \"three\" : { \"four\" : 4.1 }}}")!
    
    let result : Double? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var results : Double = 0.0
        
        if let two = json["results"]?["two"] ->> JValue<String>.value, let doubleValue = Double(two)
        {
            results += doubleValue
        }
        
        if let three = json["results"]?["three"]?["four"] ->> JValue<Double>.value
        {
            results += three
        }
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert(6.1 == result!)
}

//: ***
//: ##### Tracing.
//: ***

printHeader("Tracing Techniques:")

do {   // Trace all using the traceOn() method on the parser.
    
    print("\t 1.Trace all JSON using the trace() method on the parser.\n")
    
    let dataSource = CrispJSON.JDataSource("[{ \"one\" : 1 }, { \"two\" : \"two\" }, { \"three\" : true }]")!
    
    // Trace the JParser, which traces all parsing.
    let result : [Bool]? = CrispJSON.JParser(dataSource).traceOn("\t\t\t>> trace >>").parse({ (json) in
        
        var results = [Bool]()
        
        json.forArray({ (object) in
            
            object.forObjectValues({ (name, value) in
                
                if let boolValue = value ->> JValue<Bool>.valueWithType(eJDataType.boolean)
                {
                    results.append(boolValue)
                }
            })
        })
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert([true] == result!)
}

do {  // Partial tracing with the traceOn() method on a JTree hierarchy.
    
    print("\n\t 2. Partial tracing with the traceOn() method on a JTree hierarchy.\n")
    
    let dataSource = CrispJSON.JDataSource("[{ \"one\" : 1 }, { \"two\" : \"two\" }, { \"three\" : [{ \"four\" : 4.1 }] }]")!
    
    let _ = CrispJSON.JParser(dataSource).parseGivingError({ (json) in
        
        json.forArray({ (object) in
            
            let _ = object ->> JMatch.regex("(one)|(two)") ->> JValue<String>.value
            
            // Trace only the parsing of the objects.
            object.traceOn("\t\t\t[trace three object]")["three"]?.forArray({ (threeObject) in
                
                let _ = threeObject ->> "four" ->> JValue<Bool>.value
            })
        })
    })
}


do {  // Specific value tracing with the traceOn() method on a JTree.
    
    print("\n\t 3. Specific value tracing with the traceOn() method on a JTree object.\n")
    
    let dataSource = CrispJSON.JDataSource("[{ \"one\" : 1 }, { \"two\" : \"two\" }, { \"three\" : false }]")!
    
    let _ = CrispJSON.JParser(dataSource).parseGivingError({ (json) in
        
        json.forArray({ (object) in
            
            let _ = object.traceOn("\t\t\t[trace one  ]") ->> "two" ->> JValue<String>.value
            let _ = object ->> "two" ->> JValue<String>.value
            let _ = object.traceOn("\t\t\t[trace three]") ->> "three" ->> JValue<Bool>.value
        })
    })
}



//: ***
//: ##### Data type checking and introspection scenarios.
//: ***

printHeader("Data Typing Uses:")

do {   // Data type introspection on recursion.
    
    print("\t 1. Data type introspection on recursion")
    
    let dataSource = CrispJSON.JDataSource("{ \"results\" : [{ \"one\" : 1 }, { \"two\" : \"two\" }, { \"three\" : false, \"four\" : 22.0 }]}")!
    
    let result : [String]? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var results = [String]()
        
        json.forAll(matchingDataTypes: JDataTypeOptionSet.AllValues, { (name, jtree) in
            
            guard let name = name else { return }
            
            switch jtree.dataType
            {
            case .boolean:
                
                guard let value = jtree ->> JValue<Bool>.value else { return }
                
                results.append(String(value ? "\(name):on" : "\(name):off"))
                
            case .number:
                
                guard let value = jtree ->> JValue<Double>.value else { return }
                
                results.append("\(name):\(value)")
                
            default:
                
                break
            }
        })
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert(["one:1.0", "three:off", "four:22.0"] == result!)
}

do {   // Checking for null value
    
    print("\n\t 2. Checking for null values")
    
    let dataSource = CrispJSON.JDataSource("{ \"one\" : null, \"two\" : 2 }")!
    
    let result : [Int]? = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var results = [Int]()
        
        json.forObjectValues({ (name, value) in
            
            guard value.dataType != eJDataType.null else { results.append(0); return }
            
            if let intValue = value ->> JValue<Int>.value
            {
                results.append(intValue)
            }
        })
        
        return results
    })
    
    print("\n\t\t Result ==> ", result!)
    
    assert([0, 2] == result!)
}

//: ***
//: ##### Error Handling Scenarios.
//: ***

printHeader("Error Handling Scenarios:")

do {   // Simple parsing with parsing result/success/failure returned by func result.
    
    print("\t 1. Simple parsing with parsing result/success/failure returned by func result")
    
    var result : Int? = nil
    
    let dataSource = CrispJSON.JDataSource("{ \"one\" : 1, \"two\" : 2 }")!
    if let error = CrispJSON.JParser(dataSource).parseGivingError({ (json) in
        
        result = json ->> "one" ->> JValue<Int>.value
        
    })
    {
        // Handle error.
        
        print("\n\t\t Result ==> error: ", error)
        
        assert(false)
    }
    
    print("\n\t\t Result ==> ", result!)
    
    assert(1 == result!)
}

do {   // Errors Passed By Exception Handing.
    
    print("\n\t 2. Errors Passed By Exception Handing")
    
    do
    {
        let result = try CrispJSON.JParser(CrispJSON.JDataSource("{ \"one\" : 1 }")!).parseThrows({ (json) in
            
            return  json ->> "one" ->> JValue<Int>.value
        })
        
        print("\n\t\t Result ==> ", result!)
        
        assert(1 == result)
    }
    catch let error
    {
        print("\n\t\t Result ==> \(error)")
        
        assert(false)
    }
}

//: ***
//: ##### Data Source Handling.
//: ***

printHeader("Data Source Handling:")

do {  // Data Source validation checking before processing.
    
    print("\t 1. Data Source validation checking before processing.")
    
    // Create the data source and check its validity.
    if let dataSource = CrispJSON.JDataSource("{ \"one\" : 1, \"two\" : xxxx }"), dataSource.isValidJSON
    {
        let result : Int? = CrispJSON.JParser(dataSource).parse({ (json) in
            
            // Extract the value of the item named "one" to an Int.
            return json ->> "one" ->> JValue<Int>.value
        })!
        
        print("\n\t\t Result ==> ", result!)
        
        assert(false, "Expected JSON to be invalid.")
    }
    else
    {
        print("\n\t\t Result ==> JSON is invalid (expected result).\n")
    }
}

do {  // Streaming Data Sources.
    
    print("\t 2.  Streaming Data Sources.")
    
    func createDataSource() -> InputStream
    {
        let jsonAsDict : [String : Any] = [ "results" : [
            
            "array" : [
                "entry0",
                "entry1",
            ],
            "japanese" : [
                "日本語" : "日本語"
            ],
            ]]
        
        let data = try? JSONSerialization.data(withJSONObject: jsonAsDict, options: JSONSerialization.WritingOptions.prettyPrinted)
        return InputStream(data: data!)
    }
    
    let stream = createDataSource()
    let dataSource = CrispJSON.JDataSource(stream)
    let results : [String] = CrispJSON.JParser(dataSource).parse({ (json) in
        
        var extracted = [String]()
        
        if let firstResultObject = json ->> "results" ->> "japanese"
        {
            if let value = firstResultObject ->> "日本語" ->> JValue<String>.value
            {
                extracted.append(value)
            }
            
        }
        
        if let array = json ->> "results" ->> "array" ->> JValue<[String]>.value
        {
            extracted += array
        }
        
        return extracted
    })!
    
    print("\n\t\t Result ==> ", results)
    
    assert(["日本語", "entry0", "entry1"] == results, "Expected JSON to be invalid.")
}


//: ***
//: ##### Statistics Gathering Scenarios.
//: ***

printHeader("Statistics Gathering Scenarios:")

do {  // Simple Parsing With Returning Stats As Well As Results.
    
    func parseGivingResultAndStats() -> ResultWithStats
    {
        var results = [Int]()
        var passedCount = 0
        var failedCount = 0
        
        let dataSource = CrispJSON.JDataSource("{ \"one\" : 1, \"two\" : 2 }")!
        if let error = CrispJSON.JParser(dataSource).parseGivingError({ (json) in
            
            func extractValue(_ name : String)
            {
                if let extractedResult = json ->> "one" ->> JValue<Int>.value
                {
                    results.append(extractedResult)
                    passedCount += 1
                }
                else
                {
                    failedCount += 1
                }
            }
            
            extractValue("one")
            extractValue("two")
        })
        {
            return ResultWithStats(passedCount: 0, failedCount: 0, results: [])
        }
        
        return ResultWithStats(passedCount: passedCount, failedCount: failedCount, results: results)
    }
    
    print("\t 1.Simple Parsing With Returning Stats As Well As Results.")
    
    let result = parseGivingResultAndStats()
    
    print("\n\t\t Result ==> ", result)
    
    assert(result.passedCount == 2)
    assert(result.failedCount == 0)
    assert(result.results == [1, 1])
}

//: ***
//: ##### Strict Parsing Scenarios.
//: ***

printHeader("Strict Parsing Scenarios:")

do {   // Only Returning Data That Is Strictly Correct.
    
    func parseStrictWithSuccessFailureResult() -> eJResult
    {
        var result : Int?
        var dataFailed : String?
        let parseError = CrispJSON.JParser(CrispJSON.JDataSource("{ \"one\" : 1, \"two\" : 2 }")!).parseGivingError({ (json) in
            
            guard let one = json ->> "one" ->> JValue<Int>.value else { dataFailed = "one"; return }
            guard let two = json ->> "one" ->> JValue<Int>.value else { dataFailed = "two"; return }
            
            result = one + two
        })
        
        if let nsError = parseError as? NSError { return .fail(nsError) }
        if let description = dataFailed         { return .dataError(description) }
        if result == nil                        { return .noResult }
        
        return .success(result!)
    }
    
    print("\t 1. Only Returning Data That Is Strictly Correct")
    
    let result = parseStrictWithSuccessFailureResult()
    
    print("\n\t\t Result ==> ", result)
    
    assert(eJResult.success(2) == result)
}

do {   // Only Returning Result If All Details Across All Data Are correct.
    
    func parseStrictWithSuccessFailureResult() -> eJResult
    {
        var result = 0
        
        do
        {
            let dataSource = CrispJSON.JDataSource("{ \"one\" : 1, \"two\" : 2, \"three\" : { \"four\" : \"string\" }}")!
            
            try CrispJSON.JParser(dataSource).parseThrows({ (json) in
                
                try json.forAllThrows(matchingDataTypes: JDataTypeOptionSet.AllValues, { (name, jtree) in
                    
                    switch jtree.dataType
                    {
                    case .number:
                        
                        guard let value = jtree ->> JValue<Int>.value else { throw(eError.dataFailure("failed passing \(name!)")) }
                        
                        result += value
                        
                    default:
                        
                        throw(eError.dataFailure("Unexpected data type(\(jtree.dataType)) for item \(name!)"))
                    }
                })
            })
        }
        catch eError.dataFailure(let errorDescription)
        {
            return .dataError(errorDescription)
        }
        catch let nsError as NSError
        {
            return .fail(nsError)
        }
        
        return .success(result)
    }
    
    print("\n\t 2. Only Returning Result If All Details Across All Data Are Correct")
    print("\n\t\t Result ==> ", parseStrictWithSuccessFailureResult())
}


//: ***
//: ##### Medium Complexity Parsing Scenarios.
//: ***

printHeader("Medium Complexity Parsing Scenarios:")

struct Location
{
    let name : String
    let address : String
    let locationTypes : [String]?
    let coordinate : Coordinate
}

struct Coordinate : CustomStringConvertible
{
    let lat : Double
    let lng : Double
    
    var description : String { return "(\(lat), \(lng))"}
}

do {  // More complexity parsing (Google Places)
    
    func parseGooglePlaces(_ dataSource: CrispJSON.JDataSource) -> [Location]
    {
        func remark(_ message: String)
        {
            print(message)
        }
        
        let parser = CrispJSON.JParser(dataSource)
        
        return parser.parse({ (json) in
            
            var locations = [Location]()
            
            json["results"]?.forArray({ (result) in
                
                guard let name     = result ->> "name" ->> JValue<String>.value       else { remark("name field missing"); return }
                guard let address  = result ->> "address" ->> JValue<String>.value    else { remark("address field missing"); return }
                let locationTypes  = result ->> "types" ->> JValue<[String]>.value    // location types are optional.
                
                if let location = result ->> "geometry" ->> "location"
                {
                    guard let lat = location ->> "lat" ->> JValue<Double>.value else { remark("lat field missing"); return }
                    guard let lng = location ->> "lng" ->> JValue<Double>.value else { remark("lng field missing"); return }
                    
                    let location = Location(name: name, address: address, locationTypes: locationTypes, coordinate: Coordinate(lat: lat, lng: lng))
                    
                    locations.append(location)
                }
                else
                {
                    remark("location field missing")
                }
            })
            
            return locations
        })!
    }
    
    let dataSource = CrispJSON.dataSet(named: "google places")
    let locations = parseGooglePlaces(dataSource)
    
    print("\t 1. More Complex Parsing (Google Places JSON)")
    print("\n\t\t Result ==> ", locations)
    
    assert(locations.count == 1)
}

//: ***
//: ##### More complex parsing (Twitter)
//: ***

do {    // Decomposition of parsing into custom JValue.customValue operators.
    
    func parseTweetsInDateRange(_ dataSource : CrispJSON.JDataSource, fromDateStr: String, toDateStr: String) -> [(String, String)]
    {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let fromDate = dateFormatter.date(from: fromDateStr)!
        let toDate = dateFormatter.date(from: toDateStr)!
        
        func parseJSONDate(jtree: CrispJSON.JTree) -> Date?
        {
            guard let from = jtree ->> JValue<String>.value  else  { return nil }
            
            return dateFormatter.date(from: from)
        }
        
        func parseJSONTweetInDateRange(jtree: CrispJSON.JTree) -> (from: String, url: String)?
        {
            // Extract fields.
            guard let from = jtree ->> "from_user"  ->> JValue<String>.value  else                      { return nil }
            guard let url = jtree ->> "text"       ->> JValue<String>.value  else                       { return nil }
            guard let date = jtree ->> "created_at" ->> JValue<Date>.customValue(parseJSONDate)  else   { return nil }
            
            // Check date range.
            guard (fromDate <= date) && (date <= toDate) else                                           { return nil }
            
            return (from: from, url: url)
        }
        
        // Create and run parser.
        let parser = CrispJSON.JParser(dataSource)
        
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        
        return parser.parse({ (json) in
            
            var tweets = [(String, String)]()
            
            json["results"]?.forArray({ (result) in
                
                if let tweet = result ->> JValue<(String, String)>.customValue(parseJSONTweetInDateRange)
                {
                    tweets.append(tweet)
                }
            })
            
            return tweets
        })!
    }
    
    let dataSource = CrispJSON.dataSet(named: "twitter")
    let tweets = parseTweetsInDateRange(dataSource, fromDateStr: "2012-01-01", toDateStr: "2016-01-01")
    
    print("\t 2. Custom Value Operators (Twitter JSON)")
    print("\n\t\t Result ==> ", tweets)
    assert(tweets.count == 1)
}


//: ***
//: ##### Custom Context Uses.
//: ***

printHeader("Custom Context Uses:")

public class CustomJContext : IJContext
{
    public var jtreeLevel : Int
    
    public var jtreeLevelTag : String
    
    public var traceTitle: String? = nil
    
    let defaultLocation : Coordinate
    
    public var indent : Int { return jtreeLevel }
    
    init(jtreeLevel: Int, jtreeLevelTag: String, traceTitle : String?, defaultLocation: Coordinate)
    {
        self.jtreeLevel = jtreeLevel
        self.jtreeLevelTag = jtreeLevelTag
        self.traceTitle = traceTitle
        self.defaultLocation = defaultLocation
    }
    
    public func traceOn(_ title : String? = nil) -> IJContext
    {
        traceTitle = title
        
        return self
    }
    
    public func traceOff() -> IJContext
    {
        traceTitle = nil
        
        return self
    }
    
    public func pushLevel(_ tag : String) -> IJContext
    {
        jtreeLevel += 1
        
        return self
    }
    
    public func popLevel() -> IJContext
    {
        jtreeLevel -= 1
        
        if let range = jtreeLevelTag.range(of: "/", options:String.CompareOptions.backwards)
        {
            jtreeLevelTag.removeSubrange(range.lowerBound..<jtreeLevelTag.endIndex)
        }
        
        return self
    }
    
}

do {    // Custom Context passing through default Coordinate, to be used if none found or failed parsing.
    
    func parseGooglePlaces(_ dataSource: CrispJSON.JDataSource) -> [Location]
    {
        func remark(_ message: String)
        {
            print(message)
        }
        
        func getDefaultLocation(_ jtree: CrispJSON.JTree) -> Coordinate
        {
            return (jtree.context as! CustomJContext).defaultLocation
        }
        
        func parseCoordinate(jtree: CrispJSON.JTree) -> Coordinate
        {
            // Return the default coordinate if parsing failed.
            guard let lat = jtree ->> "lat" ->> JValue<Double>.value  else { return getDefaultLocation(jtree) }
            guard let lng = jtree ->> "lng" ->> JValue<Double>.value  else { return getDefaultLocation(jtree) }
            
            return Coordinate(lat: lat, lng: lng)
        }
        
        return CrispJSON.JParser(dataSource).parse({ (json) -> [Location] in
            
            var locations = [Location]()
            
            json["results"]?.forArray({ (result) in
                
                guard let name     = result ->> "name" ->> JValue<String>.value      else { remark("name field missing"); return }
                guard let address  = result ->> "address" ->> JValue<String>.value   else { remark("address field missing"); return }
                let locationTypes  = result ->> "types" ->> JValue<[String]>.value   // location types are optional.
                
                if let coordinate = result ->> "geometry" ->> "location" ->> JValue<Coordinate>.customValue(parseCoordinate)
                {
                    let location = Location(name: name, address: address, locationTypes: locationTypes, coordinate: coordinate)
                    
                    locations.append(location)
                }
                else
                {
                    let location = Location(name: name, address: address, locationTypes: locationTypes, coordinate: getDefaultLocation(result))
                    
                    locations.append(location)
                }
            })
            
            return locations
        })!
    }
    
    let context = CustomJContext(jtreeLevel : 0, jtreeLevelTag: "", traceTitle: nil, defaultLocation: Coordinate(lat: 22.1, lng: 135.2))
    let dataSource = CrispJSON.dataSet(named: "google places")
    let locations = parseGooglePlaces(dataSource)
    
    print("\t 3. Custom Value Passing")
    print("\n\t\t Result ==> ", locations)
    assert(locations.count == 1)
}


