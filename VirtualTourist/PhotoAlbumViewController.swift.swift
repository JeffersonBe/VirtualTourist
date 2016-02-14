//
// PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jefferson Bonnaire on 07/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var toolBarButton: UIBarButtonItem!

    var selectedPin: Pin!
    var temporaryContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()

        let annotation = MKPointAnnotation()
        annotation.coordinate = selectedPin.coordinate

        updateMap(annotation)
        loadPhotos(annotation)

        collectionView.delegate = self
        collectionView!.registerClass(CustomCollectionViewCell.self,forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView.backgroundColor = UIColor.clearColor()

        do {
            try fetchedResultsController.performFetch()
        } catch {}

        fetchedResultsController.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "locations == %@", self.selectedPin)
        fetchRequest.sortDescriptors = []

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        return fetchedResultsController
        
    }()

    func updateMap(annotation: MKPointAnnotation) {
        mapView.showAnnotations([annotation], animated: true)
    }

    func loadPhotos(annotation: MKPointAnnotation) {

        guard -180...180 ~= annotation.coordinate.latitude || -90...90 ~= annotation.coordinate.longitude else {
            return
        }

        let minlongitude = Int(annotation.coordinate.longitude) * -1
        let minlatitude = Int(annotation.coordinate.latitude) * -1
        let maxlongitude = Int(annotation.coordinate.longitude)
        let maxlatitude = Int(annotation.coordinate.latitude)

        let parameters: [String:AnyObject] = [
            "method": Flickr.Resources.SearchPhotos,
            "api_key": Flickr.Constants.ApiKey!,
            "bbox": "\(minlongitude),\(minlatitude),\(maxlongitude),\(maxlatitude)",
            "extras": Flickr.Keys.Extras,
            "format": Flickr.Keys.Format,
            "nojsoncallback": Flickr.Keys.No_json_Callback,
            "accuracy": 6,
            "per_page": 30
        ]

        Flickr.sharedInstance.taskForResource(parameters) { parsedResult, error in

            // Handle the error case
            if let error = error {
                print("Error searching for actors: \(error.localizedDescription)")
                return
            }
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary,
                photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                    return
            }

            let _ = photoArray.map() { (dictionary: [String: AnyObject]) -> Photo in
                let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                photo.locations = self.selectedPin
                return photo
            }
            
            // Save managed object context
            CoreDataStackManager.sharedInstance.saveContext()
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView.reloadData()
            }
        }
    }

    // MARK: CollectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        configureCell(cell, withPhoto: photo)
        return cell
    }

    func configureCell(cell: CustomCollectionViewCell, withPhoto photo: Photo) {
            Flickr.sharedInstance.taskForImage(photo.imageUrl) { imageData, error in
                if let image = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView.image = UIImage(data: image)
                    }
                }
            }
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        collectionView.reloadInputViews()
    }
}
