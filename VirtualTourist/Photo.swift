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
    }

    var image: UIImage? {
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(imageUrl)
        }

        set {
            Flickr.Caches.imageCache.storeImage(image, withIdentifier: imageUrl)
        }
    }

    override func prepareForDeletion() {
        Flickr.Caches.imageCache.deleteCache(imageUrl)
    }
}
