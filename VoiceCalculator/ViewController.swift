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
    
    @IBOutlet weak var actualOperation: UILabel!
    
    @IBOutlet weak var lastOperationsTableView: UITableView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US_POSIX"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    struct HistoryElement {
        var operation:String
        var result:String
    }
    
    fileprivate var lastOperations = [HistoryElement]()
    fileprivate var lastOperation = HistoryElement(operation: "", result: "")
    
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
            
            if self.lastOperation.operation != "" {
                //self.lastOperations.append(self.lastOperation)
                self.lastOperations.insert(self.lastOperation, at: 0)
                self.lastOperationsTableView.reloadData()
                self.lastOperation.operation = ""
            }
        } else {
            title = "End"
            self.recordSpeech()
        }
        
        OperationQueue.main.addOperation {
            self.recordButton.titleLabel?.text = title
            self.actualOperation.text = ""
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
        let pattern = "([0-9]*\\.?[0-9]+[\\\u{00F7}\\+\\-\\\u{00D7}])+([-+]?[0-9]*\\.?[0-9]+)"
        var string = text
        
        if String(string.characters.prefix(4)) == "One "{
            string = string.replacingOccurrences(of: "One ", with: "1")
        }
        
        guard let range = string.range(of:pattern, options: .regularExpression) else {return}
        
        let operationUnicode = string.substring(with:range)
        self.actualOperation.text = operationUnicode
        
        var operation = "1.0*"+operationUnicode
        
        operation = operation.replacingOccurrences(of: "\u{00D7}", with: "*")
        operation = operation.replacingOccurrences(of: "\u{00F7}", with: "/")
        
        
        let expn = NSExpression(format:operation)
        guard let result = expn.expressionValue(with: nil, context: nil) else {return}
        
        self.actualOperation.text = "\(operationUnicode) = \(result)"
        self.lastOperation.operation = operationUnicode
        self.lastOperation.result = "\(result)"
    }
    
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        OperationQueue.main.addOperation {
            self.recordButton.isEnabled = available
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lastOperations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "operationCell", for: indexPath) as? OperationCell else {
            return UITableViewCell()
        }
        
        cell.set(operation: self.lastOperations[indexPath.row].operation, result: self.lastOperations[indexPath.row].result)
        return cell
    }
}

