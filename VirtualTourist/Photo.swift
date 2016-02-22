//
//  Photo.swift
//  VirtualTourist
//
//  Created by Jefferson Bonnaire on 07/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation

import UIKit
import CoreData

class Photo: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var imageUrl: String
    @NSManaged var imageId: String
    @NSManaged var locations: Pin?

    override init(entity: NSEntityDescription,
        insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {

        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        title = dictionary[Flickr.JSONKeys.Title] as! String
        imageUrl = dictionary[Flickr.JSONKeys.imageUrl] as! String
        let url = NSURL(string:imageUrl)
        imageId = url!.lastPathComponent!.stringByReplacingOccurrencesOfString(".jpg", withString: "")
    }

    var image: UIImage? {
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(imageId)
        }

        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: imageId)
        }
    }

    override func prepareForDeletion() {
        Flickr.Caches.imageCache.deleteCache(imageId)
    }
}
