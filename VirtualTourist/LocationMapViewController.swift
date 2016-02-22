//
//  LocationMapViewController.swift
//  VirtualTourist
//
//  Created by Jefferson Bonnaire on 07/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import MapKit
import CoreData

let statusPhotosCollection = "statusPhotosCollection"

class LocationMapViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    var annotationPin = MKPointAnnotation()
    var editMode: Bool = false

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize delegate
        mapView.delegate = self
        fetchedResultsController.delegate = self

        // Gesture recognizer to drop pin on map
        let longTap: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addPin:")
        longTap.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longTap)

        do {
            try fetchedResultsController.performFetch()
        } catch {}

        // Load Pin on mapView
        mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [Pin])

        NSNotificationCenter.defaultCenter().addObserver(self, selector: nil, name: statusPhotosCollection, object: nil)
    }

    // Initialize CoreData and NSFetchedResultsController
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        return fetchedResultsController
    }()

    // MARK: Helpers

    @IBAction func editAction(sender: AnyObject) {
        editMode = editMode ? false : true
        if editMode {
            navigationController?.navigationBar.barTintColor = UIColor.redColor()
            navigationController?.navigationBar.tintColor = UIColor.whiteColor()
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
            navigationItem.title = "Tap pin to delete"
        } else {
            navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
            navigationController?.navigationBar.tintColor = UIColor.blueColor()
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
            navigationItem.title = "Virtual Tourist"
        }
    }

    func addPin(gestureRecognizer: UIGestureRecognizer) {

        if gestureRecognizer.state == .Began {
            let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
            annotationPin.coordinate = touchMapCoordinate

            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotation(self.annotationPin)
            })
        }

        else if gestureRecognizer.state == .Changed {

            let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
            annotationPin.coordinate = touchMapCoordinate

            dispatch_async(dispatch_get_main_queue(), {
                self.annotationPin.coordinate = touchMapCoordinate
            })
        }

        // When the Pin is drop when can add it to Core Data
        if gestureRecognizer.state == .Ended {

            let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)

            let pin = Pin(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, context: self.sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()

            Flickr.sharedInstance.loadPin(pin) { (success, error) -> Void in
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.showPhotoAlbum(pin)
                    })
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName(statusPhotosCollection, object: self)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.showPhotoAlbum(pin)
                    })
                }
            }
        }
    }

    func showPhotoAlbum(pin: Pin) {
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        nextView.selectedPin = pin
        self.navigationController?.pushViewController(nextView, animated: true)
    }

    func updatePin(pin: Pin) {
        mapView.removeAnnotation(pin)
        mapView.addAnnotation(pin)
    }
}

extension LocationMapViewController: MKMapViewDelegate {

    // MARK: Mapkit Delegate

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView){
        if editMode {
            sharedContext.deleteObject(view.annotation as! Pin)
            CoreDataStackManager.sharedInstance.saveContext()
        } else {
            if view.annotation!.isKindOfClass(Pin) {
                showPhotoAlbum(view.annotation as! Pin)
            } else {
                mapView.deselectAnnotation(view.annotation, animated: false)
            }
        }
    }
}

extension LocationMapViewController: NSFetchedResultsControllerDelegate {

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type){
        case .Insert:
            mapView.addAnnotation(anObject as! Pin)
        case .Delete:
            mapView.removeAnnotation(anObject as! Pin)
        case .Update:
            mapView.removeAnnotation(anObject as! Pin)
            mapView.addAnnotation(anObject as! Pin)
        case .Move:
            return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        mapView.reloadInputViews()
    }
}
