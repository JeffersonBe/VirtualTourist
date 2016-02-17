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
    @IBOutlet weak var statusPhotoLabel: UILabel!

    var selectedPin: Pin!
    var resultCount: Int?
    var arrayPhotoToDelete: [NSIndexPath] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView!.registerClass(CustomCollectionViewCell.self,forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.allowsMultipleSelection = true

        let flow = UICollectionViewFlowLayout()
        collectionView.collectionViewLayout = flow
        collectionView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        flow.minimumInteritemSpacing = 1.0
        flow.minimumLineSpacing = 1.0

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error")
        }

        fetchedResultsController.delegate = self

        if resultCount == 0 || resultCount == nil {
            statusPhotoLabel.hidden = false
            statusPhotoLabel.text = "Cannot find Photos in this location"
            toolBarButton.enabled = false
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(true)
        showMap(selectedPin)
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "locations == %@", self.selectedPin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        return fetchedResultsController

    }()

    @IBAction func toolbarButtonAction(sender: AnyObject) {
        if toolBarButton.title == "New Collection" {
            for photo in fetchedResultsController.fetchedObjects!{
                sharedContext.deleteObject(photo as! NSManagedObject)
            }
            CoreDataStackManager.sharedInstance.saveContext()
            loadPhotos(selectedPin)
        } else {
            for photo in arrayPhotoToDelete {
                sharedContext.deleteObject(fetchedResultsController.objectAtIndexPath(photo) as! NSManagedObject)
            }
            CoreDataStackManager.sharedInstance.saveContext()
            arrayPhotoToDelete.removeAll()
            updateToolbar()
        }
    }
    // MARK: CollectionView delegate

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        cell.clipsToBounds = true
        cell.alpha = 0.0
        configureCell(cell, withPhoto: photo)
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            cell?.alpha = 0.5
            }, completion: nil)
        arrayPhotoToDelete.append(indexPath)
        updateToolbar()
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            cell?.alpha = 1.0
            }, completion: nil)
        arrayPhotoToDelete.removeAtIndex(arrayPhotoToDelete.indexOf(indexPath)!)
        updateToolbar()
    }

    func updateToolbar() {
        if arrayPhotoToDelete.count >= 1 {
            toolBarButton.title = "Remove Selected Pictures"
        } else {
            toolBarButton.title = "New Collection"
        }
    }

    func configureCell(cell: CustomCollectionViewCell, withPhoto photo: Photo) {
        if photo.image != nil {
            dispatch_async(dispatch_get_main_queue()) {
                cell.imageView.image = photo.image
                UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    cell.alpha = 1.0
                    }, completion: nil)
            }
        } else {
            Flickr.sharedInstance.taskForImage(photo.imageUrl) { imageData, error in
                if let image = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView.image = UIImage(data: image)
                        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                            cell.alpha = 1.0
                            }, completion: nil)
                    }
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

    // MARK: NSFetchedResultsController delegate
    // Used GIST: https://gist.github.com/AppsTitude/ce072627c61ea3999b8d#file-uicollection-and-nsfetchedresultscontrollerdelegate-integration-swift-L78

    var blockOperations: [NSBlockOperation] = []

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        if type == NSFetchedResultsChangeType.Insert {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Update {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Move {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Delete {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

        if type == NSFetchedResultsChangeType.Insert {

            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Update {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Delete {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: NSBlockOperation in self.blockOperations {
                operation.start()
            }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepCapacity: false)
        })
    }

    deinit {
        // Cancel all block operations when VC deallocates
        for operation: NSBlockOperation in blockOperations {
            operation.cancel()
        }

        blockOperations.removeAll(keepCapacity: false)
    }
    

    // MARK: Helpers

    func showMap(annotation: MKAnnotation) {
        mapView.showAnnotations([annotation], animated: true)
    }

    func loadPhotos(annotation: MKAnnotation) {

        let parameters: [String:AnyObject] = [
            "method": Flickr.Resources.SearchPhotos,
            "api_key": Flickr.Constants.ApiKey!,
            "bbox": Flickr.sharedInstance.calculateBboxParameters(annotation.coordinate.latitude, longitude: annotation.coordinate.longitude),
            "extras": Flickr.Keys.Extras,
            "format": Flickr.Keys.Format,
            "nojsoncallback": Flickr.Keys.No_json_Callback,
            "page": Int(arc4random_uniform(5)),
            "per_page": 30
        ]

        Flickr.sharedInstance.taskForResource(parameters) { parsedResult, error in

            // Handle the error case
            if let error = error {
                print("Error searching for Images: \(error.localizedDescription)")
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
        }
    }
}
