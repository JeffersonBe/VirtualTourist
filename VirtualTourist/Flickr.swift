//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Jefferson Bonnaire on 08/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation

class Flickr : NSObject {

    // MARK: - Shared Instance
    static var sharedInstance = Flickr()

    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    var session: NSURLSession
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }

    // MARK: - Shared Image Cache

    struct Caches {
        static let imageCache = ImageCache()
    }


    // MARK: - All purpose task method for data

    func taskForResource(parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {

        let urlString = Constants.BaseUrl + Flickr.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in

            if let error = downloadError {
                let newError = Flickr.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                Flickr.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }

        task.resume()

        return task
    }

    // MARK: - All purpose task method for images

    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {

        let url = NSURL(string: filePath)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in

            if let error = downloadError {
                let newError = Flickr.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }

        task.resume()

        return task
    }


    // MARK: - Helpers

    // Try to make a better error, based on the status_message from Flickr. If we cant then return the previous error

    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {

        if data == nil {
            return error
        }

        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)

            if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult[Flickr.Keys.ErrorStatusMessage] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
            }

        } catch _ {}

        return error
    }

    // Parsing the JSON

    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil

        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }

        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }

    // URL Encoding a dictionary into a parameter string

    class func escapedParameters(parameters: [String : AnyObject]) -> String {

        var urlVars = [String]()

        for (key, value) in parameters {

            // make sure that it is a string value
            let stringValue = "\(value)"

            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

            // Append it

            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }

        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    func calculateBboxParameters(latitude: Double, longitude: Double) -> String {
        let latMin = -90.0
        let latMax = 90.0
        let longMin = -180.0
        let longMax = 180.0

        let bboxEdge = 0.1

        var bBoxLatMin = latitude - bboxEdge
        var bBoxLongMin = longitude - bboxEdge
        var bBoxLatMax = latitude + bboxEdge
        var bBoxLongMax = longitude + bboxEdge

        if bBoxLatMax > latMax {
            bBoxLatMax = latMax
            bBoxLatMin = latMax - bboxEdge
        } else if bBoxLatMin < latMin {
            bBoxLatMin = latMin
            bBoxLatMax = latMax - bboxEdge
        }

        if bBoxLongMax > longMax {
            bBoxLongMax = (bBoxLongMax - longMax) + longMin
        } else if bBoxLongMin < longMin {
            bBoxLongMin = longMax - (bBoxLongMin + longMin)
        }

        return "\(bBoxLongMin),\(bBoxLatMin),\(bBoxLongMax),\(bBoxLatMax)"
    }
}