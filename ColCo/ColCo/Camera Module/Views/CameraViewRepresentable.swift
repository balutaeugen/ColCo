//
//  CameraViewRepresentable.swift
//  ColCo
//
//  Created by Baluta Eugen on 09.03.2022.
//

import Foundation
import SwiftUI
import UIKit
import AVFoundation

struct CameraViewRepresentable: UIViewRepresentable {
    typealias UIViewType = UIView
    
    @State var captureSession: AVCaptureSession!
    @State var videoOutput: AVCaptureVideoDataOutput!
    @State var backCamera: AVCaptureDevice!
    @State var backInput : AVCaptureInput!
    
    @State var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Binding var color: Color
    @Binding var isSnapping: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        configureCaptureSession(context: context)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        updatePreviewLayer(for: uiView)
    }
    
    func makeCoordinator() -> VideoOutput {
        VideoOutput(isSnapping: $isSnapping, color: $color)
    }
}

extension CameraViewRepresentable {
    private func configureCaptureSession(context: Context) {
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession = AVCaptureSession()
            captureSession.beginConfiguration()
            
            // Configuration start
            captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            setCaptureSessionPreset()
            setupCaptureInputs()
            
            DispatchQueue.main.async {
                //setup preview layer
                self.setupPreviewLayer()
            }
            
            configureOutput(context: context)
            // Configuration end
            
            captureSession.commitConfiguration()
            
            captureSession.startRunning()
        }
    }
    
    private func setCaptureSessionPreset() {
        switch true {
        case captureSession.canSetSessionPreset(.hd4K3840x2160):
            captureSession.sessionPreset = .hd4K3840x2160
        case captureSession.canSetSessionPreset(.hd1920x1080):
            captureSession.sessionPreset = .hd1920x1080
        default: break
        }
    }
    
    private func setupCaptureInputs() {
        //get back camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            //handle this appropriately for production purposes
            fatalError("no back camera")
        }
        
        //now we need to create an input objects from our devices
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }
        
        //connect back camera input to session
        captureSession.addInput(backInput)
    }
    
    private func configureOutput(context: Context) {
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.name = "AVCaptureVideoPreviewLayer"
    }
    
    private func updatePreviewLayer(for view: UIView) {
        guard previewLayer != nil else { return }
        if !(view.layer.sublayers ?? []).contains(where: {$0.name == "AVCaptureVideoPreviewLayer"}) {
            view.layer.addSublayer(previewLayer)
        }
        previewLayer.frame = view.layer.frame
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.bounds = view.bounds
    }
}

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
        let context = CIContext(options: nil)
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        else { return }
        guard let color = cgImage.colors(at: [CGPoint(x: ciImage.extent.size.width / 2, y: ciImage.extent.size.height / 2)])?.first
        else { return }
        DispatchQueue.main.async { [weak self] in
            self?.isSnapping = false
            self?.color = Color(uiColor: color)
        }
        time = Date().timeIntervalSince1970
    }
}

extension CGImage {
    func colors(at: [CGPoint]) -> [UIColor]? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
            let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return nil
        }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return at.map { p in
            let i = bytesPerRow * Int(p.y) + bytesPerPixel * Int(p.x)

            let a = CGFloat(ptr[i + 3]) / 255.0
            let r = (CGFloat(ptr[i]) / a) / 255.0
            let g = (CGFloat(ptr[i + 1]) / a) / 255.0
            let b = (CGFloat(ptr[i + 2]) / a) / 255.0

            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
    }
}
