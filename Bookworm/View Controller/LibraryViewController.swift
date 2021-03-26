//
//  LibraryViewController.swift
//  Bookworm
//
//  Created by Philippe Marissal on 11.07.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import UIKit
import CoreData


//Extends UIViewController to add Toasts like in Android
extension UIViewController {
    
    func showToast(message : String, font: UIFont) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-200, width: 150, height: 70))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.numberOfLines = 3
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}


class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {
    
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    lazy var context = appDelegate.persistentContainer.viewContext
    
    var bookTitles: [String] = []
    var bookAuthors: [String] = []
    var bookpictureData: [Data] = []
    var bookPublisher: [String] = []
    var bookReleaseDate: [String] = []
    var isbnData: [String] = []
    var pagesData: [Int] = []
    var bookRead: [Bool] = []
    var whatListIsDisplayed: String = "Library"
    
    @IBOutlet weak var searchField: UISearchBar!
    
    @IBOutlet weak var libraryTableView: UITableView!
    
    @IBOutlet weak var libraryChooser: UISegmentedControl!
    
    @IBAction func selectListToShow(_ sender: Any) {
        switch libraryChooser.selectedSegmentIndex {
        case 0:
            whatListIsDisplayed = "Library"
            
        case 1:
            whatListIsDisplayed = "Wishlist"
            
        default:
            print("fehler")
            break
        }
        
        //after user changed the list which shall be shown, reload tableView
        loadSavedLibrary()
        libraryTableView.reloadData()
    }
    
    
    ///function that clears all arrays with book data, so there won't be a book two or more times in the list
    func clearLists(){
        bookTitles.removeAll()
        bookAuthors.removeAll()
        bookpictureData.removeAll()
        isbnData.removeAll()
        bookRead.removeAll()
        bookPublisher.removeAll()
        bookReleaseDate.removeAll()
    }
    
    ///When Input in Searchbar Changes, trigger loadSaveLibrary again, so only matching entries will be shown in the tableView
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        loadSavedLibrary()
        DispatchQueue.main.async {
            self.libraryTableView.reloadData()
        }
        
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return bookTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "libraryCellIdentifier", for: indexPath) as! LibraryCell
        
        //Set the Cell elements to the corresponding Book Attributes
        cell.cellTitle?.text = bookTitles[indexPath.row]
        cell.cellAuthor?.text = bookAuthors[indexPath.row]
        cell.cellCoverPicture.image = UIImage(data:bookpictureData[indexPath.row],scale:1.0)
        if (whatListIsDisplayed == "Library" && bookRead[indexPath.row] == true){
            cell.backgroundColor = UIColor(displayP3Red: 0.1, green: 1.0, blue: 0.1, alpha: 0.1)  // Change background color of cell to show that this book was marked as read
        }
        else{
            cell.backgroundColor = .white
            // need this line, otherwise books stay with a green Background if they are marked as unread after they were marked as read
        }
        return cell
    }
    
    
    /// Load Book Data from Core Data, creates custom Arra
    func loadSavedLibrary() {
        
        clearLists()   //remove all entries from the arrays, so there won't be double entries
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: whatListIsDisplayed)
        if (searchField.text?.count != 0){
            //If user has entered something in the searchbar, check titles and Authors in the showed list and only show books, where either author or title matches
            request.predicate = NSPredicate(format: "title  CONTAINS[cd] %@ OR author  CONTAINS[cd] %@", searchField.text!, searchField.text!)
        }
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                bookTitles.append(data.value(forKey: "title") as! String)
                bookAuthors.append(data.value(forKey: "author") as! String)
                bookpictureData.append(data.value(forKey: "cover_picture") as! Data)
                isbnData.append(data.value(forKey: "isbnNumber") as! String)
                bookPublisher.append(data.value(forKey: "publisher") as! String)
                bookReleaseDate.append(data.value(forKey: "release_date") as! String)
                
                if (data.value(forKey: "numberOfPages") != nil){
                    pagesData.append(data.value(forKey: "numberOfPages") as! Int)
                }
                else{
                    pagesData.append(0)
                }
                if (whatListIsDisplayed == "Library"){
                    bookRead.append(data.value(forKey: "bookAlreadyRead") as! Bool)
                }
                else{
                    bookRead.append(false)
                }
                
            }
            
        }
        catch {
            print("Failed")
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: whatListIsDisplayed)
            //Used to select the correct Entry from Core data to Delete. Use ISBN-Number since books can have the same Title
            fetchRequest.predicate = NSPredicate(format: "isbnNumber = %@", isbnData[indexPath.row])
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
            
            showToast(message: "Deleted '\(bookTitles[indexPath.row])'", font: .systemFont(ofSize: 12.0))
            
            //Also remove entry from the used Arrays
            bookTitles.remove(at: indexPath.row)
            bookAuthors.remove(at: indexPath.row)
            bookpictureData.remove(at: indexPath.row)
            isbnData.remove(at: indexPath.row)
            pagesData.remove(at: indexPath.row)
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    
    ///Reloads TableView Data if observer is notified after User wants to add a Book to the list
    ///Is annotated with @objc since we didn't know how else to solve this
    @objc func loadList(){
        loadSavedLibrary()
        libraryTableView.reloadData()
    }
    
    ///Used to hide keyboard after User presses the return-button on the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        libraryTableView.keyboardDismissMode = .onDrag //hide keyboard if User drags the tableview
        libraryTableView.delegate = self
        libraryTableView.dataSource = self
        searchField.delegate = self
        loadSavedLibrary()
        self.libraryTableView.rowHeight = 150; //This line is needed, otherwise tablerow won't be displayed properly
        
        //Observer for checking if a Book was saved to the library
        NotificationCenter.default.addObserver(self, selector: #selector(self.loadList), name:NSNotification.Name(rawValue: "load"), object: nil)
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "selectedBook" {
            let indexPaths = self.libraryTableView!.indexPathsForSelectedRows!
            
            let indexPath = indexPaths[0] as NSIndexPath
            
            let bookDetailView = segue.destination as! LibraryBookDetailViewController
            
            //Send Data about selected book to the Book Detail View
            bookDetailView.title = bookTitles[indexPath.item]
            bookDetailView.titleString = bookTitles[indexPath.item]
            bookDetailView.authorString = bookAuthors[indexPath.item]
            bookDetailView.numberOfPages = pagesData[indexPath.item]
            bookDetailView.coverPictureData = bookpictureData[indexPath.item]
            bookDetailView.releaseDateString = bookReleaseDate[indexPath.item]
            bookDetailView.publisherString = bookPublisher[indexPath.item]
            bookDetailView.isbnNumber = isbnData[indexPath.item]
            bookDetailView.alreadyRead = bookRead[indexPath.item]
            bookDetailView.whereSaved = whatListIsDisplayed
            
        }
    }
}

//Create custom Cell for TableView
class LibraryCell: UITableViewCell {
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellAuthor: UILabel!
    @IBOutlet weak var cellCoverPicture: UIImageView!
}
