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
    private let myPositionIdentifier = "My_Position"
    private var currentLocation = Constants.PointOfInterest.hotCocoa
    private let routeColor = Constants.routeColor
    private let routeLineWidth = Constants.routeLineWidth
    private var recordingOn = true
    private var currentRouteOverlay = [MKPolyline]()
    private var route = [CLLocationCoordinate2D](){
        didSet {
            addRoute()
        }
    }
    
    //MARK:- IBActions
    
    @IBAction func startAddingRoute(_ sender: UIBarButtonItem) {
        UIView.animate(withDuration: 0.7, animations: {
            sender.tintColor = .clear
        }, completion: { [weak self] _ in
            sender.tintColor = .blue
            self?.recordingOn = true
        })
    }
    
    @IBAction func clearRoute(_ sender: Any) {
        if let senderButton = sender as? UIBarButtonItem {
            UIView.animate(withDuration: 0.7, animations: {
                senderButton.tintColor = .clear
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                senderButton.tintColor = .red
                self.recordingOn = false
                self.route = [self.currentLocation.coordinate]
            })
        }
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
    
    private func addRoute() {
        print(route)
        if route.count < 2 {
            for currentPolyLine in currentRouteOverlay {
                mapView.removeOverlay(currentPolyLine)
            }
            currentRouteOverlay = []
            return
        }
        let n = route.count
        let area = [route[n - 2], route[n - 1]]
        let myPolyLine = MKPolyline(coordinates: area, count: area.count)
        mapView.addOverlay(myPolyLine)
        currentRouteOverlay.append(myPolyLine)
        
//        let rect = myPolyLine.boundingMapRect
//        mapView.setRegion(MKCoordinateRegion(rect), animated: true)
    }
}

//MARK:- LocationServiceDelegate Methods

extension ViewController: LocationServiceDelegate {
    
    func foundLocation(location: CLLocation?) {
        if let atLocation = location {
            let distanceMoved = currentLocation.distance(from: atLocation)
            print(currentLocation.coordinate, atLocation.coordinate)
            currentLocation =  atLocation
//            if distanceMoved >= Constants.distanceFilter && distanceMoved <= Constants.geofencingRadius / 4 {
                if recordingOn {
                    route.append(currentLocation.coordinate)
                }
//            }
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
        
        //// annotation markers for point of interests
        if let annotation = annotation as? TriggerPoint {
            var markerView: MKMarkerAnnotationView
            if let dequeueView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                dequeueView.annotation = annotation
                markerView = dequeueView
            } else {
                markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                markerView.canShowCallout = true
                markerView.calloutOffset = CGPoint(x: 0, y: 10)
                markerView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                markerView.glyphText = String((annotation.title?.prefix(1))!)
            }
            return markerView
        }
        
        //// annotation marker for current location
        var markerView: MKAnnotationView
        if let dequeueView = mapView.dequeueReusableAnnotationView(withIdentifier: myPositionIdentifier) {
            dequeueView.annotation = annotation
            markerView = dequeueView
        } else {
            markerView = MKAnnotationView(annotation: annotation, reuseIdentifier: myPositionIdentifier)
            markerView.canShowCallout = true
            markerView.calloutOffset = CGPoint(x: 0, y: 10)
            markerView.image = UIImage(named: "car_icon")
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
