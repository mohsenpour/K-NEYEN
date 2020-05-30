

import UIKit
import Speech
import AVKit
import Foundation
import CoreGraphics

class FirstScreenController: UIViewController, UITextFieldDelegate, AVAudioRecorderDelegate {
    //MARK: Properties

    @IBOutlet weak var transcribedTextView: UITextView!
    //    @IBOutlet weak var text_bar: UITextField!
    @IBOutlet weak var button_1: UIButton!
    
    // Used to playback audio from Polly
    var recordingSession: AVAudioSession!
    var audioPlayer = AVPlayer()
    
    // Spoken Text
    var spokenText: String!
    
    // Is the app listening flag
    var isListening = false
    
    // Language code
//    let langCode = Locale.current.languageCode
    
    // Speech stuff
    let speechRecognizer = SFSpeechRecognizer()!
    let audioEngine = AVAudioEngine()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var status = SpeechStatus.ready {
        didSet {
            //self.setUI(status: status)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Handle the text field’s user input through delegate callbacks.
//        text_bar.delegate = self
        
        // Check authorization for listening/recording audio on the device
        switch SFSpeechRecognizer.authorizationStatus() {
            case .notDetermined:
                askSpeechPermission()
            case .authorized:
                self.status = .ready
            case .denied, .restricted:
                self.status = .unavailable
        @unknown default:
            print("error")
        }
        
        // Initialize audio session
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.defaultToSpeaker);
            try recordingSession.setActive(true)
        } catch  {
            print("Exception setting up recordingSession")
        }
        
        
    }
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        transcribedTextView.text = textField.text
    }
    //MARK: Actions

    @IBAction func record(_ sender: UIButton) {
//        label_1.text = text_bar.text
        if !isListening {
            do {
                try startListening()
                button_1.setTitle("Stop Listening", for: .normal)
                print("Started listening")
            } catch  {
                print("Unexpected error: \(error)")
            }
        } else {
            button_1.setTitle("Start Listening", for: .normal)
            stopListening()
        }
    }
    func startListening() throws {
        
        isListening = true
//        togglePulse(pulse: true)
        print("listening...")
        // Setup Audio Session
        let node = audioEngine.inputNode
        
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.request.append(buffer) // Using SFSpeechAudioBufferRecognitionRequest()
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        // This is the workhorse doing ALL the work while the listening session is active and after if completes (ended manually or timesout)
        // Every word that is recognized by the Speech API will be passed in here.
        recognitionTask = speechRecognizer.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result
            {
                print(result.bestTranscription.formattedString)
                
                // Display the live text being transcribed
                DispatchQueue.main.async() {
                    self.transcribedTextView.text = result.bestTranscription.formattedString
                }
                
                if result.isFinal {
                    let finalString = result.bestTranscription.formattedString
                    print("Here's the final recognized text:\n\(finalString)")
                    
                    // This handles stopping the session automatically if the OS stops listening after about 1 minute and the users has not manually stopped the listening session by tapping the microphone
                    if(self.isListening){
                        self.stopListening()
                    }
                    
                    // Display the final transcribed text for this session
                    DispatchQueue.main.async() {
                        self.transcribedTextView.text = result.bestTranscription.formattedString
                    }
                
                    // Send final transcribed text to Amazon Translate
//                    self.translateText(spokenText: finalString, targetLanguage: self.destinationLanguage)
                }
            }
        })
    }
    func stopListening() {
//        togglePulse(pulse: false)
        isListening = false
        audioEngine.stop()
        request.endAudio()
        //recognitionTask?.cancel()
        audioEngine.inputNode.removeTap(onBus: 0) // Required to record more than one session
        print("Stopped listening")
        if transcribedTextView.text == "Search"
        {
            performSegue(withIdentifier: "start_search", sender: Any?.self)
        }
        else if transcribedTextView.text == "Detect"
        {
            performSegue(withIdentifier: "start_detect", sender: Any?.self)
        }
        else if transcribedTextView.text == "Read"
        {
            performSegue(withIdentifier: "start_read", sender: Any?.self)
        }
        
    }
    
    func playAudio(audioURL: URL) {
        let player = AVPlayer(url: audioURL)
        player.allowsExternalPlayback = true
        let vc = AVPlayerViewController()
        vc.player = player
        
        vc.player?.play()
    }
    
    func askSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.status = .ready
                default:
                    self.status = .unavailable
                }
            }
        }
    }
    enum Oops: Error {
        case FoundNil(String)
    }
    
    enum SpeechStatus {
        case ready
        case recognizing
        case unavailable
    }
    
    

}


