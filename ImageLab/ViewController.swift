import UIKit
import AVFoundation
import MetalKit

class ViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VisionAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    var readingFinger:Bool = false
    
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    @IBOutlet weak var stageLabel: UILabel!
    @IBOutlet weak var cameraView: MTKView!
    @IBOutlet weak var headAngleLabel: UILabel!
    
    @IBOutlet weak var smilingLabel: UILabel!
    @IBOutlet weak var blinkingLabel: UILabel!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        // setup the OpenCV bridge nose detector, from file
        self.bridge.loadHaarCascade(withFilename: "nose")
        
        self.videoManager = VisionAnalgesic(view: self.cameraView)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these properties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh,
                      CIDetectorNumberOfAngles:11,
                      CIDetectorTracking:false] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    
    }
    
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var camButton: UIButton!
    
    //MARK: Process image output
    func processImageSwift(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let f = getFaces(img: inputImage)
        
        var retImage = inputImage
        if (!self.readingFinger) {
            self.videoManager.turnOffFlash()
        }
        
        if f.count == 0 {
            self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())

            self.readingFinger = self.bridge.processFinger()
            if (self.readingFinger) {
                let overheat = self.videoManager.turnOnFlashwithLevel(1.0)
                if (overheat) {
                    self.videoManager.turnOffFlash()
                }
            } else {
                self.videoManager.turnOffFlash()
            }
        } else {
            for face in f {
                self.bridge.setImage(retImage,
                                     withBounds: face.bounds, // the first face bounds
                                     andContext: self.videoManager.getCIContext())
                
                self.bridge.processImage()
                retImage = self.bridge.getImageComposite()
                
                retImage = self.mouth(face: face, retImage: retImage)
                retImage = self.leftEye(face: face, retImage: retImage)
                retImage = self.rightEye(face: face, retImage: retImage)
            
                
                let isLeftEyeBlinking = face.hasLeftEyePosition && face.leftEyeClosed
                let isRightEyeBlinking = face.hasRightEyePosition && face.rightEyeClosed
                
                let isSmiling = face.hasSmile
                let headAngleText = "Head Angle: \(face.faceAngle)"
                
                print("left eye closed: \(face.leftEyeClosed), right eye closed: \(face.rightEyeClosed), smiling: \(isSmiling)")
                
                self.headAngleLabel.text = headAngleText
                self.blinkingLabel.text = isLeftEyeBlinking || isRightEyeBlinking ? "Blinking" : "Not Blinking"
                self.smilingLabel.text = isSmiling ? "Smiling" : "Not Smiling"
            }
        }
        
        return retImage
    }
    
    func leftEye(face:CIFaceFeature, retImage:CIImage) -> CIImage {
        if (face.hasLeftEyePosition) {
            let leftEyeBounds = CGRect(x: face.leftEyePosition.x - face.bounds.size.width / 4,
                                       y: face.leftEyePosition.y - face.bounds.size.height / 8,
                                       width: face.bounds.size.width / 2,
                                       height: face.bounds.size.height / 4)
            self.bridge.setImage(retImage,
                                 withBounds: leftEyeBounds, // the first face bounds
                                 andContext: self.videoManager.getCIContext())
            
            self.bridge.processFacialFeatures()
            return self.bridge.getImageComposite()
        }
        
        return retImage
    }
    
    func rightEye(face:CIFaceFeature, retImage:CIImage) -> CIImage {
        if (face.hasRightEyePosition) {
            let rightEyeBounds = CGRect(x: face.rightEyePosition.x - face.bounds.size.width / 4,
                                           y: face.rightEyePosition.y - face.bounds.size.height / 8,
                                           width: face.bounds.size.width / 2,
                                           height: face.bounds.size.height / 4)
            self.bridge.setImage(retImage,
                                 withBounds: rightEyeBounds, // the first face bounds
                                 andContext: self.videoManager.getCIContext())
            
            self.bridge.processFacialFeatures()
            return self.bridge.getImageComposite()
        }
        
        return retImage
    }
    
    func mouth(face:CIFaceFeature, retImage:CIImage) -> CIImage {
        if (face.hasMouthPosition) {
            let mouthBounds = CGRect(x: face.mouthPosition.x - face.bounds.size.width / 4,
                                        y: face.mouthPosition.y - face.bounds.size.height / 8,
                                        width: face.bounds.size.width / 2,
                                        height: face.bounds.size.height / 4)
            self.bridge.setImage(retImage,
                                 withBounds: mouthBounds, // the first face bounds
                                 andContext: self.videoManager.getCIContext())
            
            self.bridge.processFacialFeatures()
            return self.bridge.getImageComposite()
        
        }
        
        return retImage
    }
    
    //MARK: Setup Face Detection
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace: [String: Any] = [CIDetectorImageOrientation:self.videoManager.ciOrientation, CIDetectorEyeBlink:true, CIDetectorSmile:true]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    
    // change the type of processing done in OpenCV
    @IBAction func swipeRecognized(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .left:
            if self.bridge.processType <= 10 {
                self.bridge.processType += 1
            }
        case .right:
            if self.bridge.processType >= 1{
                self.bridge.processType -= 1
            }
        default:
            break
            
        }
        
        stageLabel.text = "Stage: \(self.bridge.processType)"

    }
    
    //MARK: Convenience Methods for UI Flash and Camera Toggle
    @IBAction func flash(_ sender: AnyObject) {
        if(self.videoManager.toggleFlash()){
            self.flashSlider.value = 1.0
        }
        else{
            self.flashSlider.value = 0.0
        }
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    
    @IBAction func setFlashLevel(_ sender: UISlider) {
        if(sender.value>0.0){
            let val = self.videoManager.turnOnFlashwithLevel(sender.value)
            if val {
                print("Flash return, no errors.")
            }
        }
        else if(sender.value==0.0){
            self.videoManager.turnOffFlash()
        }
    }

   
}

