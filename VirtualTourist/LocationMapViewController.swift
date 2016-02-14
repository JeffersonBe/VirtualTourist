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
        mapView.addAnnotations(fetchAllPins())
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
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        nextView.selectedPin = view.annotation as! Pin
        self.navigationController?.pushViewController(nextView, animated: true)
    }

    // Add Pin by using gestureRecognizer and translating Coordinate
    func addPin(gestureRecognizer: UIGestureRecognizer) {
        guard gestureRecognizer.state != UIGestureRecognizerState.Began else {
            return
        }
        let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)

        let pin = Pin(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, context: sharedContext)
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = pin.latitude as Double
        annotation.coordinate.longitude = pin.longitude as Double

        CoreDataStackManager.sharedInstance.saveContext()
        mapView.addAnnotation(annotation)

        dispatch_async(dispatch_get_main_queue()) {
            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
            nextView.selectedPin = pin
            self.navigationController?.pushViewController(nextView, animated: true)        }
    }

    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("Error in fetchAllActors(): \(error)")
            return [Pin]()
        }
    }
}
