/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The settings view for this app's preferences window.
*/

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem {  Label("General", systemImage: "gear")   }
            ViewingSettings()
                .tabItem {  Label("Viewing", systemImage: "eyeglasses")   }
            CytometerSettings()
                .tabItem {  Label("Cytometers", systemImage: "slowmo")   }
            OutputSettings()
                .tabItem {  Label("Output", systemImage: "tray.and.arrow.up.fill")   }
        }
        .frame(width: 600, height: 200, alignment: .top)
    }
    
    private struct GeneralSettings: View {
        var body: some View {
            Text("The general settings") //.tag(Garden.ID?.none)
            Text("Dummy Text 1") //.tag(Garden.ID?.none)
        }
    }
    
    
    private struct ViewingSettings: View {
        var body: some View {
            Text("Viewing Settings go here") //.tag(Garden.ID?.none)
            Color.clear
        }
    }
    
    private struct CytometerSettings: View {
        var body: some View {
            Text("About Your Instrumentation")
            Color.clear
        }
    }
    private struct OutputSettings: View {
        var body: some View {
            Text("How to save your reports")
            Color.clear
        }
    }
}
