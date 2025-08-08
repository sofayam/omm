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
    @State private var streamPlayer: AVPlayer?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    private let streamURL = "http://air.local:3000/stream"
    @State private var isStreamPlaying = false
    @State private var streamVolume: Double = 0.5
    @State private var volumeFadeTimer: Timer?
    @State private var stopMusicAfterSession = true

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
                
                VStack(spacing: 10) {
                    Button(action: toggleStream) {
                        Text(isStreamPlaying ? "Pause Background Music" : "Play Background Music")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isStreamPlaying ? Color.orange : Color.green)
                            .cornerRadius(10)
                    }
                    
                    HStack {
                        Text("Volume")
                        Slider(value: $streamVolume, in: 0...1)
                            .onChange(of: streamVolume) { newVolume in
                                streamPlayer?.volume = Float(newVolume)
                            }
                    }
                    .disabled(!isStreamPlaying)
                    
                    Toggle("Stop music after session", isOn: $stopMusicAfterSession)
                        .padding(.top, 5)
                        .disabled(!isStreamPlaying)
                }
                
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
            
            if let gongPath = Bundle.main.path(forResource: "Chime", ofType: "mp3") {
                let gongUrl = URL(fileURLWithPath: gongPath)
                audioPlayer = try AVAudioPlayer(contentsOf: gongUrl)
                audioPlayer?.prepareToPlay()
            }
            
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
        UIApplication.shared.isIdleTimerDisabled = true
        playGong()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                currentGong += 1
                if currentGong < numberOfGongs {
                    playGong()
                    timeRemaining = intervalMinutes * 60
                } else {
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
        UIApplication.shared.isIdleTimerDisabled = false
        
        if isStreamPlaying && stopMusicAfterSession {
            fadeVolume(to: 0) {
                self.streamPlayer?.pause()
                self.isStreamPlaying = false
            }
        }
    }
    
    func playGong() {
        let streamWasPlaying = isStreamPlaying
        
        let playGongAction = {
            let playerToPlay = (self.currentGong == self.numberOfGongs - 1) ? self.finalAudioPlayer : self.audioPlayer
            playerToPlay?.stop()
            playerToPlay?.currentTime = 0
            playerToPlay?.play()
            
            if streamWasPlaying {
                // Chime is ~2s long. Fade in after it finishes.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.fadeVolume(to: Float(self.streamVolume))
                }
            }
        }
        
        if streamWasPlaying {
            fadeVolume(to: 0) {
                playGongAction()
            }
        } else {
            playGongAction()
        }
    }
    
    func toggleStream() {
        if isStreamPlaying {
            fadeVolume(to: 0) {
                self.streamPlayer?.pause()
                self.isStreamPlaying = false
            }
        } else {
            guard let url = URL(string: streamURL) else {
                alertMessage = "Invalid stream URL"
                showingAlert = true
                return
            }
            streamPlayer = AVPlayer(url: url)
            streamPlayer?.volume = 0 // Start at 0 for fade-in
            streamPlayer?.play()
            isStreamPlaying = true
            fadeVolume(to: Float(streamVolume))
        }
    }
    
    func fadeVolume(to targetVolume: Float, completion: (() -> Void)? = nil) {
        volumeFadeTimer?.invalidate()
        let initialVolume = streamPlayer?.volume ?? 0
        let volumeChange = targetVolume - initialVolume
        let fadeDuration = 1.0 // 1 second fade
        let steps = 20
        let stepInterval = fadeDuration / Double(steps)
        var currentStep = 0
        
        volumeFadeTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            currentStep += 1
            if currentStep >= steps {
                timer.invalidate()
                self.streamPlayer?.volume = targetVolume
                completion?()
            } else {
                let percentage = Float(currentStep) / Float(steps)
                self.streamPlayer?.volume = initialVolume + (volumeChange * percentage)
            }
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

