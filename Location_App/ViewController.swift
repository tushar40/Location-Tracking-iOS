//
//  ViewController.swift
//  Location_App
//
//  Created by Tushar Gusain on 30/01/20.
//  Copyright © 2020 Hot Cocoa Software. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import MapKit

class ViewController: UIViewController {
    
    //MARK:- IBOutlets
    
    @IBOutlet var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    @IBOutlet var positionInfoLabel: UILabel!
    
    //MARK:- Property Variables
    
    private let locationService = LocationService.shared
    private let poiDictionary = Constants.PointOfInterest.pointsOfInterestDictionary
    private var audioPlayer = AVAudioPlayer()
    private let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    private let identifier = "Marker"
    private var currentLocation: CLLocation! = Constants.PointOfInterest.hotCocoa
    
    //MARK:- Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setUpSound()
        addTriggerMarkers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationService.delegate = self
        locationService.startService()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        locationService.stopService()
        super.viewWillDisappear(animated)
    }
    
    //MARK:- Custom Methods
    
    private func setUpSound() {
        let soundPath = Bundle.main.path(forResource: "iphone_notification", ofType: "mp3")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: soundPath!))
        } catch {
            print(error)
        }
    }
    
    private func playSound() {
        audioPlayer.play()
    }
    
    private func setupMapView() {
        let currentCenter = currentLocation.coordinate
        mapView.setCenter(currentCenter, animated: true)
        let region = MKCoordinateRegion(center: currentCenter, span: coordinateSpan)
        mapView.setRegion(region, animated: true)
    }
    
    private func addTriggerMarkers() {
        for (key,value) in poiDictionary {
            let marker = TriggerPoint(title: key, locationName: key, discipline: identifier, coordinate: value.coordinate)
            mapView.addAnnotation(marker)
        }
    }
}

//MARK:- LocationServiceDelegate Methods

extension ViewController: LocationServiceDelegate {
    
    func foundLocation(location: CLLocation?) {
        if let atLocation = location {
            currentLocation =  atLocation
        }
    }
    
    func triggeredLocation(locationIdentifier: String, entered: Bool) {
        audioPlayer.play()
        let message = entered == true ? "Entered \(locationIdentifier)" : "Exited \(locationIdentifier)"
        positionInfoLabel.text = message
    }
}
 
//MARK:- MapView Delegate Methods

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? TriggerPoint else { return }
        positionInfoLabel.text = annotation.title
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? TriggerPoint else { return nil }
        var markerView: MKMarkerAnnotationView
        if let dequeueView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeueView.annotation = annotation
            markerView = dequeueView
        } else {
            markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            markerView.canShowCallout = true
            markerView.calloutOffset = CGPoint(x: -5, y: 5)
            markerView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            markerView.glyphText = String((annotation.title?.prefix(1))!)
        }
        return markerView
    }
}
