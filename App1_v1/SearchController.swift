//
//  ViewController.swift
//  object_detector
//
//  Created by Mohammad Mohsen-Pour on 2020-01-03.
//  Copyright © 2020 Mohammad Mohsen-Pour. All rights reserved.
//

import UIKit
import AVKit
import Vision
import AVFoundation

extension UserDefaults {
    var counter2: Int {
        get {
            return integer(forKey: "counter2")
        }
        set {
            set(newValue, forKey: "counter2")
        }
    }
}

class SearchController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let synthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.counter2 = 0
        //setting up the camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video)
            else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice)
            else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        // display what the camera sees on the screen
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        // analyzing what the camera sees
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        setupLabel()
        
        
        
    }
    
    fileprivate func setupLabel(){
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -64).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    // delegate method that gets called everytime camera captures a frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if UserDefaults.standard.counter2 < 50
        {
            UserDefaults.standard.counter2 = UserDefaults.standard.counter2 + 1
            return
        }
        else{
            UserDefaults.standard.counter2 = 0
            // setup the ML model used for object detection and pass the captured frame to it for object detection to take place
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                else { return }
            guard let model = try? VNCoreMLModel(for: Resnet50().model)
                else { return }
            
            let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
                
                guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
                guard let firstObservation = results.first else { return }
                if firstObservation.confidence > 0.5
                {
                    DispatchQueue.main.async {
                        self.identifierLabel.text = "\(firstObservation.identifier)"
                    }
                    let utterance = AVSpeechUtterance(string: firstObservation.identifier)
                    self.synthesizer.speak(utterance)
                    
                }
                else
                {
                    DispatchQueue.main.async {
                        self.identifierLabel.text = "No objects detected!"
                    }
                    let utterance = AVSpeechUtterance(string: "No objects detected!")
                    self.synthesizer.speak(utterance)
                    
                }
            }
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        }
    }


}


