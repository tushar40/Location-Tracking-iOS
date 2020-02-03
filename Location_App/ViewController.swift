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
    private let routeColor = Constants.routeColor
    private let routeLineWidth = Constants.routeLineWidth
    private var recordingOn = true
    private var currentRouteOverlay: MKPolyline?
    private var route = [CLLocationCoordinate2D](){
        didSet {
            addRoute()
        }
    }
    @IBAction func startAddingRoute(_ sender: UIBarButtonItem) {
        recordingOn = true
    }
    
    @IBAction func clearRoute(_ sender: Any) {
        recordingOn = false
        route = []
    }
    
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
        clearRoute(self)
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
    
    private func addRoute(sourceLocation: CLLocationCoordinate2D, destinationLocation: CLLocationCoordinate2D) {
        let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlaceMark = MKPlacemark(coordinate: destinationLocation)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
        let destinationMapItem = MKMapItem(placemark: destinationPlaceMark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            guard let response = response else {
                if let error = error {
                    print(error)
                }
                return
            }
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    private func addRoute() {
        print(route)
        if let currentPolyLine = currentRouteOverlay {
            mapView.removeOverlay(currentPolyLine)
        }
        if route.count < 1 {
            return
        }
        
        let myPolyLine = MKPolyline(coordinates: route, count: route.count)
        mapView.addOverlay(myPolyLine)
        currentRouteOverlay = myPolyLine
        
        let rect = myPolyLine.boundingMapRect
        self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
    }
}

//MARK:- LocationServiceDelegate Methods

extension ViewController: LocationServiceDelegate {
    
    func foundLocation(location: CLLocation?) {
        if let atLocation = location {
            let distanceMoved = currentLocation.distance(from: atLocation)
            print(currentLocation.coordinate, atLocation.coordinate)
            print("distance moved: ",distanceMoved)
            if distanceMoved > 0.0 && distanceMoved <= Constants.geofencingRadius / 5 {
//                addRoute(sourceLocation: currentLocation.coordinate, destinationLocation: atLocation.coordinate)
            }
            currentLocation =  atLocation
            if distanceMoved > 0.0 && distanceMoved <= Constants.geofencingRadius / 2 {
                if recordingOn {
                    route.append(currentLocation.coordinate)
                }
            }
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = routeColor
        renderer.lineWidth = routeLineWidth
        
        return renderer
    }
}
