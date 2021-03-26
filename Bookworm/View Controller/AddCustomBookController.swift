//
//  AddCustomBookController.swift
//  Bookworm
//
//  Created by Philippe Marissal on 13.07.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import UIKit

///Extension to rotate custom Cover Pictures, otherwise they will be saved rotated 90 degrees in the Library / Wishlist
extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

class AddCustomBookController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var isbnTextField: UITextField!
    @IBOutlet weak var bookTitleTextField: UITextField!
    @IBOutlet weak var authorTextField: UITextField!
    @IBOutlet weak var publisherTextField: UITextField!
    @IBOutlet weak var releaseDateTextField: UITextField!
    @IBOutlet weak var numberOfPagesTextField: UITextField!
    
    @IBOutlet weak var whereToSaveChoser: UISegmentedControl!
        
    var isbnString: String?
    var pictureData: Data?
    var setWhereToSave: String = "Library"
    
    var imagePicker: UIImagePickerController!
    
    
    @IBAction func selectWhereToSave(_ sender: Any) {
        switch whereToSaveChoser.selectedSegmentIndex {
        case 0:
            setWhereToSave = "Library"
            
        case 1:
            setWhereToSave = "Wishlist"
        default:
            print("Error saving book to \(setWhereToSave)")
            break
        }
    }
    
    ///triggered, when user presses the next button. Checks if User entered a Title and a isbn-number with at least 1 Character. Also asks, if user wants to take a picture for his book
    @IBAction func nextButtonPressed(_ sender: Any) {
        
        //Bools for checking if either book or title are entered or not
        var bookTitleEntered: Bool = false
        var isbnEntered: Bool = false

        if (bookTitleTextField.text?.count == 0){
            bookTitleEntered = false
            //Pops up, when user didn't enter a title for the book. every book needs a title
            let alert = UIAlertController(title: "No title entered", message: "Please enter a title for your Book", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            
            //make textField for the BookTitle slighthly red, so user sees, that he must enter something here (in addition to the Dialog)
            bookTitleTextField.backgroundColor = UIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 0.1)

            self.present(alert, animated: true)
        }
        else {
            bookTitleEntered = true
            bookTitleTextField.backgroundColor = .white
        }
        if (isbnTextField.text?.count == 0){
            isbnEntered = false

            //Pops up, when user didn't enter a ISBN for the book. every book needs a title
            let alert = UIAlertController(title: "No ISBN entered", message: "Please enter a ISBN for your Book", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
           
            //make textField for the BookTitle slighthly red, so user sees, that he must enter something here (in addition to the Dialog)
            isbnTextField.backgroundColor = UIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 0.1)

            self.present(alert, animated: true)
        }
        else if (isbnTextField.text?.isNumeric == false){
            isbnEntered = false

             //Pops up, when user didn't enter a ISBN for the book. every book needs a title
             let alert = UIAlertController(title: "No valid ISBN entered", message: "Your entered ISBN contains characters, which are not allowed. Only numbers (0-9) are allowed.", preferredStyle: .alert)
             alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            
             //make textField for the BookTitle slighthly red, so user sees, that he must enter something here (in addition to the Dialog)
             isbnTextField.backgroundColor = UIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 0.1)

             self.present(alert, animated: true)
        }
        else{
            isbnEntered = true
            isbnTextField.backgroundColor = .white
        }
        //only show dialog for going to next view or add a cover picture if there is a title and a isbn
        if (bookTitleEntered && isbnEntered){
            showAddCoverPictureDialog()
        }
    }
    
    func showAddCoverPictureDialog(){
        let alert = UIAlertController(title: "Add Cover Picture", message: "Do you want to take a Cover Picture for your Book?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {ACTION in
            self.saveCoverPicture()
        }))
        
        alert.addAction(UIAlertAction(title: "Add book without Picture", style: .default, handler: { ACTION in
            self.performSegue(withIdentifier: "showEnteredCustomBook", sender: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //delegate all the textfields so that the keyboard can be closed by the function textFieldShouldReturn via pressing the return button of the keyboard
        self.isbnTextField.delegate = self
        self.bookTitleTextField.delegate = self
        self.authorTextField.delegate = self
        self.numberOfPagesTextField.delegate = self
        self.publisherTextField.delegate = self
        self.releaseDateTextField.delegate = self
        
        isbnTextField.text = isbnString         //Take entered ISBN and place it in the textfield, so user doesn't has to enter it again
        
    }
    
    ///Used to hide the Keyboard if User taps anywhere on the screen while the keyboard is shown
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func saveCoverPicture(){
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera  //directs View Controller to the Camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "takeCoverPicture" {
            
            let customBookDetailView = segue.destination as! CustomBookDetailViewController
            
            //send values to the customBookViewController
            customBookDetailView.titleString = bookTitleTextField.text
            customBookDetailView.title = bookTitleTextField.text
            customBookDetailView.setWhereToSave = self.setWhereToSave
            customBookDetailView.isbnNumberString = isbnTextField.text
            customBookDetailView.coverPictureData = pictureData
            
            if (authorTextField.text == nil || authorTextField.text!.count == 0) {
                //when user didn't enter anything for the author, set the author to "No Author specified"
                customBookDetailView.authorString = "No Author specified"
            }
            else {
                customBookDetailView.authorString = authorTextField.text
            }
            
            if (publisherTextField.text == nil || publisherTextField.text!.count == 0) {
                //when user didn't enter anything for the publisher, set the publisher to "No Publisher specified"
                customBookDetailView.publisherString = "No Publisher specified"
            }
            else {
                customBookDetailView.publisherString = publisherTextField.text
            }
            
            if (releaseDateTextField.text == nil || releaseDateTextField.text!.count == 0) {
                //when user didn't enter anything for the release date, set the release date  to "unknown"
                customBookDetailView.releaseDateString = "Unknown"
            }
            else {
                customBookDetailView.releaseDateString = releaseDateTextField.text
            }
            
            if (numberOfPagesTextField.text == nil || numberOfPagesTextField.text!.count == 0) {
                //when user didn't enter anything for the release date, set the release date  to "unknown"
                customBookDetailView.numberOfPages = 0
            }
            else {
                customBookDetailView.numberOfPages = Int(numberOfPagesTextField.text!)
            }
            
        }
        if segue.identifier == "showEnteredCustomBook" {
            let customBookDetailView = segue.destination as! CustomBookDetailViewController
            customBookDetailView.titleString = bookTitleTextField.text
            customBookDetailView.title = bookTitleTextField.text
            customBookDetailView.setWhereToSave = self.setWhereToSave
            customBookDetailView.isbnNumberString = isbnTextField.text
            if (authorTextField.text == nil || authorTextField.text!.count == 0) {
                //when user didn't enter anything for the author, set the author to "No Author specified"
                customBookDetailView.authorString = "No Author specified"
            }
            else {
                customBookDetailView.authorString = authorTextField.text
            }
            
            if (publisherTextField.text == nil || publisherTextField.text!.count == 0) {
                //when user didn't enter anything for the publisher, set the publisher to "No Publisher specified"
                customBookDetailView.publisherString = "No Publisher specified"
            }
            else {
                customBookDetailView.publisherString = publisherTextField.text
            }
            
            if (releaseDateTextField.text == nil || releaseDateTextField.text!.count == 0) {
                //when user didn't enter anything for the release date, set the release date  to "unknown"
                customBookDetailView.releaseDateString = "Unknown"
            }
            else {
                customBookDetailView.releaseDateString = releaseDateTextField.text
            }
            
            if (numberOfPagesTextField.text == nil || numberOfPagesTextField.text!.count == 0) {
                //when user didn't enter anything for the release date, set the release date  to "unknown"
                customBookDetailView.numberOfPages = 0
            }
            else {
                customBookDetailView.numberOfPages = Int(numberOfPagesTextField.text!)
            }
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        pictureData = image.rotate(radians: 0)!.pngData()  // save rotated imageData to send it to the preview-View
        self.performSegue(withIdentifier: "takeCoverPicture", sender: self)

    }
}
