//
//  LocationService.swift
//  Location_App
//
//  Created by Tushar Gusain on 30/01/20.
//  Copyright © 2020 Hot Cocoa Software. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceDelegate {
    func foundLocation(location: CLLocation?)
    func triggeredLocation(locationIdentifier: String, entered: Bool)
}

class LocationService: NSObject {
    
    //MARK:- Property Variables
    
    private var locationManager: CLLocationManager?
    private let distanceFilter = Constants.distanceFilter
    private let geofencingRadius = Constants.geofencingRadius
    private let pointsOfInterestDictionary = Constants.PointOfInterest.pointsOfInterestDictionary
    private var locationState = [String: Bool]()
    private let notificationService = NotificationService.shared
    
    static let shared = LocationService()
    var delegate: LocationServiceDelegate?
    
    
    //MARK:- Initializers
    
    private override init() { }
    
    //MARK:- Member Methods
    
    func startService() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            notificationService.startService()
        }
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = true
        handleAuthorization(status: CLLocationManager.authorizationStatus())
        
        for (key,_) in pointsOfInterestDictionary {
            locationState[key] = defaults.bool(forKey: "\(key)_status")
        }
    }
    
    func stopService() {
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
    
    private func handleAuthorization(status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.distanceFilter = distanceFilter
            locationManager?.startUpdatingLocation()
        } else {
            locationManager?.requestAlwaysAuthorization()
        }
    }
    
    private func checkTriggering(location: CLLocation?) {
        guard let currentLocation = location else { return }
        
        for (locationName,locationCoordinates) in pointsOfInterestDictionary {
            let distance = currentLocation.distance(from: locationCoordinates)
            let inside = distance <= Constants.geofencingRadius ? true : false
            let key = "\(locationName)_status"
            let wasInside = defaults.bool(forKey: key)
            
            if (wasInside && !inside) || (!wasInside && inside) {
                defaults.set(inside, forKey: key)
                delegate?.triggeredLocation(locationIdentifier: locationName, entered: inside)
            }
        }
    }
}

//MARK:- CLLocationManager Delegate Methods
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.first
        delegate?.foundLocation(location: currentLocation)
        checkTriggering(location: currentLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorization(status: status)
    }
}
