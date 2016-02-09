//
// PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jefferson Bonnaire on 07/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var toolBarButton: UIBarButtonItem!

    var annotation: MKPointAnnotation?
    var photos: AnyObject = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateMap(annotation!)
        loadPhotos(annotation!)
        collectionView.delegate = self
        collectionView!.registerClass(CustomCollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView.backgroundColor = UIColor.clearColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateMap(annotation: MKPointAnnotation) {
        mapView.showAnnotations([annotation], animated: true)
    }

    func loadPhotos(annotations: MKPointAnnotation) {

        guard let latitude = annotation?.coordinate.latitude, let longitude = annotation?.coordinate.longitude else {
            return
        }

        guard -180...180 ~= latitude || -90...90 ~= longitude else {
            return
        }

        let minlongitude = Int(longitude) * -1
        let minlatitude = Int(latitude) * -1
        let maxlongitude = Int(longitude)
        let maxlatitude = Int(latitude)

        let parameters: [String:AnyObject] = [
            "method": Flickr.Resources.SearchPhotos,
            "api_key": Flickr.Constants.ApiKey!,
            "bbox": "\(minlongitude),\(minlatitude),\(maxlongitude),\(maxlatitude)",
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

            dispatch_async(dispatch_get_main_queue()) {
                self.photos = photoArray
                self.collectionView.reloadData()
            }
        }
    }

    // MARK: CollectionView

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        print(photos[indexPath.row])
        if let filePath = photos[indexPath.row]["url_m"] as? String {
            Flickr.sharedInstance.taskForImage(filePath) { imageData, error in
                if let image = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView.image = UIImage(data: image)
                    }
                }
            }
        }
        return cell
    }
}
