//
//  Constants.swift
//  Location_App
//
//  Created by Tushar Gusain on 30/01/20.
//  Copyright © 2020 Hot Cocoa Software. All rights reserved.
//

import Foundation
import CoreLocation

struct Constants {
    
    static let distanceFilter = 1.0
    static let geofencingRadius = 100.0

    struct PointOfInterest {
        static let hotCocoa = CLLocation(latitude: 28.537750, longitude: 77.210376)
        static let dilshadGarden = CLLocation(latitude: 28.687507, longitude: 77.322567)
        static let dgMetro = CLLocation(latitude: 28.676190, longitude: 77.321492)
        
        static let pointsOfInterestDictionary = ["Hot Cocoa Software": hotCocoa, "Home Dilshad Garden": dilshadGarden, "Dilshad Garden Metro Station": dgMetro]
        
        static func getAllPointsOfInterest() -> [CLLocation] {
            let allPoi = [hotCocoa, dilshadGarden, dgMetro]
            return allPoi
        }
    }
}
