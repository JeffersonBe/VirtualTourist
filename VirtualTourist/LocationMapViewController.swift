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

class LocationMapViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var annotationPin = MKPointAnnotation()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        mapView.delegate = self

        let longTap: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addPin:")
        longTap.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longTap)

        do {
            try fetchedResultsController.performFetch()
        } catch {}

        fetchedResultsController.delegate = self
        mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [Pin])
    }

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

    // MARK: Mapkit Delegate

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView){
        if ((view.annotation?.isKindOfClass(Pin)) != nil) {
            showPhotoAlbum(view.annotation as! Pin)
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.draggable = true
            pinView?.canShowCallout = false
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch (newState) {
        case .Starting:
            view.dragState = .Dragging
            print("Start")
        case .Ending, .Canceling:
            view.dragState = .None
            print("Finish")
        default: break
        }
    }

    // MARK: Helpers

    // Add Pin by using gestureRecognizer and translating Coordinate
    func addPin(gestureRecognizer: UIGestureRecognizer) {
        //If the touch has now ended
        if gestureRecognizer.state == .Began {

            //Get the spot that was pressed.
            let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
            annotationPin.coordinate = touchMapCoordinate

            //Add annotation to map
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotation(self.annotationPin)
            })
        }

            //If the touch has moved / changed once the touch has began
        else if gestureRecognizer.state == .Changed {

            //Check to make sure the pin has dropped

                //Get the coordinates from the map where we dragged over
                let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
                let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
            annotationPin.coordinate = touchMapCoordinate

                //Update the pin view
                dispatch_async(dispatch_get_main_queue(), {
                    self.annotationPin.coordinate = touchMapCoordinate
                })
        }

        if gestureRecognizer.state == .Ended {

            let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)

            let pin = Pin(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, context: sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
            showPhotoAlbum(pin)
        }
    }

    func showPhotoAlbum(pin: Pin) {
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        nextView.selectedPin = pin
        self.navigationController?.pushViewController(nextView, animated: true)
    }

    // MARK: NSFetchedResultsController delegate

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type){
        case .Insert:
            mapView.addAnnotation(anObject as! Pin)
        case .Delete:
            mapView.removeAnnotation(anObject as! Pin)
        case .Update:
            updatePin(anObject as! Pin)
        case .Move:
            return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        mapView.reloadInputViews()
    }

    func updatePin(pin: Pin) {
        mapView.removeAnnotation(pin)
        mapView.addAnnotation(pin)
    }
}
