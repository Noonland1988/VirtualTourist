//
//  UserDefaults.swift
//  VirtualTourist
//
//  Created by 嶋田省吾 on 2021/12/29.
//

import Foundation
import MapKit

class UserDefaultsHandling{
    
    // MARK: checking initial launch or regular launch

    public static func checkRegular() {
        let regular = UserDefaults.standard.bool(forKey: "regular")
        if  regular == true {
            print("regular launch \(regular)")
            AppDelegate.launchRegion = loadLatestRegion()
            
        } else {
            print("initial launch")
            AppDelegate.launchRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35, longitude: 139), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
            UserDefaults.standard.set(true, forKey: "regular")
            
        }
        
    }
    
    // MARK: saving current region for next launch region
    
    public static func saveLaunchRegion(region: MKCoordinateRegion) {
        UserDefaults.standard.set(Double(region.center.longitude), forKey: "centerLongitude")
        UserDefaults.standard.set(Double(region.center.latitude), forKey: "centerLatitude")
        UserDefaults.standard.set(Double(region.span.longitudeDelta), forKey: "longitudeDelta")
        UserDefaults.standard.set(Double(region.span.latitudeDelta), forKey: "latitudeDelta")
    }
    
    public static func loadLatestRegion() -> MKCoordinateRegion {
        let centerLongitude = UserDefaults.standard.double(forKey: "centerLongitude")
        let centerLatitude = UserDefaults.standard.double(forKey: "centerLatitude")
        let spanLongitude = UserDefaults.standard.double(forKey: "longitudeDelta")
        let spanLatitude = UserDefaults.standard.double(forKey: "latitudeDelta")
       return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude), span: MKCoordinateSpan(latitudeDelta: spanLatitude, longitudeDelta: spanLongitude))
        
    }
    
}


