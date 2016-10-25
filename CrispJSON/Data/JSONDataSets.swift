//
// Created by Terry Stillone on 1/10/2016.
// Copyright (c) 2016 Originware. All rights reserved.
//

import Foundation

fileprivate let faceBook : [String: Any] = [

    "data": [
            [
                    "id": "X999_Y999",
                    "from": [
                            "name": "Tom Brady", "id": "X12"
                    ],
                    "message": "Looking forward to 2010!",
                    "actions": [
                            [
                                    "name": "Comment",
                                    "link": "http://www.facebook.com/X999/posts/Y999"
                            ],
                            [
                                    "name": "Like",
                                    "link": "http://www.facebook.com/X999/posts/Y999"
                            ]
                    ],
                    "type": "status",
                    "created_time": "2010-08-02T21:27:44+0000",
                    "updated_time": "2010-08-02T21:27:44+0000"
            ],
            [
                    "id": "X998_Y998",
                    "from": [
                            "name": "Peyton Manning", "id": "X18"
                    ],
                    "message": "Where's my contract?",
                    "actions": [
                            [
                                    "name": "Comment",
                                    "link": "http://www.facebook.com/X998/posts/Y998"
                            ],
                            [
                                    "name": "Like",
                                    "link": "http://www.facebook.com/X998/posts/Y998"
                            ]
                    ],
                    "type": "status",
                    "created_time": "2010-08-02T21:27:44+0000",
                    "updated_time": "2010-08-02T21:27:44+0000"
            ]
    ]
]

fileprivate let colors : [String: Any] = [
    "red":"#f00",
    "green":"#0f0",
    "blue":"#00f",
    "cyan":"#0ff",
    "magenta":"#f0f",
    "yellow":"#ff0",
    "black":"#000"
]

fileprivate let twitter : [String: Any] = [

    "results": [

            [
                "text":"@twitterapi  http://tinyurl.com/ctrefg",
                "to_user_id":396524,
                "to_user":"TwitterAPI",
                "from_user":"jkoum",
                "metadata":

                [
                    "result_type":"popular",
                    "recent_retweets": 109
                ],

                "id":1478555574,
                "from_user_id":1833773,
                "iso_language_code":"nl",
                "source":"twitter< /a>",
                "profile_image_url":"http://s3.amazonaws.com/twitter_production/profile_images/118412707/2522215727_a5f07da155_b_normal.jpg",
                "created_at":"Wed, 08 Apr 2009 19:22:10 +0000"
            ],

            [
                    "text":"@twitterapi  http://tinyurl.com/ctrefg",
                    "to_user_id":396525,
                    "to_user":"TwitterAPI",
                    "from_user":"test",
                    "metadata":

                    [
                            "result_type":"popular",
                            "recent_retweets": 102
                    ],

                    "id":1478555578,
                    "from_user_id":1833778,
                    "iso_language_code":"nl",
                    "source":"twitter< /a>",
                    "profile_image_url":"http://s3.amazonaws.com/twitter_production/profile_images/118412707/2522215727_a5f07da155_b_normal.jpg",
                    "created_at":"Wed, 09 Mar 2014 10:22:10 +0000"
            ],
    ],

    "since_id":0,
    "max_id":1480307926,
    "refresh_url":"?since_id=1480307926&q=%40twitterapi",
    "results_per_page":15,
    "next_page":"?page=2&max_id=1480307926&q=%40twitterapi",
    "completed_in":0.031704,
    "page":1,
    "query":"%40twitterapi"
]

let googlePlaces : [String : Any] = [

    "results" : [

        [
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
        ]
    ]
]

extension CrispJSON
{
    public static func dataSet(named name: String) -> JDataSource
    {
        switch name
        {
            case "facebook":        return JDataSource(faceBook)!
            case "colors":          return JDataSource(colors)!
            case "twitter":         return JDataSource(twitter)!
            case "google places":   return JDataSource(googlePlaces)!

            default:           fatalError("Unknown data set")
        }
    }
}

