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

let cameraArea = CGSize(width: 50, height: 50)

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
        captureSession.sessionPreset = .hd1920x1080
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
