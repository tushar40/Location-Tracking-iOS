//
//  NotificationService.swift
//  Location_App
//
//  Created by Tushar Gusain on 03/02/20.
//  Copyright © 2020 Hot Cocoa Software. All rights reserved.
//

import Foundation
import UserNotifications
import CoreLocation.CLLocation

class NotificationService: NSObject {
    
    //MARK:- Property Variables
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var permissionGranted = false
    static let shared = NotificationService()
    
    //MARK:- Initializers
    
    private override init() { }
    
    //MARK:- Member Methods
    
    func startService() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Granted notification Permission")
                self.permissionGranted = true
            } else {
                print("Didn't grant notification Permission")
                self.permissionGranted = false
            }
        }
    }
    
    func addNotification(radius: Double, region: CLCircularRegion) {
        if permissionGranted {
            let content = UNMutableNotificationContent()
            content.title = region.identifier
            content.subtitle = "\(region.center.latitude), \(region.center.longitude)"
            content.body = "At location: \(region.identifier)"
            content.sound = UNNotificationSound.default //(named: UNNotificationSoundName(rawValue: "iphone_notification.mp3"))
            
            let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
            let request = UNNotificationRequest(identifier: "\(region.identifier)_notify", content: content, trigger: trigger)
            notificationCenter.add(request, withCompletionHandler: nil)
        }
    }
}
