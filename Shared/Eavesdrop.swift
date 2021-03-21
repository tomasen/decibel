//
//  Eavesdrop.swift
//  decibel
//
//  Created by SHEN SHENG on 3/22/21.
//

import Foundation
import SwiftUI
import AVFoundation
import CoreData

class Eavesdrop: ObservableObject{
    private var viewContext = PersistenceController.shared.container.viewContext
    
    @Published var recording = false
    let tmpurl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    var timer: DispatchSourceTimer?
    var recorder: AVAudioRecorder?
    
    func Toggle() {
        if recording {
            Stop()
        } else {
            Start()
        }
    }
    
    func Start() {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setActive(true)
        }
        catch let err {
            // TODO: pop error
            print("Unable start recording", err)
            return
        }
        #endif
        
        let recordSettings = [
            AVSampleRateKey : NSNumber(value: Float(44100.0) as Float),
            AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC) as Int32),
            AVNumberOfChannelsKey : NSNumber(value: 1 as Int32),
            AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue) as Int32),
        ]
        
        do {
            let audioRecorder = try AVAudioRecorder(url: tmpurl, settings: recordSettings)
            audioRecorder.prepareToRecord()
            
            // workaround against Swift, AVAudioRecorder: Error 317: ca_debug_string: inPropertyData == NULL issue
            // https://stackoverflow.com/a/57670740/598057
            let firstSuccess = audioRecorder.record()
            if firstSuccess == false || audioRecorder.isRecording == false {
                audioRecorder.record()
            }
            
            if !audioRecorder.isRecording {
                print("unable to start recording")
                return
            }
            
            self.recorder = audioRecorder
            
            audioRecorder.isMeteringEnabled = true
            
            // delete tmp file since we only need to monitor sound level
            try FileManager.default.removeItem(atPath: tmpurl.path)
            
            keepRecording(audioRecorder: audioRecorder)
        } catch let err {
            print("Unable start recording", err)
            return
        }
        
        recording = true
    }
    
    func keepRecording(audioRecorder: AVAudioRecorder) {
        let queue = DispatchQueue(label: "org.tomasen.decibel", attributes: .concurrent)
        timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(5), leeway: .milliseconds(100))
        timer?.setEventHandler { [weak self] in
            audioRecorder.updateMeters()

             // NOTE: seems to be the approx correction to get real decibels
            let correction: Float = 100
            let average = audioRecorder.averagePower(forChannel: 0) + correction
            let peak = audioRecorder.peakPower(forChannel: 0) + correction
            self?.recordDatapoint(average: average, peak: peak)
        }
        timer?.resume()
    }
    
    func recordDatapoint(average: Float, peak: Float) {
        var filesize : UInt64 = 0
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: tmpurl.path) as NSDictionary
            filesize = attr.fileSize()
        } catch let err {
            print("Unable get file size", err)
        }
    
        print("recordDatapoint \(average), \(peak), \(filesize)")
        
        let req = NSFetchRequest<Decible>(entityName: "Decible")
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Decible.timestamp, ascending: false)]
        req.fetchLimit = 1
        do {
            let res = try viewContext.fetch(req) as [Decible]
            print("last power: \(res.first?.power ?? -1)")
            if res.first?.power == peak {
                // skip since there isn't any changes
                return
            }
        } catch let err {
            print("Unable fetch latest decible record", err)
        }
        
        let newItem = Decible(context: viewContext)
        newItem.timestamp = Date()
        newItem.power = peak

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func Stop() {
        if let recorder = recorder {
          recorder.stop()
        }

        recording = false
    }
}
