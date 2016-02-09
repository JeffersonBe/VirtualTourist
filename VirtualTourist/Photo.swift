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

    struct Keys {
        static let Title = "title"
        static let imageUrl = "url_m"
    }

    @NSManaged var title: String
    @NSManaged var imageUrl: String

    override init(entity: NSEntityDescription,
        insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {

        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        // Dictionary
        title = dictionary[Keys.Title] as! String
        imageUrl = dictionary[Keys.imageUrl] as! String
    }
}
