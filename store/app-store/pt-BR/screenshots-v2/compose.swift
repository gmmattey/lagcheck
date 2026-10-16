import AppKit
import CoreText

let root = CommandLine.arguments[1]
let out = root + "/store/app-store/pt-BR/screenshots-v2"
func load(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
let bg = load(out + "/originals/background.png")
let logo = load(root + "/design-system/assets/brand/wordmark-purple-master.png")
func image(_ c: CGContext, _ i: CGImage, _ r: CGRect) {
    c.saveGState(); c.translateBy(x:r.minX,y:r.maxY); c.scaleBy(x:1,y:-1)
    c.draw(i,in:CGRect(x:0,y:0,width:r.width,height:r.height)); c.restoreGState()
}
func text(_ c: CGContext,_ s: String,_ size: CGFloat,_ y: CGFloat,_ color: CGColor) {
    let font = CTFontCreateWithName("HelveticaNeue-CondensedBlack" as CFString,size,nil)
    let a = NSAttributedString(string:s,attributes:[NSAttributedString.Key(kCTFontAttributeName as String):font,NSAttributedString.Key(kCTForegroundColorAttributeName as String):color])
    let line = CTLineCreateWithAttributedString(a)
    let w = CGFloat(CTLineGetTypographicBounds(line,nil,nil,nil))
    c.saveGState(); c.translateBy(x:(1206-w)/2,y:y); c.scaleBy(x:1,y:-1)
    c.textPosition = .zero; CTLineDraw(line,c); c.restoreGState()
}
struct Item { let source:String; let filename:String; let title:[String]; let points:[CGPoint] }
func pts(_ values:[CGFloat]) -> [CGPoint] { stride(from:0,to:values.count,by:2).map{CGPoint(x:values[$0],y:values[$0+1])} }
let items = [
Item(source:"01",filename:"01-antes-da-partida",title:["ANTES DA PARTIDA,","CONFIRA SUA CONEXÃO."],points:pts([120,1417,128,1290,192,553,207,506,243,476,289,461,660,438,705,453,734,484,750,529,714,1070,674,1440,661,1481,631,1514,594,1530,171,1502,143,1481,126,1453])),
Item(source:"04",filename:"02-resultado",title:["SUA CONEXÃO.","UM RESULTADO CLARO."],points:pts([129,1406,143,1220,204,594,218,549,243,520,282,500,655,480,698,489,728,511,747,550,741,615,677,1413,667,1458,647,1495,615,1516,577,1520,189,1496,157,1481,136,1451])),
Item(source:"03",filename:"03-duas-fases",title:["TESTE EM REPOUSO","E COM A REDE EM USO."],points:pts([150,513,161,478,194,441,227,420,264,409,591,440,630,450,660,475,683,514,694,571,724,1375,720,1422,702,1461,668,1489,630,1499,239,1498,200,1484,173,1456,157,1410])),
Item(source:"02",filename:"04-escolha-jogo",title:["ESCOLHA O JOGO.","FAÇA O CHECK."],points:pts([109,1404,126,1215,201,481,216,439,246,406,290,388,664,354,698,360,728,382,748,420,752,466,675,1388,668,1435,649,1478,617,1506,578,1515,169,1480,138,1464,116,1434])),
Item(source:"05",filename:"05-detalhes",title:["ENTENDA", "O RESULTADO."],points:pts([130,1397,146,1201,207,555,224,506,257,478,296,463,655,440,694,450,724,476,745,515,743,571,677,1401,667,1448,646,1483,613,1509,575,1517,185,1490,154,1473,136,1440]))
]
let white = CGColor(red:244/255,green:245/255,blue:247/255,alpha:1)
let purple = CGColor(red:167/255,green:139/255,blue:250/255,alpha:1)
for item in items {
    let c = CGContext(data:nil,width:1206,height:2622,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.translateBy(x:0,y:2622); c.scaleBy(x:1,y:-1); c.interpolationQuality = .high
    image(c,bg,CGRect(x:0,y:0,width:1206,height:2622))
    image(c,logo,CGRect(x:343,y:125,width:520,height:520*CGFloat(logo.height)/CGFloat(logo.width)))
    text(c,item.title[0],86,390,white); text(c,item.title[1],86,492,purple)
    let minX = item.points.map{$0.x}.min()!, maxX = item.points.map{$0.x}.max()!
    let minY = item.points.map{$0.y}.min()!, maxY = item.points.map{$0.y}.max()!
    let f = min(980/(maxX-minX),1740/(maxY-minY))
    let dx = (1206-(maxX-minX)*f)/2, dy:CGFloat = 650
    c.saveGState(); c.translateBy(x:dx-minX*f,y:dy-minY*f); c.scaleBy(x:f,y:f)
    let p = CGMutablePath()
    let q = item.points
    p.move(to:CGPoint(x:(q.last!.x+q[0].x)/2,y:(q.last!.y+q[0].y)/2))
    for i in q.indices {
        let next=q[(i+1)%q.count]
        p.addQuadCurve(to:CGPoint(x:(q[i].x+next.x)/2,y:(q[i].y+next.y)/2),control:q[i])
    }
    p.closeSubpath(); c.addPath(p); c.clip()
    let screen = load(root+"/store/app-store/pt-BR/screenshots/originals/"+item.source+".png")
    image(c,screen,CGRect(x:0,y:0,width:853,height:1844)); c.restoreGState()
    let result = c.makeImage()!
    let url=URL(fileURLWithPath:out+"/"+item.filename+".png")
    let dest=CGImageDestinationCreateWithURL(url as CFURL,"public.png" as CFString,1,nil)!
    CGImageDestinationAddImage(dest,result,nil); precondition(CGImageDestinationFinalize(dest))
    print(url.path)
}
let preview = CGContext(data:nil,width:1500,height:652,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
preview.translateBy(x:0,y:652); preview.scaleBy(x:1,y:-1)
for (n,item) in items.enumerated() {
    image(preview,load(out+"/"+item.filename+".png"),CGRect(x:n*300,y:0,width:300,height:652))
}
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath:out+"/preview.png") as CFURL,"public.png" as CFString,1,nil)!
CGImageDestinationAddImage(dest,preview.makeImage()!,nil); precondition(CGImageDestinationFinalize(dest))
