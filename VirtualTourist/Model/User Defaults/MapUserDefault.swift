//
//  MapUserDefault.swift
//  VirtualTourist
//
//  Created by admin on 12/26/20.
//  Copyright © 2020 Com.JeremyKievit. All rights reserved.
//

import Foundation
import MapKit

class MapUserDefault {
    struct Keys {
        static let latitude: String = "latitude"
        static let longitude: String = "longitude"
        static let latitudeDelta: String = "latitudeDelta"
        static let longitudeDelta: String = "longitudeDelta"
    }
    
    class func saveRegion(mapRegion: MKCoordinateRegion?) {
        if let mapRegion = mapRegion {
            UserDefaults.standard.set(mapRegion.center.latitude, forKey: Keys.latitude)
            UserDefaults.standard.set(mapRegion.center.longitude, forKey: Keys.longitude)
            UserDefaults.standard.set(mapRegion.span.latitudeDelta, forKey: Keys.latitudeDelta)
            UserDefaults.standard.set(mapRegion.span.longitudeDelta, forKey: Keys.longitudeDelta)
        }
    }
    
    class func getRegion() -> MKCoordinateRegion {
        var center = CLLocationCoordinate2D()
        center.latitude = UserDefaults.standard.value(forKey: Keys.latitude) as! CLLocationDegrees
        center.longitude = UserDefaults.standard.value(forKey: Keys.longitude) as! CLLocationDegrees
        
        var span = MKCoordinateSpan()
        span.latitudeDelta = UserDefaults.standard.value(forKey: Keys.latitudeDelta) as! CLLocationDegrees
        span.longitudeDelta = UserDefaults.standard.value(forKey: Keys.longitudeDelta) as! CLLocationDegrees
        
        let mapRegion = MKCoordinateRegion(center: center, span: span)
        
        return mapRegion
    }
}
