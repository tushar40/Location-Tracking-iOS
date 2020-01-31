//
//  TriggerPoint.swift
//  Location_App
//
//  Created by Tushar Gusain on 31/01/20.
//  Copyright © 2020 Hot Cocoa Software. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class TriggerPoint: NSObject, MKAnnotation {
    
    //MARK:- Property Variables
    
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    var subtitle: String? {
        locationName
    }
    
    //MARK:- Initializer
    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        super.init()
    }
}
