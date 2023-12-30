//
//  LocationsMapVC.swift
//  VirtualTourist
//
//  Created by admin on 12/19/20.
//  Copyright © 2020 Com.JeremyKievit. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationsMapVC: UIViewController {

    @IBOutlet weak var locationsMapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var annotations: [Annotation] = []
    var selectedAnnotation: Annotation!
    var dataController: DataController!
    private var userDidInitiateMapChange = false
    
    
    // MARK: View state
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on view appearance
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationsMapView.delegate = self
        
        // Long press gesture recognizer for adding annotations
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(geocodeGesture))
        locationsMapView.addGestureRecognizer(longGesture)
        
        // Restore map region if previously changed
        if UserDefaults.standard.value(forKey: "regionDidChange") != nil {
            let region = MapUserDefault.getRegion()
            locationsMapView.setRegion(region, animated: true)
        }
        
        // Fetch and display persisted annotations
        fetchAnnotations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on view disappearance
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    // MARK: Fetch persisted locations
    
    func fetchAnnotations() {
        // Fetch and display annotations from Core Data
        
        let fetchRequest: NSFetchRequest<Annotation> = Annotation.fetchRequest()
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            for annotation in result {
                let mapViewAnnotation = MKPointAnnotation()
                mapViewAnnotation.coordinate = CLLocationCoordinate2D(latitude: annotation.lat, longitude: annotation.long)
                self.locationsMapView.addAnnotation(mapViewAnnotation)
            }
        }
    }
    
    
    // MARK: Handle long gestures
    
    @objc func geocodeGesture(longGesture: UIGestureRecognizer) {
        // Handle long press gesture to add annotations
        
        if longGesture.state == UIGestureRecognizer.State.began {
            let touchPoint = longGesture.location(in: locationsMapView)
            let touchPointCoordinates = locationsMapView.convert(touchPoint, toCoordinateFrom: locationsMapView)

            // Reverse geocode to get location information
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: touchPointCoordinates.latitude, longitude: touchPointCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    DispatchQueue.main.async {
                        self.errorAlert(text: "Error", message: "Could not retrieve location coordinates", action: "OK")
                    }
                    return
                }
                
                // Save and display the new annotation
                self.saveAnnotation(at: touchPointCoordinates)
                self.addAnnotation(at: touchPointCoordinates)
            })
        }
    }
    
    func saveAnnotation(at touchPointCoordinates: CLLocationCoordinate2D) {
        // Save annotation to Core Data
        
        let annotation = Annotation(context: self.dataController.viewContext)
        annotation.lat = touchPointCoordinates.latitude
        annotation.long = touchPointCoordinates.longitude
        self.annotations.append(annotation)
        try? self.dataController.viewContext.save()
    }
    
    func addAnnotation(at touchPointCoordinates: CLLocationCoordinate2D) {
        // Add annotation to the map view
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchPointCoordinates
        self.locationsMapView.addAnnotation(annotation)
    }
}


// MARK: MapView delegate

extension LocationsMapVC: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Customize the appearance of map annotations
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }

        return pinView
    }

    // MARK: Handle annotation selections
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Handle the selection of a map annotation
        
        DispatchQueue.main.async { self.setDownloading(true) }
        
        // Create a new annotation for the selected location
        selectedAnnotation = Annotation(context: dataController.viewContext)
        selectedAnnotation.lat = view.annotation?.coordinate.latitude ?? 0
        selectedAnnotation.long = view.annotation?.coordinate.longitude ?? 0
        
        // Retrieve Flickr images for the selected location
        FlickrClient.retrieveFlickrImages(withCoordinates: self.selectedAnnotation.lat, self.selectedAnnotation.long, completion: self.handleFlickrSearchResponse(data:imageURLs:error:))
    }
    
    // MARK: Flickr client handlers
    
    func handleFlickrSearchResponse(data: Photos?, imageURLs: [URL]?, error: Error?) {
        guard let imageURLs = imageURLs else {
            setDownloading(false)
            DispatchQueue.main.async {
                self.errorAlert(text: "Error", message: "Network request failed", action: "OK")
            }
            return
        }

        // Display the retrieved images in a new view controller
        DispatchQueue.main.async {
            let controller: PhotoAlbumVC
            controller = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumVC") as! PhotoAlbumVC
            // data retrieved and sent to PhotoAlbumVC

            if imageURLs == [] {
                self.setDownloading(false)
                
                controller.imageURLs = []
                self.present(controller, animated: true, completion: nil)
                return
            }

            // Set the selected annotation and data controller for the photo
            self.selectedAnnotation.pages = Int64(data?.pages ?? 1)
            controller.self.selectedAnnotation = self.selectedAnnotation
            controller.self.dataController = self.dataController
            controller.imageURLs = imageURLs
            
            // Dismiss the activity indicator and present the photo album
            self.setDownloading(false)
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func setDownloading(_ downloading: Bool) {
        // Set the downloading state and disable map interactions
        
        if downloading {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
        
        self.locationsMapView.isZoomEnabled = !downloading
        self.locationsMapView.isScrollEnabled = !downloading
        self.locationsMapView.isUserInteractionEnabled = !downloading
    }
    
    // MARK: Handle map zoom level
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // Detect user-initiated map region changes
        
        userDidInitiateMapChange = mapViewRegionDidChangeFromUserInteraction()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Save the changed map region to user defaults
        
        if (userDidInitiateMapChange) {
            MapUserDefault.saveRegion(mapRegion: locationsMapView.region)
            UserDefaults.standard.setValue(true, forKey: "regionDidChange")
        }
    }
    
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        // Determine if the map region change is from user interaction
        
        let view = self.locationsMapView.subviews[0]
        
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
           for recognizer in gestureRecognizers {
            if( recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.ended ) {
                   return true
               }
           }
        }
        
        return false
    }
}

