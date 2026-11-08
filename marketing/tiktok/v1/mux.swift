import AVFoundation
let dir=CommandLine.arguments[1]
let duration=18.0
let silent=URL(fileURLWithPath:dir+"/video-sem-som.mp4")
let audioURL=URL(fileURLWithPath:dir+"/trilha-original.wav")
let composition=AVMutableComposition(), video=AVURLAsset(url:silent), audio=AVURLAsset(url:audioURL)
let range=CMTimeRange(start:.zero,duration:CMTime(seconds:duration,preferredTimescale:600))
try composition.addMutableTrack(withMediaType:.video,preferredTrackID:kCMPersistentTrackID_Invalid)!.insertTimeRange(range,of:video.tracks(withMediaType:.video)[0],at:.zero)
try composition.addMutableTrack(withMediaType:.audio,preferredTrackID:kCMPersistentTrackID_Invalid)!.insertTimeRange(range,of:audio.tracks(withMediaType:.audio)[0],at:.zero)
let export=AVAssetExportSession(asset:composition,presetName:AVAssetExportPresetHighestQuality)!
export.outputURL=URL(fileURLWithPath:dir+"/lagcheck-tiktok-18s.mp4");export.outputFileType = .mp4;export.shouldOptimizeForNetworkUse=true
let done=DispatchSemaphore(value:0);export.exportAsynchronously{done.signal()};done.wait();precondition(export.status == .completed,"Mux failed: \(String(describing:export.error))")
print("FINAL: "+export.outputURL!.path)
