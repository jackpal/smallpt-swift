#!/usr/bin/env xcrun swift -O

// Smallpt in swift
// Based on http://www.kevinbeason.com/smallpt/

import Foundation

class OutputStream : OutputStreamType {
  let handle : NSFileHandle
  init(handle : NSFileHandle) {
    self.handle = handle
  }
  func write(string: String) {
    if let asUTF8 = string.dataUsingEncoding(NSUTF8StringEncoding) {
      handle.writeData(asUTF8)
    }
  }
}

class StandardErrorOutputStream: OutputStream {
  init() {
    let stderr = NSFileHandle.fileHandleWithStandardError()
    super.init(handle:stderr)
  }
}

class FileStream : OutputStream {
  init(path : String) {
    let d = NSFileManager.defaultManager()
    d.createFileAtPath(path, contents: nil, attributes: nil)
    let h = NSFileHandle(forWritingAtPath: path)
    super.init(handle:h!)
  }
}

let stderr = StandardErrorOutputStream()

struct Vec {
  let x, y, z : Double
  init() { self.init(x:0, y:0, z:0) }
  init(x : Double, y : Double, z: Double){ self.x=x; self.y=y; self.z=z; }
  func length() -> Double { return sqrt(x*x+y*y+z*z) }
  func norm() -> Vec { return self * (1/self.length()) }
  func dot(b : Vec) -> Double { return x*b.x+y*b.y+z*b.z }
};

func +(a :Vec, b:Vec) -> Vec { return Vec(x:a.x+b.x, y:a.y+b.y, z:a.z+b.z) }
func -(a :Vec, b:Vec) -> Vec { return Vec(x:a.x-b.x, y:a.y-b.y, z:a.z-b.z) }
func *(a :Vec, b : Double) -> Vec { return Vec(x:a.x*b, y:a.y*b, z:a.z*b) }
func *(a :Vec, b : Vec) -> Vec { return Vec(x:a.x*b.x, y:a.y*b.y, z:a.z*b.z) }
// cross product:
func %(a :Vec, b : Vec) -> Vec{
  return Vec(x:a.y*b.z-a.z*b.y, y:a.z*b.x-a.x*b.z, z:a.x*b.y-a.y*b.x)
}

struct Ray { let o, d : Vec; init(o : Vec, d : Vec) {self.o = o; self.d = d}}

enum Refl_t { case DIFF; case SPEC; case REFR }  // material types, used in radiance()

struct Sphere {
  let rad : Double       // radius
  let p, e, c : Vec      // position, emission, color
  let refl : Refl_t      // reflection type (DIFFuse, SPECular, REFRactive)
  init(rad :Double, p: Vec, e: Vec, c: Vec, refl: Refl_t) {
    self.rad = rad; self.p = p; self.e = e; self.c = c; self.refl = refl; }
  func intersect(r: Ray) -> Double { // returns distance, 0 if nohit
    let op = p-r.o // Solve t^2*d.d + 2*t*(o-p).d + (o-p).(o-p)-R^2 = 0
    let eps = 1e-4
    let b = op.dot(r.d)
    let det = b*b-op.dot(op)+rad*rad
    if (det<0) {
      return 0
    }
    let det2=sqrt(det)
    let t=b-det2
    if t > eps {
      return t
    }
    let t2 = b+det2
    if t2 > eps {return t2}
    return 0
  }
}

let spheres :[Sphere] = [//Scene: radius, position, emission, color, material
  Sphere(rad:1e5, p:Vec(x: 1e5+1,y:40.8,z:81.6), e:Vec(), c:Vec(x:0.75,y:0.25,z:0.25), refl:Refl_t.DIFF),//Left
  Sphere(rad:1e5, p:Vec(x:-1e5+99,y:40.8,z:81.6),e:Vec(), c:Vec(x:0.25,y:0.25,z:0.75), refl:Refl_t.DIFF),//Rght
  Sphere(rad:1e5, p:Vec(x:50,y:40.8,z: 1e5),     e:Vec(), c:Vec(x:0.75,y:0.75,z:0.75), refl:Refl_t.DIFF),//Back
  Sphere(rad:1e5, p:Vec(x:50,y:40.8,z:-1e5+170), e:Vec(), c:Vec(),            refl:Refl_t.DIFF),//Frnt
  Sphere(rad:1e5, p:Vec(x:50,y: 1e5,z: 81.6),    e:Vec(), c:Vec(x:0.75,y:0.75,z:0.75), refl:Refl_t.DIFF),//Botm
  Sphere(rad:1e5, p:Vec(x:50,y:-1e5+81.6,z:81.6),e:Vec(), c:Vec(x:0.75,y:0.75,z:0.75), refl:Refl_t.DIFF),//Top
  Sphere(rad:16.5,p:Vec(x:27,y:16.5,z:47),       e:Vec(), c:Vec(x:1,y:1,z:1)*0.999,  refl:Refl_t.SPEC),//Mirr
  Sphere(rad:16.5,p:Vec(x:73,y:16.5,z:78),       e:Vec(), c:Vec(x:1,y:1,z:1)*0.999,  refl:Refl_t.REFR),//Glas
  Sphere(rad:600, p:Vec(x:50,y:681.6-0.27,z:81.6),e:Vec(x:12,y:12,z:12),   c:Vec(),  refl:Refl_t.DIFF) //Lite
]
func clamp(x : Double) -> Double { return x < 0 ? 0 : x > 1 ? 1 : x; }

func toInt(x : Double) -> Int { return Int(pow(clamp(x),1/2.2)*255+0.5); }

func intersect(r : Ray, inout t: Double, inout id: Int) -> Bool {
  let n = spheres.count
  let inf = 1e20
  t = inf
  for (var i = n-1; i >= 0; i--) {
    let d = spheres[i].intersect(r)
    if (d != 0.0 && d<t){
      t=d
      id=i
    }
  }
  return t<inf
}

struct drand {
  let pbuffer = UnsafeMutablePointer<UInt16>.alloc(3)
  init(a : UInt16) {
    pbuffer[2] = a
  }
  func next() -> Double { return erand48(pbuffer) }
}

func radiance(r: Ray, depthIn: Int, Xi : drand) -> Vec {
  var t : Double = 0                               // distance to intersection
  var id : Int = 0                             // id of intersected object
  if (!intersect(r, &t, &id)) {return Vec() } // if miss, return black
  let obj = spheres[id]        // the hit object
  let x=r.o+r.d*t
  let n=(x-obj.p).norm()
  let nl = (n.dot(r.d) < 0) ? n : n * -1
  var f=obj.c
  let p = f.x > f.y && f.x > f.z ? f.x : f.y > f.z ? f.y : f.z; // max refl
  let depth = depthIn+1
  // Russian Roulette:
  if (depth>5) {
    if (Xi.next()<p) {
      f=f*(1/p)
    } else {
      return obj.e
    }
  }
  switch (obj.refl) {
  case Refl_t.DIFF:                  // Ideal DIFFUSE reflection
    let r1=2*M_PI*Xi.next(), r2=Xi.next(), r2s=sqrt(r2);
    let w = nl
    let u = ((fabs(w.x)>0.1 ? Vec(x:0, y:1, z:0) : Vec(x:1, y:0, z:0)) % w).norm()
    let v = w % u
    let d = (u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1-r2)).norm()
    return obj.e + f * radiance(Ray(o: x, d:d), depth, Xi)
  case Refl_t.SPEC: // Ideal SPECULAR reflection
    return obj.e + f * (radiance(Ray(o:x, d:r.d-n*2*n.dot(r.d)), depth, Xi))
  case Refl_t.REFR:
    let reflRay = Ray(o:x, d:r.d-n*2*n.dot(r.d))    // Ideal dielectric REFRACTION
    let into = n.dot(nl)>0                // Ray from outside going in?
    let nc = 1, nt=1.5
    let nnt = into ? Double(nc) / nt : nt / Double(nc)
    let ddn = r.d.dot(nl)
    let cos2t=1-nnt*nnt*(1-ddn*ddn)
    if (cos2t<0) {    // Total internal reflection
      return obj.e + f * radiance(reflRay, depth, Xi)
    }
    let tdir = (r.d * nnt - n * ((into ? 1 : -1)*(ddn*nnt+sqrt(cos2t)))).norm()
    let a = nt-Double(nc), b = nt+Double(nc), R0 = a*a/(b*b), c = 1-(into ? -ddn : tdir.dot(n))
    let Re=R0+(1-R0)*c*c*c*c*c,Tr=1-Re,P=0.25+0.5*Re,RP=Re/P,TP=Tr/(1-P)
    return obj.e + f * (depth>2 ? (Xi.next()<P ?   // Russian roulette
      radiance(reflRay,depth,Xi) * RP : radiance(Ray(o: x, d: tdir),depth,Xi)*TP) :
      radiance(reflRay,depth,Xi) * Re + radiance(Ray(o: x, d: tdir),depth,Xi)*Tr);
  }
}

func main() {
  let mainQueue = dispatch_get_main_queue()
  let collectQueue = dispatch_queue_create("collectQueue", nil)
  dispatch_async(mainQueue) {
    let argc = C_ARGC, argv = C_ARGV
    let w=1024, h=768
    // let w = 160, h = 120
    let samps = argc==2 ? Int(atoi(argv[1])/4) : 1 // # samples
    let cam = Ray(o:Vec(x:50,y:52,z:295.6), d:Vec(x:0,y:-0.042612,z:-1).norm()) // cam pos, dir
    let cx = Vec(x:Double(w) * 0.5135 / Double(h), y:0, z:0)
    let cy = (cx % cam.d).norm()*0.5135
    var c = Array<Vec>(count:w*h, repeatedValue:Vec())
    let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    dispatch_apply(UInt(h), globalQueue) {
      let y = Int($0)
      let Xi = drand(a:UInt16(0xffff & (y * y * y)))
      let spp = samps*4
      let percent = 100.0 * Double(y)/Double(h-1)
      stderr.write(String(format:"\rRendering (%d spp) %.2f%%", spp, percent))
      for (var x = 0; x < w; x++) {   // Loop cols
        let i=(h-y-1)*w+x
        var r = Vec()
        for (var sy=0; sy<2; sy++) {     // 2x2 subpixel rows
          for (var sx=0; sx<2; sx++) {        // 2x2 subpixel cols
            for (var s=0; s < samps; s++) {
              let r1=2*Xi.next(), dx=r1<1 ? sqrt(r1)-1: 1-sqrt(2-r1)
              let r2=2*Xi.next(), dy=r2<1 ? sqrt(r2)-1: 1-sqrt(2-r2)
              let part1 = ( ( (Double(sx)+0.5 + Double(dx))/2 + Double(x))/Double(w) - 0.5)
              let part2 =  ( ( (Double(sy)+0.5 + Double(dy))/2 + Double(y))/Double(h) - 0.5)
              let d = cx * part1
                  + cy * part2
                  + cam.d
              let rr = radiance(Ray(o:cam.o+d*140, d:d.norm()), 0, Xi)
              r = r + rr * (1.0 / Double(samps))
            } // Camera rays are pushed ^^^^^ forward to start in interior
          }
        }
        let result = r*0.25
        dispatch_async(collectQueue) {
          c[i] = result
        }
      }
    }
    dispatch_async(collectQueue) {
      let f = FileStream(path: "image.ppm")         // Write image to PPM file.
      f.write("P3\n\(w) \(h)\n\(255)\n")
      for (var i=0; i<w*h; i++) {
        f.write("\(toInt(c[i].x)) \(toInt(c[i].y)) \(toInt(c[i].z)) ")
      }
      exit(0)
    }
  }
  dispatch_main();
}

main()
