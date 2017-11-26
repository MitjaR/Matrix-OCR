//
//  FirstViewController.swift
//  Matrike1
//
//  Created by Jakob Peterlin on 25/11/2017.
//  Copyright © 2017 Jakob Peterlin. All rights reserved.
//

import UIKit
import Vision
import CoreML


class FirstViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
   
   @IBOutlet weak var textView: UITextView!
   @IBOutlet weak var imageView: UIImageView!
   
   
   
   
   var imageA = UIImage()
   var matrixA = ""
   var inputImage = CIImage()
   var textToShow = "Matrika!!!"
   //var paperBox = nil
   
   
   
   
   
   
  
   
   
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
      
      //textToShow = "Predicted number is : \(best.identifier), \(best.confidence)"
      print(textToShow)
      
      //% DispatchQueue.main.async {
      //%    self.classficationLabel.text = "Classification: \"\(best.identifier)\" Confidence:\(best.confidence)"
      //% }
   }
   
   
   
   lazy var textRectangleRequest: VNDetectTextRectanglesRequest = {
      let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.handleChars)
      textRequest.reportCharacterBoxes = true
      return textRequest
   }()

   
   func handleTextIdentifiaction (request: VNRequest, error: Error?) {
      
      guard let observations = request.results as? [VNTextObservation]
         else { print("unexpected result type from VNTextObservation")
            return
      }
      guard observations.first != nil else {
         return
      }
      
         for box in observations {
            guard let chars = box.characterBoxes else {
               print("no char values found")
               return
            }
            
         
            
            return
      }
            
     
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

      
      imageView.image = convert(cmage: correctImage)
      
      //self.paperBox = correctImage
      inputImage = correctImage
      
      // Run the CoreML MNIST clasifier -- resoults in handleClassification method
      let handler = VNImageRequestHandler(ciImage: correctImage)
      do {
         try handler.perform([textRectangleRequest])
      } catch {
         print(error)
      }
   }

   
   func handleChars(request: VNRequest, error: Error?) {
      textToShow = "HandleChars start"
      
      guard let observations = request.results as? [VNTextObservation]
         else { print("unexpected result type from VNTextObservation")
            return
      }
      guard observations.first != nil else {
         return
      }
      
      for box in observations {
         guard let chars = box.characterBoxes else {
            print("no char values found")
            return
         }
         
         for detectedChar in chars {
         textToShow.append("detect char")
         //var imageSize = paperBox.extent.size
         let imageSize = inputImage.extent.size
         
         // Verify detected rectangle is valid.
         let boundingBox = detectedChar.boundingBox.scaled(to: imageSize)
         guard inputImage.extent.contains(boundingBox)
            else { print("invalid detected rectangle"); return }
         
         // Rectify the detected image and reduce it to inverted grayscale for applying model.
         /*
         let topLeft = detectedChar.boundingBox.topLeft.scaled(to: imageSize)
         let topRight = detectedChar.boundingBox.topRight.scaled(to: imageSize)
         let bottomLeft = detectedChar.boundingBox.bottomLeft.scaled(to: imageSize)
         let bottomRight = detectedChar.boundingBox.bottomRight.scaled(to: imageSize)
         */
         let correctImage = inputImage.cropped(to: boundingBox)
         
         imageView.image = convert(cmage: correctImage)
         
         // Run the CoreML MNIST clasifier -- resoults in handleClassification method
         let handler = VNImageRequestHandler(ciImage: correctImage)
         do {
            try handler.perform([classificationRequest])
         } catch {
            print(error)
         }
      }
      
   }

   }













   
   @IBAction func chooseA(_ sender: Any) {
      let picker = UIImagePickerController()
      picker.delegate = self
      picker.sourceType = .savedPhotosAlbum
      present(picker, animated: true)
   }
   
   func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
      picker.dismiss(animated: true)
      
      guard let uiImage = info[UIImagePickerControllerOriginalImage] as? UIImage
         else { fatalError("no image from image picker") }
      
      
      
      
      guard let ciImage = CIImage(image: uiImage)
         else { fatalError("can't create CIImage from UIImage")}
      
      
      
      let orientation = CGImagePropertyOrientation(rawValue: UInt32(uiImage.imageOrientation.rawValue))
      inputImage = ciImage.oriented(forExifOrientation: Int32(orientation!.rawValue))
      //% inputImage = ciImage.applyingOrientation(Int32(orientation.rawValue))
      
            //textToShow = ""
      
      // Run the rectangle detector, which upon completion runs the ML classifier.
      let handler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation(rawValue: UInt32(Int32(orientation!.rawValue)))!)
      DispatchQueue.global(qos: .userInteractive).async {
         
         DispatchQueue.global(qos: .userInteractive).async {
               do {
                  try handler.perform([self.rectangleRequest])
         } catch {
            print(error)
         }
            
      }
      }
      textView.text = textToShow
      
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



func convert(cmage:CIImage) -> UIImage
{
   let context:CIContext = CIContext.init(options: nil)
   let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
   let image:UIImage = UIImage.init(cgImage: cgImage)
   return image
}


/*
 func handleClassification(request: VNRequest, error: Error?) {
 guard let observations = request.results as? [VNClassificationObservation]
 else { fatalError("unexpected result type from VNCoreMlRequest") }
 //guard let best = observations.first
 //   else { fatalError("can't get best result") }
 for number in observations {
 textToShow.append("Predicted number is : \(number.identifier), \(number.confidence)")
 print(textToShow)
 }
 
 //textToShow = "Predicted number is : \(best.identifier), \(best.confidence)"
 //print(textToShow)
 
 //% DispatchQueue.main.async {
 //%    self.classficationLabel.text = "Classification: \"\(best.identifier)\" Confidence:\(best.confidence)"
 //% }
 }
 */
