//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by admin on 12/20/20.
//  Copyright © 2020 Com.JeremyKievit. All rights reserved.
//

import Foundation

class FlickrClient {
    
    struct Auth {
        static var APIKey: String = "470a2895859806359270134c72a52ac0"
    }
    
    enum Endpoints {
        static let searchPhotosBase = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
        static let imageURLBase = "https://live.staticflickr.com/"
        
        case getSearcehdPhotos(String, Double, Double, Int, Int, Int)
        case imageURL(String, String, String)
        
        var stringValue: String {
            // Computed property to get the string value of the endpoint
            
            switch self {
            case .getSearcehdPhotos(let APIKey, let lat, let lon, let radius, let page, let perPage):
                return Endpoints.searchPhotosBase + "&api_key=\(APIKey)&lat=\(lat)&lon=\(lon)&radius=\(radius)&page=\(page)&per_page=\(perPage)&format=json&nojsoncallback=1"
            case .imageURL(let server, let id, let secret):
                return Endpoints.imageURLBase + "\(server)/\(id)_\(secret)_q.jpg"
            }
        }
        
        var url: URL {
            // Computed property to get the URL from the string value
            
            return URL(string: stringValue)!
        }
    }
    
    class func retrieveFlickrImages(withCoordinates lat: Double, _ long: Double, radius: Int = 5, page: Int = 1, perPage: Int = 150, completion: @escaping (_ data: Photos?, _
        ImageURLs: [URL]?, _ error: Error?) -> Void) {
        // Retrieving Flickr images based on coordinates
        
        // Create a URLRequest using the endpoint for searching photos
        var request = URLRequest(url: Endpoints.getSearcehdPhotos(Auth.APIKey, lat, long, radius, page, perPage).url)
        request.httpMethod = "GET"
        
        // URLSession data task for the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { completion(nil, nil, error); return }
            do {
                // Decode the JSON response into a FlickrSearchResponse object
                
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(FlickrSearchResponse.self, from: data)
                
                // Extract relevant data from the response
                let pages = responseObject.photos
                var imageURLs = [URL]()
                let photos = responseObject.photos.photo
                
                // Generate image URLs from photo details
                for photo in photos {
                    let url = Endpoints.imageURL(photo.server ?? "", photo.id ?? "", photo.secret!).url
                    imageURLs.append(url)
                }
                
                // Sending the retrieved image data to the completion handler
                completion(pages, imageURLs, nil)
            } catch {
               completion(nil, nil, error)
            }
        }
        task.resume() // Start the data task
    }
    
    class func downloadFlickrImages(imageURL: URL, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        // Create a URLSession data task for downloading the image
        
        let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
        guard let data = data else { completion(nil, error); return }
        
        // Call the completion handler with the downloaded image data
        completion(data, nil)
      }
      task.resume() // Start the data task
    }
}
