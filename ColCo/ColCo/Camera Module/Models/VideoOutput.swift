//
//  VideoOutput.swift
//  ColCo
//
//  Created by Baluta Eugen on 10.03.2022.
//

import Foundation
import SwiftUI
import UIKit
import AVFoundation

class VideoOutput: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Binding var isSnapping: Bool
    @Binding var color: Color
    
    var time: TimeInterval = 0
    
    init(isSnapping: Binding<Bool>, color: Binding<Color>) {
        self._isSnapping = isSnapping
        self._color = color
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        if !isSnapping { return }
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        else { return }
        
        let scale = ciImage.extent.size.height / UIScreen.main.bounds.width
        let scaledArea = CGSize(width: cameraArea.width * scale, height: cameraArea.height * scale)
        
        // The cropRect is the rect of the image to keep
        let cropRect = CGRect(
            x: ciImage.extent.size.width / 2 - scaledArea.width / 2,
            y: ciImage.extent.size.height / 2 - scaledArea.height / 2,
            width: scaledArea.width,
            height: scaledArea.height
        ).integral

        let sourceCGImage = cgImage
        let croppedCGImage = sourceCGImage.cropping(
            to: cropRect
        )!
        
        DispatchQueue.main.async { [weak self] in
            self?.isSnapping = false
            self?.color = Color(uiColor: UIImage(cgImage: croppedCGImage).getColors()?.background ?? .clear)
        }
        time = Date().timeIntervalSince1970
    }
}
