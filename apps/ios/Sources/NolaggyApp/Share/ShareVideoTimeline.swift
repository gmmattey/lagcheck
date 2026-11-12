import Foundation

/// Linha do tempo do vídeo (s): escolha 0–3,5, medição 3,5–9,5, resultado 9,5–14.
/// Paridade estrita 1:1 com ShareVideoTimeline do Android (Decisões 81 e 103).
public enum ShareVideoTimeline {
    public static let WIDTH = 1080
    public static let HEIGHT = 1920
    public static let FPS: Int32 = 30
    public static let DURATION: Double = 14.0
    public static let MEASURE_START: Double = 3.5
    public static let RESULT_START: Double = 9.5
    public static var frameCount: Int { Int(DURATION * Double(FPS)) }
}
