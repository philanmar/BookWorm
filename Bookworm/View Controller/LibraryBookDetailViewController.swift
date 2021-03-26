//
//  LibraryBookDetailViewController.swift
//  Bookworm
//
//  Created by Philippe Marissal on 14.07.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import UIKit
import CoreData

class LibraryBookDetailViewController: UIViewController {
    
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    lazy var context = appDelegate.persistentContainer.viewContext
    
    var titleString: String?
    var authorString: String?
    var publisherString: String?
    var releaseDateString: String?
    var numberOfPages: Int?
    var alreadyRead: Bool?
    var coverPictureData: Data?
    var isbnNumber: String?
    var whereSaved: String?
    
    @IBOutlet weak var bookReadSwitch: UISwitch!
    @IBOutlet weak var alreadyReadStackView: UIStackView!
    
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookPublisherLabel: UILabel!
    @IBOutlet weak var bookAuthorLabel: UILabel!
    @IBOutlet weak var bookReleaseDateLabel: UILabel!
    @IBOutlet weak var bookPages: UILabel!
    @IBOutlet weak var bookPagesLabel: UILabel!
    @IBOutlet weak var coverPictureImageView: UIImageView!
    
    @IBOutlet weak var moveToBookshelfButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showBookData()
        setButtonAndSwitchOnViewAppears()
    }
    
    @IBAction func bookReadSwitchChange(_ sender: Any) {
        saveBookReadChanges()
    }
    
    @IBAction func moveBookToBookshelfButtonPressed(_ sender: Any) {
        removeBookFromWishlist()
        addBookToBookshelf()
        whereSaved = "Library"      //Set book saved location to the Bookshelf, so the correct Core Data entry will be used when user also marks it as read after he moved it to the bookshelf
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)   //Update TableView in LibraryViewController
        
        showToast(message: "Book moved to Bookshelf", font: .systemFont(ofSize: 12.0))
        moveToBookshelfButton.isHidden = true   //hide button after Book moved from Wishlist to Bookshelf
        alreadyReadStackView.isHidden = false     //show Switch to set book to read or not after book was moved to the Library
    }
    
    
    func removeBookFromWishlist(){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Wishlist")
        //Used to select the correct Entry from Core data to Delete. Use ISBN-Number since books can have the same Title
        fetchRequest.predicate = NSPredicate(format: "isbnNumber = %@", isbnNumber!)    //Use ISBN as unique Identifier to find correct entry
        do {
            let tryDelete = try context.fetch(fetchRequest)
            
            let entryToDelete = tryDelete[0] as! NSManagedObject
            context.delete(entryToDelete)
            
            do{
                try context.save()
                
            }
            catch{
                print("Error Deleting Entry from Core Data")
            }
        }
        catch{
            print("Could not delete Entry from Core Data")
        }
        
    }
    
    ///add entry to bookshelf. Is called after entry is removed from the Wishlist in order to add it to the library
    func addBookToBookshelf(){
       
        let entity = NSEntityDescription.entity(forEntityName: "Library", in: context)
        
        let newLibraryEntry = NSManagedObject(entity: entity!, insertInto: context)
        
        //insert values of given book into Core Data
        newLibraryEntry.setValue(titleString, forKey: "title")
        newLibraryEntry.setValue(authorString, forKey: "author")
        newLibraryEntry.setValue(releaseDateString, forKey: "release_date")
        newLibraryEntry.setValue(isbnNumber, forKey: "isbnNumber")
        newLibraryEntry.setValue(publisherString, forKey: "publisher")
        newLibraryEntry.setValue(releaseDateString, forKey: "release_date")
        newLibraryEntry.setValue(numberOfPages, forKey: "numberOfPages")
        newLibraryEntry.setValue(false, forKey: "bookAlreadyRead")
        newLibraryEntry.setValue(coverPictureData, forKey: "cover_picture")
        
        
        do {
           try context.save()
          
            print("saved")
            
          } catch {
           print("Failed saving")
        }
        
        
    }
    
    ///Changes Value of "bookAlreadyRead" in Core Data. Is called when the switch value changes
    func saveBookReadChanges(){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: whereSaved!)
            //Used to select the correct Entry from Core data to Delete. Use ISBN-Number since books can have the same Title
            fetchRequest.predicate = NSPredicate(format: "isbnNumber = %@", isbnNumber!)
            
            do {
                let tryModify = try context.fetch(fetchRequest)
                
                let entryToModify = tryModify[0] as! NSManagedObject
                entryToModify.setValue(bookReadSwitch.isOn, forKey: "bookAlreadyRead")
                
                do{
                    try context.save()
                    if bookReadSwitch.isOn{
                        showToast(message: "Book marked as read", font: .systemFont(ofSize: 12.0))
                    }
                    else{
                        showToast(message: "Book marked as not read", font: .systemFont(ofSize: 12.0))
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)   //Update TableView in LibraryViewController

                }
                catch{
                    print("Error Deleting Entry from Core Data")
                }
            }
            catch{
                print("Could not delete Entry from Core Data")
            }

    }
    
    
    ///First checks, if there is a value, to see if it's just on the wishlist (and not read yet) or if it's in the library an set either as read or not
    func setButtonAndSwitchOnViewAppears(){
        if(whereSaved == "Wishlist"){
            //hides the switch if book has no "read"-value, which means it must be saved in the wishlist
            alreadyReadStackView.isHidden = true
            moveToBookshelfButton.isHidden = false
        }
        else{
            moveToBookshelfButton.isHidden = true
            if(alreadyRead!){
                bookReadSwitch.isOn = true
            }
            else{
                bookReadSwitch.isOn = false
            }
        }
    }
    
    
    ///Sets all the Values for the UI Elements to show when View is called
    func showBookData(){
        
        //converts saved book picture data back to an showable image an sets it as image for the cover picture
        coverPictureImageView.image = UIImage(data:coverPictureData!,scale:1.0)

        if (authorString != "No Author specified"){
            let tap = UITapGestureRecognizer(target: self, action: #selector(SearchedBookDetailViewController.tapFunction))
            bookAuthorLabel.isUserInteractionEnabled=true
            bookAuthorLabel.addGestureRecognizer(tap)
            bookAuthorLabel.textColor = UIColor.blue
            
        }
        bookTitleLabel.text = titleString
        bookAuthorLabel.text = authorString
        bookReleaseDateLabel.text = releaseDateString
        
        //hides the number of pages if there wasn's a value to save in the first place
        if (numberOfPages != 0){
            bookPagesLabel.text = "\(numberOfPages!) Pages"
        }
        else{
            bookPages.isHidden = true
            bookPagesLabel.isHidden = true
        }
        
    }
    
    ///Custom Tab function for the Author Name, so User can view the Wikipedia-Page for given Author
    @IBAction func tapFunction(sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "showAuthorPage", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showAuthorPage" {
        let authorWebView = segue.destination as! AuthorWebPageView
        authorWebView.title = authorString
        authorWebView.authorName = authorString
        }
        
    }

}
