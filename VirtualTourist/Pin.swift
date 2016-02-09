//
//  Pin.swift
//  VirtualTourist
//
//  Created by Jefferson Bonnaire on 07/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation

import UIKit
import CoreData

class Pin: NSManagedObject {

    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {

        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        // Dictionary
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
    }
}
