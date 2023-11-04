import UIKit
import AVFoundation
import MetalKit

class ViewControllerB: UIViewController   {

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

    @IBOutlet weak var readingLabel: UILabel!
    
    @IBOutlet weak var ppgGraphView: PPGGraphView!
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        // setup the OpenCV bridge nose detector, from file
        self.bridge.loadHaarCascade(withFilename: "nose")
        
        self.videoManager = VisionAnalgesic(view: self.cameraView)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
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
    
        
        var retImage = inputImage
        if (!self.readingFinger) {
            self.videoManager.turnOffFlash()
        }
    
        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())

        self.readingFinger = self.bridge.processFinger()
        //print(self.readingFinger)
        if (self.readingFinger) {
            if (self.ppgGraphView.data.count == 500) {
                self.ppgGraphView.data.removeAll(keepingCapacity: false)
            }
            
            let bpm = self.bridge.getFingerReading(30)
            if (bpm < 0) {
                self.readingLabel.text = "Reading..."
                //print(self.bridge.getLatestData(), CGFloat(self.bridge.getLatestData()))
                self.ppgGraphView.data.append(CGFloat(self.bridge.getLatestData()))
            } else {
                self.readingLabel.text = "BPM: \(bpm)"
                
            }
            
            
            let overheating = self.videoManager.turnOnFlashwithLevel(1.0)
            if (overheating) {
                self.videoManager.turnOffFlash()
                print("Overheating: turning off flash.")
            }
        } else {
            //self.readingLabel.text = "Place your finger on the Camera"
            self.videoManager.turnOffFlash()
            
        }
    
        return retImage
    }
    
   
    //MARK: Setup Face Detection
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
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

