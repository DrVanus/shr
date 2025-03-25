//
//  SettingsView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  SettingsView.swift
//  CRYPTOSAI
//
//  Simple settings screen, toggling dark mode, etc.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Toggle("Dark Mode", isOn: $appState.isDarkMode)
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(AppState())
    }
}
