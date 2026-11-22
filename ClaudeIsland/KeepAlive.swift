import AVFoundation
import Foundation

/// Keeps the app running in the background by looping inaudible audio.
/// The session uses .mixWithOthers so YouTube, music, etc. keep playing normally.
final class KeepAlive {
    private var player: AVAudioPlayer?
    private var observer: NSObjectProtocol?

    func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        if player == nil {
            player = try? AVAudioPlayer(data: Self.silentWAV())
            player?.numberOfLoops = -1
            player?.prepareToPlay()
        }
        player?.play()

        if observer == nil {
            observer = NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard
                    let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                    AVAudioSession.InterruptionType(rawValue: raw) == .ended
                else { return }
                try? AVAudioSession.sharedInstance().setActive(true)
                self?.player?.play()
            }
        }
    }

    func stop() {
        player?.stop()
        player = nil
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// One second of 8 kHz 16-bit mono silence as an in-memory WAV file.
    private static func silentWAV(seconds: Int = 1, sampleRate: Int = 8000) -> Data {
        let dataSize = sampleRate * seconds * 2
        var d = Data()

        func u32(_ v: UInt32) {
            var x = v.littleEndian
            d.append(Data(bytes: &x, count: 4))
        }
        func u16(_ v: UInt16) {
            var x = v.littleEndian
            d.append(Data(bytes: &x, count: 2))
        }

        d.append("RIFF".data(using: .ascii)!)
        u32(UInt32(36 + dataSize))
        d.append("WAVE".data(using: .ascii)!)
        d.append("fmt ".data(using: .ascii)!)
        u32(16)                          // fmt chunk size
        u16(1)                           // PCM
        u16(1)                           // mono
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * 2))      // byte rate
        u16(2)                           // block align
        u16(16)                          // bits per sample
        d.append("data".data(using: .ascii)!)
        u32(UInt32(dataSize))
        d.append(Data(count: dataSize))  // zeros = silence
        return d
    }
}
