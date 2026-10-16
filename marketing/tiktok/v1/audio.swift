import AVFoundation
let dir=CommandLine.arguments[1]
let duration=18.0
// Original procedural instrumental: 120 BPM kick, hi-hat, bass and restrained chords.
let rate=48000.0, count=Int(duration*48000)
let format=AVAudioFormat(standardFormatWithSampleRate:rate,channels:2)!
let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:AVAudioFrameCount(count))!;buffer.frameLength=AVAudioFrameCount(count)
var seed:UInt32=1987
for i in 0..<count {
 let t=Double(i)/rate, beat=t.truncatingRemainder(dividingBy:0.5), eighth=t.truncatingRemainder(dividingBy:0.25)
 let kick=0.34*exp(-beat*25)*sin(2*Double.pi*(49*beat+2.4*(1-exp(-beat*35))))
 seed=1664525 &* seed &+ 1013904223
 let noise=(Double(seed)/Double(UInt32.max)*2-1)
 let hat=0.042*noise*exp(-eighth*95)
 let bass=0.11*sin(2*Double.pi*55*t)*min(1,beat*35)*exp(-beat*4)
 let pad=0.022*(sin(2*Double.pi*220*t)+sin(2*Double.pi*261.63*t)+sin(2*Double.pi*329.63*t))
 let fade=min(1,t/0.12)*min(1,(duration-t)/0.8)
 let value=Float((kick+hat+bass+pad)*fade)
 buffer.floatChannelData![0][i]=value;buffer.floatChannelData![1][i]=value
}
let audioURL=URL(fileURLWithPath:dir+"/trilha-original.wav")
do { let audioFile=try AVAudioFile(forWriting:audioURL,settings:format.settings);try audioFile.write(from:buffer) }
