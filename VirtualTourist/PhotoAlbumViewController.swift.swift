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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var toolBarButton: UIBarButtonItem!

    var selectedPin: Pin!
    var temporaryContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView!.registerClass(CustomCollectionViewCell.self,forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView.backgroundColor = UIColor.clearColor()

        let flow = UICollectionViewFlowLayout()
        collectionView.collectionViewLayout = flow
        collectionView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        flow.minimumInteritemSpacing = 1.0
        flow.minimumLineSpacing = 1.0

        do {
            try fetchedResultsController.performFetch()
        } catch {}

        fetchedResultsController.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        print("2")
        let annotation = MKPointAnnotation()
        annotation.coordinate = selectedPin.coordinate
        updateMap(annotation)
        loadPhotos(annotation)
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
        let parameters: [String:AnyObject] = [
            "method": Flickr.Resources.SearchPhotos,
            "api_key": Flickr.Constants.ApiKey!,
            "bbox": calculateBboxParameters(annotation.coordinate.latitude, longitude: annotation.coordinate.longitude),
            "extras": Flickr.Keys.Extras,
            "format": Flickr.Keys.Format,
            "nojsoncallback": Flickr.Keys.No_json_Callback,
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

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            return CGSize(width: 100, height: 100)
    }

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return UIEdgeInsetsZero
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        collectionView.reloadInputViews()
    }

    // MARK: Helpers

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
