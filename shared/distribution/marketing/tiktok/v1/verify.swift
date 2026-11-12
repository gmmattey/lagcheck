import AVFoundation
import AppKit
let url=URL(fileURLWithPath:CommandLine.arguments[1]);let asset=AVURLAsset(url:url)
let v=asset.tracks(withMediaType:.video)[0], a=asset.tracks(withMediaType:.audio)[0]
print("duration=\(asset.duration.seconds) dimensions=\(v.naturalSize) fps=\(v.nominalFrameRate) audioTracks=\(asset.tracks(withMediaType:.audio).count)")
let reader=try AVAssetReader(asset:asset)
let vo=AVAssetReaderTrackOutput(track:v,outputSettings:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]);reader.add(vo);reader.startReading();var n=0
while vo.copyNextSampleBuffer() != nil {n += 1}
print("decodedFrames=\(n) status=\(reader.status.rawValue)")
let ar=try AVAssetReader(asset:asset)
let ao=AVAssetReaderTrackOutput(track:a,outputSettings:[AVFormatIDKey:kAudioFormatLinearPCM,AVLinearPCMIsFloatKey:true,AVLinearPCMBitDepthKey:32]);ar.add(ao);ar.startReading();var samples=0;var peak:Float=0
while let b=ao.copyNextSampleBuffer(){samples += CMSampleBufferGetNumSamples(b);if let block=CMSampleBufferGetDataBuffer(b){var len=0;var ptr:UnsafeMutablePointer<Int8>?;CMBlockBufferGetDataPointer(block,atOffset:0,lengthAtOffsetOut:nil,totalLengthOut:&len,dataPointerOut:&ptr);if let p=ptr{p.withMemoryRebound(to:Float.self,capacity:len/4){for i in 0..<len/4{peak=max(peak,abs($0[i]))}}}}}
print("audioSamples=\(samples) peak=\(peak) status=\(ar.status.rawValue)")
