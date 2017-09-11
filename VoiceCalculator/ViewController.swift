//
//  ViewController.swift
//  VoiceCalculator
//
//  Created by Przemysław Bartnik on 10.09.2017.
//  Copyright © 2017 Przemysław Bartnik. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var recordButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US_POSIX"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.speechRecognizer.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            if authStatus == .authorized{
                OperationQueue.main.addOperation() {
                    self.recordButton.isEnabled = true
                }
            } else {
                OperationQueue.main.addOperation() {
                    self.recordButton.isEnabled = false
                }
            }
        }
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func speechRecognizerButtonTapped(_ sender: Any) {
        var title = "enter the mathematical operation"
        if self.audioEngine.isRunning {
            self.audioEngine.stop()
            self.recognitionTask?.cancel()
        } else {
            title = "End"
            self.recordSpeech()
        }
        
        OperationQueue.main.addOperation {
            self.recordButton.titleLabel?.text = title
        }
    }

    func recordSpeech() {
        
        if self.recognitionTask != nil {
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        self.recognitionTask = self.speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                print(result!.bestTranscription.formattedString)

                self.evaluate(text: result!.bestTranscription.formattedString)
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start.")
        }
    }
    
    func evaluate(text:String){
        //([-+]?[0-9]*\\.?[0-9]+[\\/\\+\\-\\*])+([-+]?[0-9]*\\.?[0-9]+)
        let pattern = "([0-9]*\\.?[0-9]+[\\/\\+\\-\\*])+([-+]?[0-9]*\\.?[0-9]+)"
        var string = text
        
        string = string.replacingOccurrences(of: "\u{00D7}", with: "*")
        string = string.replacingOccurrences(of: "\u{00F7}", with: "/")
        
        if String(string.characters.prefix(4)) == "One "{
            string = string.replacingOccurrences(of: "One ", with: "1")
        }
        print(string)
        
        guard let range = string.range(of:pattern, options: .regularExpression) else {return}
        
        var result = string.substring(with:range)
        print("=======")
        
        
        let expn = NSExpression(format:result)
        print(result)
        print(expn.expressionValue(with: nil, context: nil)!)
        print("=======")
        
        
    }
    
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        OperationQueue.main.addOperation {
            self.recordButton.isEnabled = available
        }
    }
}

