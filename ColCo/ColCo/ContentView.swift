//
//  ContentView.swift
//  ColCo
//
//  Created by Baluta Eugen on 09.03.2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            CameraView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
