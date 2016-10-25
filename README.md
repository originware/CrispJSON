---
# README: CrispJSON v1.0.1 

CrispJSON allows you to create concise and readable JSON parsing code in Swift. Scalable and lightweight, it parses both simple and complex JSON. 


Platforms    | OSX, iOS, watchOS, tvOS and Linux package
:------------| :--------------------------------------
Language     | Swift 3.0
Origination  | [Originware](http://www.originware.com) 
Git Repo     | [bitbucket.org/originware/crispjson](https://bitbucket.org/originware/crispjson)    
Requirements | Xcode 8 or the Swift 3 compiler toolchain for Linux.


### Example Use (parsing Google Places JSON)

```
let dataSource = CrispJSON.JDataSource(jsonFromGooglePlaces)
let locations = CrispJSON.JParser(dataSource!).parse({ (json) in

    // Create the MyLocation-s array (where MyLocation is a struct representing a location).
    var results = [MyLocation]()

    json["results"].forArray({ (result) in

        guard let name     = result ->> JValue<String>.value("name")              else { return }
        guard let address  = result ->> JValue<String>.value("formatted_address") else { return }
        let types          = result ->> JValue<[String]>.value("types")           // location types 
                                                                                  // are optional.

        let coordinate = result ->> "geometry" ->> "location"

        guard let lat      = coordinate ->> JValue<Double>.value("lat")           else { return }
        guard let lng      = coordinate ->> JValue<Double>.value("lng")           else { return }

        let location       = MyLocation(name, address, types, lat, lng)
                
        results.append(location)
    })
    
    return results
})
```

Parses the following (simplified Google Places JSON)

```
{
    "results" : [
          {
             "name" : "Acme Anvil and Dynamite Company",
             "formatted_address" : "Burbank, California",
             "types" : [
                "store",
                "home_goods_store",
                "funeral_home",
             ],
             "geometry" : {
                "location" : {
                   "lat" : 34.1808,
                   "lng" : -118.3090
                },
             
          }
    } 
}         
```
 
### Parsing

CrispJSON uses a variety of parsing mechanisms:

 * The **->> operator** operates on:
     * Strings - matching specific object-dictionary entries. 
     * JMatch - regex matching object entries. 
     * JValue - matching values using Generics and converting to resultant types.
     
 * **Iterators**:
     * forArray - iterating through array entries.
     * forObjectValues - iterating through object name/values.
     * forAllValues - recursively iterating through all values, picking out what is required, by name, data-type or path.
     
 * **Subscripting**:
     * Strings - matching specific object entries.
     * JMatch - regex matching object entries.
     
See the git repo [Playground](https://bitbucket.org/originware/crispjson/src/f02f9385a798726d40ef6ebe7cd7c6789282d885/CrispJSON%20Use%20Senario%20Playground.playground/Contents.swift?at=master&fileviewer=file-view-default) source for an extensive set of use-scenarios, including:

  * Iteration and Recursion.
  * Object datatype checking.
  * Complex/repetitive parsing with custom parsing closures.
  * Error handling (simple error value passing and exception handling)
  * Supported data-dources (streaming and non-streaming)
  * Custom statistics gathering.
  * Operational tracing of parsing for debugging.  
  * Use of custom contexts for complex data handling. 
       
     
### Other Features

 * Xcode project comes with a use scenario playground for demonstration and training (see the git repo).
 * Operational tracing - Parsing can be debugged by enabling tracing and viewing the console output.
 * Decomposition of parsing into smaller units for repetitive data-types.
 * User contexts - Complex control, state and user data can be injected into parsing. 
 * Swift Package and Cocoapods support.

### Integration

* **Direct incorporation of the CrispJSON Source**:
	 
		Add the two files under the Sources directory to your source (files: CrispJSON.swift and CrispJSON-support.swift)
		
 * **Cocoapods**:
 	
 		The pod name is "CrispJSON"
    
 * **Swift Package**:
	
		cd CrispJSON
		swift build
		
### Bug Reporting, Tracking and Enhancement Requests.
		
These are handled on the CrispJSON  [Issues](https://bitbucket.org/originware/crispjson/issues?status=new&status=open)  page.    
 
### Licensing

The source package is to be provided for under the Apache Version 2.0 license.

Please direct comments and feedback to [Terry Stillone](mailto:terry@originware.com) at Originware.com