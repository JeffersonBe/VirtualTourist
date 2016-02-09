//
//  FlickrConstant.swift
//  VirtualTourist
//
//  Created by Jefferson Bonnaire on 08/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation

extension Flickr {

    struct Constants {

        // MARK: - URLs
        static let ApiKey = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Key", ofType: "plist")!)?.valueForKey("API_KEY")
        static let BaseUrl = "https://api.flickr.com/services/rest/"
    }

    struct Resources {

        // MARK: - Methods
        static let SearchPhotos = "flickr.photos.search";
    }

    struct Keys {
        static let ID = "id"
        static let ErrorStatusMessage = "status_message"
        static let Extras = "url_m"
        static let Format = "json"
        static let No_json_Callback = "1"
    }
}