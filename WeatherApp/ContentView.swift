//
//  ContentView.swift
//  WeatherApp
//
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

/*
 
 [
     {
         "id": 2801268,
         "name": "London",
         "region": "City of London, Greater London",
         "country": "United Kingdom",
         "lat": 51.52,
         "lon": -0.11,
         "url": "london-city-of-london-greater-london-united-kingdom"
     },
     {
         "id": 315398,
         "name": "London",
         "region": "Ontario",
         "country": "Canada",
         "lat": 42.98,
         "lon": -81.25,
         "url": "london-ontario-canada"
     },
     {
         "id": 2610925,
         "name": "Londonderry",
         "region": "New Hampshire",
         "country": "United States of America",
         "lat": 42.87,
         "lon": -71.37,
         "url": "londonderry-new-hampshire-united-states-of-america"
     }
 ]
 
 */
