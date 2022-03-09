//
//  CameraViewModel.swift
//  ColCo
//
//  Created by Baluta Eugen on 09.03.2022.
//

import Foundation
import SwiftUI

class CameraViewModel: ObservableObject {
    @Published var color: Color = .clear
    @Published var isSnapping = false
}
