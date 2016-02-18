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

class LocationMapViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var mapView: MKMapView!
    var annotationPin = MKPointAnnotation()

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

            let pin = Pin(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, context: sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()

            Flickr.sharedInstance.loadPin(pin) { (success, error) -> Void in }
            showPhotoAlbum(pin)
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
        showPhotoAlbum(view.annotation as! Pin)
    }

    // TODO: - Implement drag functionality
    //    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
    //        let reuseId = "pin"
    //        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
    //        if pinView == nil {
    //            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
    //            pinView?.draggable = true
    //            pinView?.canShowCallout = false
    //        }
    //        else {
    //            pinView?.annotation = annotation
    //        }
    //
    //        return pinView
    //    }
    //
    //    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
    //        switch (newState) {
    //        case .Starting:
    //            view.dragState = .Dragging
    //            print("Start")
    //        case .Ending, .Canceling:
    //            view.dragState = .None
    //            print("Finish")
    //        default: break
    //        }
    //    }
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