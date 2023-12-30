//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by admin on 12/19/20.
//  Copyright © 2020 Com.JeremyKievit. All rights reserved.
//

import Foundation
import UIKit
import CoreData
 
class PhotoAlbumVC: UIViewController {
    
    @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    let cellReuseIdentifier = "collectionViewCell"
    var selectedAnnotation: Annotation!
    var imageURLs: [URL?] = []
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<FlickrImage>!
    var currentPage: Int = 1
    var itemCount: Int = 0
    
    
    // MARK: View state
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        newCollectionButton.isEnabled = false
        noImagesLabel.text = ""
        photoAlbumCollectionView.bounces = false
        
        setCollectionState()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Clear fetched results controller on disappearance
        
        fetchedResultsController = nil
        noImagesLabel.text = ""
    }
       
    func setUpFetchedResultsController() {
        // Set up the fetched results controller based on selected annotation
        
        let fetchRequest: NSFetchRequest<FlickrImage> = FlickrImage.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "annotation", ascending: false)
        let predicate = NSPredicate(format: "annotation == %@", selectedAnnotation)

        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "flickrImages")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            self.photoAlbumCollectionView.reloadData()
        } catch {
            DispatchQueue.main.async {
               self.errorAlert(text: "Error", message: "Coult not retrieve Flickr images", action: "OK")
            }
        }
   }
    
    func setCollectionState() {
        // Set the initial state of the photo collection
        
        if imageURLs == [] {
            newCollectionButton.setTitle("", for: .normal)
            noImagesLabel.text = "No Images at this Location"
            return
        }
        
        if currentPage == 1 {
            setUpFetchedResultsController()
        }
        
        //Objects instantiated and inserted into collection as placeholders
        for _ in self.imageURLs {
                let flickrImage = FlickrImage(context: self.dataController.viewContext)
                flickrImage.annotation = self.selectedAnnotation
                try? self.dataController.viewContext.save()
        }
        
        if selectedAnnotation.pages == 1 {
            DispatchQueue.main.async {
                self.newCollectionButton.setTitle("Reload Collection", for: .normal)
                self.newCollectionButton.isEnabled = true
            }
        } else {
            DispatchQueue.main.async {
                self.newCollectionButton.setTitle("New Collection", for: .normal)
                self.newCollectionButton.isEnabled = true
            }
        }
     }
    
    
    //MARK: New collection button
    
    @IBAction func newCollection(_ sender: Any) {
        if self.selectedAnnotation.pages > currentPage {
            currentPage += 1
        } else if self.selectedAnnotation.pages == currentPage {
            currentPage = 1
        }
        
        // Retrieve new Flickr images based on the selected annotation and current page
        FlickrClient.retrieveFlickrImages(withCoordinates: selectedAnnotation.lat, selectedAnnotation.long, page: currentPage, completion: handleFlickrSearchResponse(data:imageURLs:error:))
    }

    func handleFlickrSearchResponse(data: Photos?, imageURLs: [URL]?, error: Error?) {
        // Handle the response from the Flickr image search
        
        guard let imageURLs = imageURLs else {
          DispatchQueue.main.async {
              self.errorAlert(text: "Error", message: "Network request failed", action: "OK")
          }
          return
        }

        if imageURLs == [] {
          DispatchQueue.main.async {
              self.newCollectionButton.setTitle("", for: .normal)
              self.noImagesLabel.text = "No Images at this Location"
                self.imageURLs = []
          }
        }

        // Delete fetched images
        DispatchQueue.main.async {
            // Delete fetched images
            
            if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
                
                for flickrImage in fetchedObjects {
                        self.dataController.viewContext.delete(flickrImage)
                        self.itemCount -= 1
                        try? self.dataController.viewContext.save()
                }
            }
        }
        
        DispatchQueue.main.async {
            // Update the collection state with new images
            
            self.itemCount = 0
            self.imageURLs = imageURLs
            self.setCollectionState()
        }
    }
    
    
    // MARK: Dismiss collection button
    
    @IBAction func dismiss(_ sender: Any) {
        // Dismiss the photo album view controller
        
        self.currentPage = 1
        self.itemCount = 0
        
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}


// MARK: Collection view delegate
 
extension PhotoAlbumVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellReuseIdentifier, for: indexPath as IndexPath) as! ImageViewCell
        
        if let data = self.fetchedResultsController.object(at: indexPath).data {
            cell.imageView.image = UIImage(data: data)
        } else {
            if let url = self.imageURLs[indexPath.row] {
                DispatchQueue.main.async {
                    
                    cell.activityIndicator.startAnimating()
                    cell.imageView.image = UIImage(named: "placeholder")
                }
                DispatchQueue.global(qos: .background).async {
//                  Images downloaded and saved in background queue and displayed on the main queue
                    FlickrClient.downloadFlickrImages(imageURL: url) { data, error in
                        guard let data = data else { return }
                        
                        self.fetchedResultsController.object(at: indexPath).data = data
                        try? self.dataController.viewContext.save()
                        
                        DispatchQueue.main.async {
                            cell.activityIndicator.stopAnimating()
                            cell.imageView.image = UIImage(data: data)
                        }
                    }
                }
            }
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Delete image on selection
        
        deleteImage(at: indexPath)
    }
    
    func deleteImage(at indexPath: IndexPath) {
        // Delete image at a given index path
        
        let imageToDelete = fetchedResultsController.object(at: indexPath)
        self.itemCount -= 1
        dataController.viewContext.delete(imageToDelete)
        try? dataController.viewContext.save()
    }
}

 
// MARK: Fetched results controller delegate
 
extension PhotoAlbumVC: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // Respond to changes in the fetched results controller
        
        switch type {
        case .insert:
                if (newIndexPath != nil) {
                    DispatchQueue.main.async {
                        self.itemCount += 1
                        self.photoAlbumCollectionView.insertItems(at: [newIndexPath!])
                    }
                }
        case .delete:
                if ((indexPath != nil)) {
                        self.photoAlbumCollectionView.deleteItems(at: [indexPath!])
                }
        case .update:
                if ((indexPath != nil)) {
                        self.photoAlbumCollectionView.reloadItems(at: [newIndexPath!])
                }
        default:
            break
        }
    }
}
