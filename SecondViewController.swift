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


class SecondViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
   
   @IBOutlet weak var textView: UITextView!
   
   @IBOutlet weak var imageView: UIImageView!
   
   
   
   var imageA = UIImage()
   var matrixA = ""
   var inputImage = CIImage()
   var textToShow = "Matrika!!!"
   
   
   
   
   
   
   
   
   
   
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
      
      textToShow.append("Predicted number is : \(best.identifier), \(best.confidence)")
      print(textToShow)
      
      //% DispatchQueue.main.async {
      //%    self.classficationLabel.text = "Classification: \"\(best.identifier)\" Confidence:\(best.confidence)"
      //% }
   }
   
   
   
   lazy var textRectangleRequest: VNDetectTextRectanglesRequest = {
      let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.handleTextIdentifiaction)
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
      
      textToShow = "a"
      for box in observations {
         textToShow = "b"
         guard let chars = box.characterBoxes else {
            print("no char values found")
            return
         }
         
      for char in chars {
         textToShow.append("bla bla AAAA  ")
         textToShow.append(String(chars.count))
            
         
         
      
      var imageSize = inputImage.extent.size
      
       
      // Verify detected rectangle is valid.
      let boundingBox = char.boundingBox.scaled(to: imageSize)
      //print("Char bounding box")
      //print(char.boundingBox)
      textToShow.append("  Char bounding box:  ")
      textToShow.append(" x:  ")
         textToShow.append(String(describing: char.boundingBox.origin.x))
      textToShow.append(" y:  ")
         textToShow.append(String(describing: char.boundingBox.origin.y))
      guard inputImage.extent.contains(boundingBox)
         else { print("invalid detected number"); return }
      
         
         
      // Rectify the detected image and reduce it to inverted grayscale for applying model.
         let correctImage = inputImage.cropped(to: boundingBox).applyingFilter("CIColorControls",  parameters: [
            kCIInputSaturationKey: 0,
            kCIInputContrastKey: 32
            ])
            .applyingFilter("CIColorInvert", parameters: [:])
         
         
      
      // Run the CoreML MNIST clasifier -- resoults in handleClassification method
         //*
      let handler = VNImageRequestHandler(ciImage: correctImage)
      do {
         try handler.perform([classificationRequest])
      } catch {
         print(error)
      }
 //*/
   }
   }
   }
   
   
   
   //#-code-listing(RectangleDetectorSetup)
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
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
               try handler.perform([self.textRectangleRequest])
            } catch {
               print(error)
            }
            
         }
      }
      textView.text = textToShow
      
   }
   
}








