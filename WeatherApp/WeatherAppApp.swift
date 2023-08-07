//
//  WeatherApp.swift
//  WeatherApp

import SwiftUI

@main
struct Arunsapplication1App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            WeatherDetailOneView()
        }
    }
}
