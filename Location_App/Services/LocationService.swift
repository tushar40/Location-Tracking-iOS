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
    private var monitoringStarted = false
    private let geofencingRadius = Constants.geofencingRadius
    static let shared = LocationService()
    var delegate: LocationServiceDelegate?
    
    
    //MARK:- Initializers
    
    private override init() { }
    
    //MARK:- Member Methods
    
    func startService() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = true
        handleAuthorization(status: CLLocationManager.authorizationStatus())
    }
    
    func stopService() {
        stopMonitoringRegions()
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
    
    private func handleAuthorization(status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.distanceFilter = distanceFilter
            locationManager?.startUpdatingLocation()
            if !monitoringStarted {
                startMonitoringRegions()
                monitoringStarted = true
            }
        } else {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    private func startMonitoringRegions() {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let maxDistance = locationManager?.maximumRegionMonitoringDistance
            let radius = maxDistance == nil || geofencingRadius < maxDistance! ? geofencingRadius : maxDistance!
            let poi = Constants.PointOfInterest.pointsOfInterestDictionary
            for (key,value) in poi {
                let region = CLCircularRegion(center: value.coordinate, radius: radius, identifier: key)
                region.notifyOnEntry = true
                region.notifyOnExit = true
                locationManager?.startMonitoring(for: region)
            }
        }
    }
    
    private func stopMonitoringRegions() {
        for region in locationManager!.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion else { continue }
            locationManager?.stopMonitoring(for: circularRegion)
        }
    }
}

//MARK:- CLLocationManager Delegate Methods
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.first
        delegate?.foundLocation(location: currentLocation)
        let distance = currentLocation?.distance(from: Constants.PointOfInterest.hotCocoa)
        print(distance)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorization(status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered:",region.identifier)
        delegate?.triggeredLocation(locationIdentifier: region.identifier, entered: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited:",region.identifier)
        delegate?.triggeredLocation(locationIdentifier: region.identifier, entered: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("monitoring started for:",region.identifier)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("failed to start monitoring")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("failed to start location manager")
    }
}
