//
//  PushNotificationService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//
import Firebase
import FirebaseMessaging
import SwiftUI

class PushNotificationService: NSObject, MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: [AnyHashable : Any]) {
        print("📩 Push Notification Received!")
        print("📩 Message Data: \(remoteMessage)")
    }
}
