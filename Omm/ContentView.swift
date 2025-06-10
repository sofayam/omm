import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @State private var numberOfGongs = 3
    @State private var intervalMinutes = 2
    @State private var isRunning = false
    @State private var currentGong = 0
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var finalAudioPlayer: AVAudioPlayer?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let gongOptions = Array(1...10)
    let intervalOptions = Array(1...10)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Omm")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Number of Gongs:")
                            .font(.headline)
                        Spacer()
                        Picker("Gongs", selection: $numberOfGongs) {
                            ForEach(gongOptions, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(isRunning)
                    }
                    
                    HStack {
                        Text("Interval (minutes):")
                            .font(.headline)
                        Spacer()
                        Picker("Interval", selection: $intervalMinutes) {
                            ForEach(intervalOptions, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(isRunning)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                if isRunning {
                    VStack(spacing: 15) {
                        Text("Session Active")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Gong \(currentGong + 1) of \(numberOfGongs)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Text("until next gong")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                }
                
                Button(action: isRunning ? stopSession : startSession) {
                    Text(isRunning ? "Stop Session" : "Start Session")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRunning ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear(perform: setupAudio)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Audio Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Setup regular gong sound
            if let gongPath = Bundle.main.path(forResource: "Chime", ofType: "mp3") {
                let gongUrl = URL(fileURLWithPath: gongPath)
                audioPlayer = try AVAudioPlayer(contentsOf: gongUrl)
                audioPlayer?.prepareToPlay()
            }
            
            // Setup final gong sound
            if let finalGongPath = Bundle.main.path(forResource: "EndChime", ofType: "mp3") {
                let finalGongUrl = URL(fileURLWithPath: finalGongPath)
                finalAudioPlayer = try AVAudioPlayer(contentsOf: finalGongUrl)
                finalAudioPlayer?.prepareToPlay()
            }
        } catch {
            alertMessage = "Could not setup audio: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    func startSession() {
        isRunning = true
        currentGong = 0
        timeRemaining = intervalMinutes * 60
        
        // Keep screen awake during meditation
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Play first gong immediately
        playGong()
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Time for next gong
                currentGong += 1
                
                if currentGong < numberOfGongs - 1 {
                    // Play regular gong and reset timer
                    playGong()
                    timeRemaining = intervalMinutes * 60
                } else {
                    // Play final gong and end session immediately
                    playGong()
                    stopSession()
                }
            }
        }
    }
    
    func stopSession() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        currentGong = 0
        timeRemaining = 0
        
        // Allow screen to sleep again
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func playGong() {
        if currentGong == numberOfGongs - 1 {
            // Play final gong
            finalAudioPlayer?.stop()
            finalAudioPlayer?.currentTime = 0
            finalAudioPlayer?.play()
        } else {
            // Play regular gong
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
        }
    }
    
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

