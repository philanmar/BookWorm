//
//  SearchedBookDetailViewController.swift
//  Bookworm
//
//  Created by Philippe Marissal on 21.06.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import UIKit
import CoreData






///Extension for UIImageView to download a cover Picture via URL
extension UIImageView {
   func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
      URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
   }
   
    func downloadImage(from url: URL) {
      getData(from: url) {
         data, response, error in
         guard let data = data, error == nil else {
            return
         }
         DispatchQueue.main.async() {
            self.image = UIImage(data: data)
         }
      }
   }
}


class SearchedBookDetailViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var posterIMGView: UIImageView!
    
    var savedISBNArray: [String] = []
    
    var authorString: String?
    var titleString: String?
    var releaseDateString: String?
    var coverPictureURLString: URL?
    var isbnNumberString: String?
    var authorURL: String?
    var publisherString: String?
    var numberOfPages: Int?
    
    var bookAlreadyRead: Bool = false
    
    var setWhereToSave : String = "Library"
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bookTitle: UILabel!
    @IBOutlet weak var bookAuthor: UILabel!
    @IBOutlet weak var bookYear: UILabel!
    @IBOutlet weak var bookPublisher: UILabel!
    @IBOutlet weak var bookPages: UILabel!
    @IBOutlet weak var bookPagesLabel: UILabel!
    
    @IBOutlet weak var readBookLabel: UILabel!
    @IBOutlet weak var readBookSwitch: UISwitch!
        
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    @IBOutlet weak var saveToLibraryButton: UIButton!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    lazy var context = appDelegate.persistentContainer.viewContext
    
    
    //gets value of the switch, which marks book either as read or not
    @IBAction func readBookSwitchChecked(_ sender: Any) {
        switch readBookSwitch.isOn{
        case true:
            bookAlreadyRead = true
        case false:
            bookAlreadyRead = false
        }
    }
    
    
    //Check if User wants to save Book in Wishlist. Then make Switch not usable.
    @IBAction func segmentedControlChooser(_ sender: Any) {
        switch segmentControl.selectedSegmentIndex {
            case 0:
                readBookLabel.isEnabled = true
                readBookSwitch.isEnabled = true
            case 1:
                readBookLabel.isEnabled = false
                readBookSwitch.isEnabled = false
            default:
                print("Error changing between Library and Wishlist")
            break
        }
        //After user changes in which part of the Library the book shall be saved, check again if book is already saved in that part of the Library and set the save button either to Enabled or Disabled
        loadSavedLibrary()
        if (self.savedISBNArray.contains(self.isbnNumberString!)){
            self.saveToLibraryButton.isEnabled = false
            self.saveToLibraryButton.setTitle("Already Saved", for: .normal)
        }
        else{
            self.saveToLibraryButton.isEnabled = true
        }
    }
    
    @IBAction func saveBookToLibrary(_ sender: Any) {
        
        switch segmentControl.selectedSegmentIndex {
        case 0:
            setWhereToSave = "Library"
            
            //check switch again, so correct value is saved in bool variable in case user switches from library to wishlist and back
            switch readBookSwitch.isOn{
            case true:
                bookAlreadyRead = true
            case false:
                bookAlreadyRead = false
            }
        case 1:
            setWhereToSave = "Wishlist"
            bookAlreadyRead = false
        default:
            print("Error saving book to \(setWhereToSave)")
        break
        }
        
        let entity = NSEntityDescription.entity(forEntityName: setWhereToSave, in: context)
        
        let newLibraryEntry = NSManagedObject(entity: entity!, insertInto: context)
        
        //insert values of given book into Core Data
        newLibraryEntry.setValue(titleString, forKey: "title")
        newLibraryEntry.setValue(authorString, forKey: "author")
        newLibraryEntry.setValue(releaseDateString, forKey: "release_date")
        newLibraryEntry.setValue(isbnNumberString, forKey: "isbnNumber")
        newLibraryEntry.setValue(publisherString, forKey: "publisher")
        newLibraryEntry.setValue(releaseDateString, forKey: "release_date")
        
        if (numberOfPages != nil){
            newLibraryEntry.setValue(numberOfPages, forKey: "numberOfPages")
        }
        
        //only if the book is going to be saved in the Library, save also the value if it was already read or not
        if (setWhereToSave == "Library"){
            newLibraryEntry.setValue(bookAlreadyRead, forKey: "bookAlreadyRead")
        }
        
        //If there is a cover pictore loaded, save it also to core data
        if (posterIMGView.image != nil){
            newLibraryEntry.setValue(posterIMGView.image?.pngData(), forKey: "cover_picture")
        }
        
        do {
           try context.save()
            self.saveToLibraryButton.setTitle("Saved to \(setWhereToSave)", for: .normal)
            self.saveToLibraryButton.isEnabled = false  //disable Button, since book was already saved
            
            
            //Send Notification to observer in LibraryViewController that a book was saved to the Library and the tableview has to be updated
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
            showToast(message: "Book saved", font: .systemFont(ofSize: 12.0))
            print("saved")
            
          } catch {
           print("Failed saving")
        }
        
        
        
    }
    
    //function to fetch data for coverpicture, used to make it possible to controll wether user can already save book to library or not
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    
    ///downloads the coverpicture and handles the "save to library" button
    func downloadImage(from url: URL) {
        self.loadingIndicator.startAnimating()
        saveToLibraryButton.isEnabled = false
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async() {
                self.posterIMGView.image = UIImage(data: data)
                
                //Check if book was already saved. If so, make button not clickable and change text so user sees that this book was already saved in his library
                if (self.savedISBNArray.contains(self.isbnNumberString!)){
                    
                    self.saveToLibraryButton.isEnabled = false
                    self.saveToLibraryButton.setTitle("Already Saved", for: .normal)
                }
                else{
                    self.saveToLibraryButton.isEnabled = true
                }
                 self.loadingIndicator.stopAnimating()

            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSavedLibrary()
        showBookData()
    }
    
    
    ///Sets View elements with Data to show Details about the book
    func showBookData(){
        
        if (coverPictureURLString != nil){
            downloadImage(from: coverPictureURLString!)
        }
        else{
            //if there is no picture for this book on the server -> make save button usable
            //also use placeholder image
            saveToLibraryButton.isEnabled = true
            self.posterIMGView.image = #imageLiteral(resourceName: "nocoverimg")
        }
        if (authorString != nil){
            let tap = UITapGestureRecognizer(target: self, action: #selector(SearchedBookDetailViewController.tapFunction))
            bookAuthor.isUserInteractionEnabled=true
            bookAuthor.addGestureRecognizer(tap)
            bookAuthor.textColor = UIColor.blue
            
        }
        bookTitle.text = titleString
        bookAuthor.text = authorString
        bookYear.text = releaseDateString
        if (publisherString != nil){
            bookPublisher.text = publisherString
        }
        else{
            bookPublisher.isHidden = true
        }
        
        if (numberOfPages != nil){
            bookPages.text = "\(numberOfPages!) Pages"
        }
        else{
            bookPagesLabel.isHidden = true
            bookPages.isHidden = true
        }
        
    }
    

    /// custom tap function for the Author, so User can view Wikipedia Article of the Author
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
    
    ///Loads saved books from core data, so this App can check, if a book was already saved into core data. For this, there is a check to see, if the isbn-number, was already saved in core data
    func loadSavedLibrary() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: setWhereToSave)
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                savedISBNArray.append(data.value(forKey: "isbnNumber") as! String)
          }
            
        } catch {
            
            print("Failed")
        }
    }
}
