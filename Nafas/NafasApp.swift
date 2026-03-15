//
//  NafasApp.swift
//  Nafas
//
//  Created by Rana Alngashy on 15/03/2026.
//

import SwiftUI
import Firebase

@main
struct NafasApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
   
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? =
    nil) -> Bool {
    FirebaseApp.configure()
      print("configured/// hi")
    return true
  }
}
