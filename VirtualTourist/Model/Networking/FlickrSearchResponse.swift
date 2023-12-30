//
//  FlickrSearchResponse.swift
//  VirtualTourist
//
//  Created by admin on 12/20/20.
//  Copyright © 2020 Com.JeremyKievit. All rights reserved.
//

import Foundation

struct FlickrSearchResponse: Decodable {
    let photos: Photos
}

struct Photos: Decodable {
    let pages: Int?
    let perpage: Int?
    let photo: [Photo]
}

struct Photo: Decodable {
    let id: String?
    let secret: String?
    let server: String?
    let title: String?
}
