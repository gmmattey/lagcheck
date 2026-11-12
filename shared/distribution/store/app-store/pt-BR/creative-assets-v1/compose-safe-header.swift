import AppKit
let root=CommandLine.arguments[1]
let dir=root+"/store/app-store/pt-BR/creative-assets-v1"
func load(_ p:String)->CGImage { CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath:p) as CFURL,nil)!,0,nil)! }
let bg=load(dir+"/originals/cabecalho-sem-texto-fundo.png")
let brand=load(root+"/design-system/assets/brand/wordmark-purple-master.png")
// Isolate the existing official symbol. Do not redraw or recolor it.
let symbol=brand.cropping(to:CGRect(x:0,y:0,width:250,height:250))!
let c=CGContext(data:nil,width:3840,height:1646,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
c.interpolationQuality = .high
c.draw(bg,in:CGRect(x:0,y:0,width:3840,height:1646))
let sw:CGFloat=720, sh:CGFloat=720
c.draw(symbol,in:CGRect(x:(3840-sw)/2,y:(1646-sh)/2,width:sw,height:sh))
let img=c.makeImage()!
func save(_ img:CGImage,_ name:String) {
 let d=CGImageDestinationCreateWithURL(URL(fileURLWithPath:dir+"/"+name) as CFURL,"public.png" as CFString,1,nil)!
 CGImageDestinationAddImage(d,img,nil); precondition(CGImageDestinationFinalize(d))
}
save(img,"cabecalho-sem-texto-3840x1646.png")
// Illustrative centered crop approximating the visible proportions in the user's preview.
save(img.cropping(to:CGRect(x:668,y:0,width:2504,height:1646))!,"preview-recorte-cabecalho.png")
