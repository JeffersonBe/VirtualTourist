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
            let fetchedPhotoResultsController: NSFetchedResultsController = {

                let fetchRequest = NSFetchRequest(entityName: "Photo")
                fetchRequest.predicate = NSPredicate(format: "locations == %@", view.annotation as! Pin)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

                let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                    managedObjectContext: self.sharedContext,
                    sectionNameKeyPath: nil,
                    cacheName: nil)
                
                return fetchedResultsController
            }()

            do {
                try fetchedPhotoResultsController.performFetch()
            } catch {}

            showPhotoAlbum(view.annotation as! Pin, resultCount: fetchedPhotoResultsController.fetchedObjects?.count)
        }
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

        if gestureRecognizer.state == .Ended {

            let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)

            let pin = Pin(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, context: sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
            let number = preloadPhoto(pin)
            showPhotoAlbum(pin, resultCount: number)
        }
    }

    func showPhotoAlbum(pin: Pin, resultCount: Int?) {
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        nextView.selectedPin = pin
        nextView.resultCount = resultCount

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

    // MARK: - Helpers
    func preloadPhoto(pin: Pin) -> Int {
        var number: Int = 0
        
        let parameters: [String:AnyObject] = [
            "method": Flickr.Resources.SearchPhotos,
            "api_key": Flickr.Constants.ApiKey!,
            "bbox": Flickr.sharedInstance.calculateBboxParameters(pin.latitude, longitude: pin.longitude),
            "extras": Flickr.Keys.Extras,
            "format": Flickr.Keys.Format,
            "nojsoncallback": Flickr.Keys.No_json_Callback,
            "page": Int(arc4random_uniform(10)),
            "per_page": 30
        ]

        Flickr.sharedInstance.taskForResource(parameters) { parsedResult, error in

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
                photo.locations = pin
                return photo
            }

            number = photoArray.count

            // Save managed object context
            CoreDataStackManager.sharedInstance.saveContext()
        }
        return number
    }
}
