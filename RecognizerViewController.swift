//
//  RecognizerViewController.swift
//  Matrike1
//
//  Created by Jakob Peterlin on 25/11/2017.
//  Copyright © 2017 Jakob Peterlin. All rights reserved.
//

import UIKit
import Vision
import CoreML

class RecognizerViewController: FirstViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

   override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo
      info: [String : Any]) {
      picker.dismiss(animated: true)
      //% classificationLabel.text = "Analyzing Image..."
      //% correctedImageView.image = nil
      
      guard let uiImage = info[UIImagePickerControllerOriginalImage] as? UIImage
         else { fatalError("no image form image picker") }
      guard let ciImage = CIImage(image: uiImage)
         else { fatalError("can't create CIImage from UIImage")}



      let orientation = CGImagePropertyOrientation(rawValue: UInt32(uiImage.imageOrientation.rawValue))
      inputImage = ciImage.oriented(forExifOrientation: Int32(orientation!.rawValue))
      //% inputImage = ciImage.applyingOrientation(Int32(orientation.rawValue))
      // Show the image in the UI.
      //% imageView.image = uiImage
      
      // Run the rectangle detector, which upon completion runs the ML classifier.
      let handler = VNImageRequestHandler(ciImage: ciImage, orientation: Int32(orientation!.rawValue))
      DispatchQueue.global(qos: .userInteractive).async {
           do {
            try handler.perform{[self.rectangleRequest]}
         } catch {
            print(error)
         }
      }
   }
   
   
   
    lazy var classificationRequest: VNCoreMLRequest = {
      // Load the ML model throught its generated class and create a Vision request for it.
      do {
         let model = try VNCoreMLModel(for: mnistCNN().model)
         return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
      } catch {
         fatalError("can't load Vision ML model: \(error)")
      }
   }()
   
   
   func handleClassification(request: VNRequest, error: Error?) {
      guard let observations = request.results as? [VNClassificationObservation]
         else { fatalError("unexpected result type from VNCoreMlRequest") }
      guard let best = observations.first
         else { fatalError("can't get best result") }
      
      //% DispatchQueue.main.async {
      //%    <#code#>self.classficationLabel.text = "Classification: \"\(best.identifier)\" Confidence:\(best.confidence)"
      //% }
   }
   
   //#-code-listing(RectangleDetectorSetup)
   lazy var rectangleRequest: VNDetectRectanglesRequest = {
      return VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
   }()
   
   func handleRectangles(request: VNRequest, error: Error?) {
      guard let observations = request.results as? [VNRectangleObservation]
         else { fatalError("unexpected resoult type from VNDetectRectanglesRequest") }
      guard let detectedRectangle = observations.first else {
         //% DispatchQueue.main.async {
         //%    self.clasificationLabel.text = "No rectangles detected."
         //% }
         return
      }
      var imageSize = inputImage.extent.size
      
      // Verify detected rectangle is valid.
      let boundingBox = detectedRectangle.boundingBox.scaled(to: imageSize)
      guard inputImage.extent.contains(boundingBox)
         else { print("invalid detected rectangle"); return }
      
      // Rectify the detected image and reduce it to inverted grayscale for applying model.
      let topLeft = detectedRectangle.topLeft.scaled(to: imageSize)
      let topRight = detectedRectangle.topRight.scaled(to: imageSize)
      let bottomLeft = detectedRectangle.bottomLeft.scaled(to: imageSize)
      let bottomRight = detectedRectangle.bottomRight.scaled(to: imageSize)
      let correctImage = inputImage
         .cropped(to: boundingBox)
         .applyingFilter("CIPerspectiveCorrection", parameters : [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight)
            ])
         .applyingFilter("CIColorControls",  parameters: [
            kCIInputSaturationKey: 0,
            kCIInputContrastKey: 32
            ])
         .applyingFilter("CIColorInvert", parameters: [:])
      
      // Run the CoreML MNIST clasifier -- resoults in handleClassification method
      let handler = VNImageRequestHandler(ciImage: correctImage)
      do {
         try handler.perform([classificationRequest])
      } catch {
         print(error)
      }
   }
}





extension CGRect {
   func scaled(to: CGSize) -> CGRect {
      let newX = minX * to.width
      let newY = minY * to.height
      let newWidth = width * to.width
      let newHeight = height * to.height
      return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
      
   }
   
   
}



extension CGPoint {
   func scaled(to: CGSize) -> CGPoint {
      let newX = x * to.width
      let newY = y * to.height
      return CGPoint(x: newX, y: newY)
   }
}
