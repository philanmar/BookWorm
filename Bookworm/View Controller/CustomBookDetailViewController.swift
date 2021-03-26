//
//  CustomBookDetailViewController.swift
//  Bookworm
//
//  Created by Philippe Marissal on 22.07.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import UIKit
import CoreData


class CustomBookDetailViewController: UIViewController {

    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    lazy var context = appDelegate.persistentContainer.viewContext
    
    var authorString: String?
    var titleString: String?
    var releaseDateString: String?
    var coverPictureData: Data?
    var isbnNumberString: String?
    var authorURL: String?
    var publisherString: String?
    var numberOfPages: Int?
    
    var setWhereToSave: String?
    
    var alreadyRead: Bool = false
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publisherLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var pagesLabel: UILabel!
    @IBOutlet weak var numberPagesHeader: UILabel!
    
    @IBOutlet weak var coverPicture: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var bookReadStackView: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (setWhereToSave == "Wishlist"){
            bookReadStackView.isHidden = true
        }
        else {
            bookReadStackView.isHidden = false
        }
        
        saveButton.setTitle("Save to \(setWhereToSave!)", for: .normal)
        showBookData()
                

    }
    
    
    @IBAction func saveBookButton(_ sender: Any) {
        saveBookToLibrary()
    }
    
    @IBOutlet weak var readBookSwitch: UISwitch!
    
    func showBookData() {
        titleLabel.text = titleString
        authorLabel.text = authorString
        releaseDateLabel.text = releaseDateString
        publisherLabel.text = publisherString
        
        if (numberOfPages == 0){
            numberPagesHeader.isHidden = true
            self.pagesLabel.isHidden = true
        }
        else {
            pagesLabel.text = "\(numberOfPages!) Pages"
        }
        
        if (coverPictureData == nil) {
            //if no coverpicture was added by user with his camera, use the placeholder-picture
            coverPicture.image = #imageLiteral(resourceName: "nocoverimg.jpg")
        }
        else {
            coverPicture.image = UIImage(data:coverPictureData!,scale:1.0)
        }
        
    }
    
    func saveBookToLibrary() {
        //Switch for where to save
        
        let entity = NSEntityDescription.entity(forEntityName: self.setWhereToSave!, in: context)
        
        let newLibraryEntry = NSManagedObject(entity: entity!, insertInto: context)
        
        //insert values of given book into Core Data
        newLibraryEntry.setValue(titleString, forKey: "title")
        newLibraryEntry.setValue(authorString, forKey: "author")
        newLibraryEntry.setValue(releaseDateString, forKey: "release_date")
        newLibraryEntry.setValue(isbnNumberString, forKey: "isbnNumber")
        newLibraryEntry.setValue(publisherString, forKey: "publisher")
        newLibraryEntry.setValue(releaseDateString, forKey: "release_date")
        newLibraryEntry.setValue(numberOfPages, forKey: "numberOfPages")
        
        if (setWhereToSave == "Library") {
            newLibraryEntry.setValue(readBookSwitch.isOn, forKey: "bookAlreadyRead")
        }
        
        if (coverPictureData == nil) {
            //if no coverpicture was added by user with his camera, use the placeholder-picture
            newLibraryEntry.setValue(#imageLiteral(resourceName: "nocoverimg.jpg").pngData(), forKey: "cover_picture")
        }
        else {
            newLibraryEntry.setValue(coverPictureData, forKey: "cover_picture")
        }
        
        do {
           try context.save()
            performSegue(withIdentifier: "goBackToLibrary", sender: self)
            //Send Notification to observer in LibraryViewController that a book was saved to the Library and the tableview has to be updated
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
            print("saved")
            
          } catch {
           print("Failed saving")
        }
        
        
            }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goBackToLibrary"){
            let libraryView = segue.destination as! TabBarController
            libraryView.hidesBottomBarWhenPushed = true //hide the tab bar when segue is used, so ther won't be two tabbars after segue
            libraryView.navigationItem.hidesBackButton = true;      //Hide Back Button when the Library is shown again after Book was saved, otherwise user could go back to the custom book detail view
            
            self.navigationController?.navigationBar.isHidden = true  //Hides navigation Bar on segue, otherwise Navigationbar would be shown two times (or more)
        }
    }
    

}
