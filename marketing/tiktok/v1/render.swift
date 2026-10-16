import AppKit
import CoreText
import AVFoundation
struct Item { let source:String; let filename:String; let title:[String]; let points:[CGPoint] }
func pts(_ values:[CGFloat]) -> [CGPoint] { stride(from:0,to:values.count,by:2).map{CGPoint(x:values[$0],y:values[$0+1])} }
let items = [
Item(source:"01",filename:"01-antes-da-partida",title:["ANTES DA PARTIDA,","CONFIRA SUA CONEXÃO."],points:pts([120,1417,128,1290,192,553,207,506,243,476,289,461,660,438,705,453,734,484,750,529,714,1070,674,1440,661,1481,631,1514,594,1530,171,1502,143,1481,126,1453])),
Item(source:"04",filename:"02-resultado",title:["SUA CONEXÃO.","UM RESULTADO CLARO."],points:pts([129,1406,143,1220,204,594,218,549,243,520,282,500,655,480,698,489,728,511,747,550,741,615,677,1413,667,1458,647,1495,615,1516,577,1520,189,1496,157,1481,136,1451])),
Item(source:"03",filename:"03-duas-fases",title:["TESTE EM REPOUSO","E COM A REDE EM USO."],points:pts([150,513,161,478,194,441,227,420,264,409,591,440,630,450,660,475,683,514,694,571,724,1375,720,1422,702,1461,668,1489,630,1499,239,1498,200,1484,173,1456,157,1410])),
Item(source:"02",filename:"04-escolha-jogo",title:["ESCOLHA O JOGO.","FAÇA O CHECK."],points:pts([109,1404,126,1215,201,481,216,439,246,406,290,388,664,354,698,360,728,382,748,420,752,466,675,1388,668,1435,649,1478,617,1506,578,1515,169,1480,138,1464,116,1434])),
Item(source:"05",filename:"05-detalhes",title:["ENTENDA", "O RESULTADO."],points:pts([130,1397,146,1201,207,555,224,506,257,478,296,463,655,440,694,450,724,476,745,515,743,571,677,1401,667,1448,646,1483,613,1509,575,1517,185,1490,154,1473,136,1440]))
]
let root=CommandLine.arguments[1], dir=CommandLine.arguments[1]+"/marketing/tiktok/v1"
let W=1080, H=1920, fps:Int32=30, duration=18.0
func load(_ p:String)->CGImage { CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath:p) as CFURL,nil)!,0,nil)! }
let bg=load(root+"/store/app-store/pt-BR/screenshots-v2/originals/background.png")
let logo=load(root+"/design-system/assets/brand/wordmark-purple-master.png")
let screens=items.map{load(root+"/store/app-store/pt-BR/screenshots/originals/"+$0.source+".png")}
let white=CGColor(red:0.957,green:0.961,blue:0.969,alpha:1)
let purple=CGColor(red:0.655,green:0.545,blue:0.98,alpha:1)
func image(_ c:CGContext,_ i:CGImage,_ r:CGRect){ c.saveGState(); c.translateBy(x:r.minX,y:r.maxY); c.scaleBy(x:1,y:-1); c.draw(i,in:CGRect(x:0,y:0,width:r.width,height:r.height)); c.restoreGState() }
func text(_ c:CGContext,_ s:String,_ size:CGFloat,_ y:CGFloat,_ color:CGColor){
 let f=CTFontCreateWithName("HelveticaNeue-CondensedBlack" as CFString,size,nil)
 let a=NSAttributedString(string:s,attributes:[NSAttributedString.Key(kCTFontAttributeName as String):f,NSAttributedString.Key(kCTForegroundColorAttributeName as String):color])
 let l=CTLineCreateWithAttributedString(a); let width=CGFloat(CTLineGetTypographicBounds(l,nil,nil,nil))
 c.saveGState(); c.translateBy(x:(1000-width)/2,y:y); c.scaleBy(x:1,y:-1); c.textPosition = .zero; CTLineDraw(l,c); c.restoreGState()
}
func phone(_ c:CGContext,_ index:Int,_ y:CGFloat,_ height:CGFloat){
 let q=items[index].points; let minX=q.map{$0.x}.min()!, maxX=q.map{$0.x}.max()!, minY=q.map{$0.y}.min()!, maxY=q.map{$0.y}.max()!
 let scale=height/(maxY-minY)
 c.saveGState(); c.translateBy(x:(1000-(maxX-minX)*scale)/2-minX*scale,y:y-minY*scale); c.scaleBy(x:scale,y:scale)
 let p=CGMutablePath(); p.move(to:CGPoint(x:(q.last!.x+q[0].x)/2,y:(q.last!.y+q[0].y)/2))
 for i in q.indices {let n=q[(i+1)%q.count];p.addQuadCurve(to:CGPoint(x:(q[i].x+n.x)/2,y:(q[i].y+n.y)/2),control:q[i])}
 p.closeSubpath(); c.addPath(p);c.clip();image(c,screens[index],CGRect(x:0,y:0,width:853,height:1844));c.restoreGState()
}
func render(_ c:CGContext,_ t:Double){
 c.translateBy(x:0,y:CGFloat(H));c.scaleBy(x:1,y:-1);c.interpolationQuality = .high
 let drift=CGFloat(sin(t/5)*12)
 image(c,bg,CGRect(x:-20+drift,y:-25,width:1120,height:1970))
 image(c,logo,CGRect(x:280,y:190,width:440,height:440*CGFloat(logo.height)/CGFloat(logo.width)))
 let start:Double = t<3 ? 0 : t<7 ? 3 : t<11 ? 7 : t<14 ? 11 : 14
 let local=t-start, a=min(1,local/0.22)
 c.saveGState();c.setAlpha(a);c.translateBy(x:0,y:CGFloat((1-a)*28))
 if t<3 {
  text(c,"VAI DE",125,690,white);text(c,"RANKED?",160,865,purple)
  text(c,"Confira a conexão",67,1050,white);text(c,"antes da partida.",67,1130,white)
 } else if t<7 {
  text(c,"FAÇA UM CHECK",84,395,white);text(c,"ANTES DE JOGAR.",84,487,purple)
  phone(c,2,565-CGFloat(local)*3,970+CGFloat(local)*6)
 } else if t<11 {
  text(c,"VEJA COMO ESTÁ",82,395,white);text(c,"SUA CONEXÃO.",86,487,purple)
  phone(c,1,565-CGFloat(local)*3,970+CGFloat(local)*6)
  text(c,"Exemplo de resultado",33,1600,white)
 } else if t<14 {
  text(c,"ENTENDA",86,395,white);text(c,"O RESULTADO.",86,487,purple)
  phone(c,4,565-CGFloat(local)*3,970+CGFloat(local)*6)
  text(c,"Exemplo de resultado",33,1600,white)
 } else {
  text(c,"ANTES DA PARTIDA,",83,680,white);text(c,"FAÇA UM",100,810,white)
  image(c,logo,CGRect(x:170,y:885,width:660,height:660*CGFloat(logo.height)/CGFloat(logo.width)))
  text(c,"Conheça na App Store",59,1220,purple)
 }
 c.restoreGState()
 c.setFillColor(CGColor(red:0.486,green:0.227,blue:0.929,alpha:1))
 c.fill(CGRect(x:100,y:1680,width:800*t/duration,height:5))
}
let silent=URL(fileURLWithPath:dir+"/video-sem-som.mp4")
let writer=try AVAssetWriter(outputURL:silent,fileType:.mp4)
let input=AVAssetWriterInput(mediaType:.video,outputSettings:[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:W,AVVideoHeightKey:H,AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:8000000,AVVideoExpectedSourceFrameRateKey:30]])
let adapter=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:W,kCVPixelBufferHeightKey as String:H,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
writer.add(input);writer.startWriting();writer.startSession(atSourceTime:.zero)
for frame in 0..<Int(duration*Double(fps)) {
 autoreleasepool {
 while !input.isReadyForMoreMediaData {Thread.sleep(forTimeInterval:0.005)}
 var pb:CVPixelBuffer?;CVPixelBufferPoolCreatePixelBuffer(nil,adapter.pixelBufferPool!,&pb)
 CVPixelBufferLockBaseAddress(pb!,[])
 let c=CGContext(data:CVPixelBufferGetBaseAddress(pb!),width:W,height:H,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(pb!),space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
 render(c,Double(frame)/Double(fps))
 if [45,150,270,375,495].contains(frame) {
  let url=URL(fileURLWithPath:dir+"/frame-\(frame).png")
  let d=CGImageDestinationCreateWithURL(url as CFURL,"public.png" as CFString,1,nil)!
  CGImageDestinationAddImage(d,c.makeImage()!,nil);CGImageDestinationFinalize(d)
 }
 CVPixelBufferUnlockBaseAddress(pb!,[])
 precondition(adapter.append(pb!,withPresentationTime:CMTime(value:Int64(frame),timescale:fps)),"Frame failed")
 }
}
input.markAsFinished();let sem=DispatchSemaphore(value:0);writer.finishWriting{sem.signal()};sem.wait();precondition(writer.status == .completed,"Video encoding failed")
print("Video render complete")
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
let composition=AVMutableComposition(), video=AVURLAsset(url:silent), audio=AVURLAsset(url:audioURL)
let range=CMTimeRange(start:.zero,duration:CMTime(seconds:duration,preferredTimescale:600))
try composition.addMutableTrack(withMediaType:.video,preferredTrackID:kCMPersistentTrackID_Invalid)!.insertTimeRange(range,of:video.tracks(withMediaType:.video)[0],at:.zero)
try composition.addMutableTrack(withMediaType:.audio,preferredTrackID:kCMPersistentTrackID_Invalid)!.insertTimeRange(range,of:audio.tracks(withMediaType:.audio)[0],at:.zero)
let export=AVAssetExportSession(asset:composition,presetName:AVAssetExportPresetHighestQuality)!
export.outputURL=URL(fileURLWithPath:dir+"/lagcheck-tiktok-18s.mp4");export.outputFileType = .mp4;export.shouldOptimizeForNetworkUse=true
let done=DispatchSemaphore(value:0);export.exportAsynchronously{done.signal()};done.wait();precondition(export.status == .completed,"Mux failed: \(String(describing:export.error))")
print("FINAL: "+export.outputURL!.path)
