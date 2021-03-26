//
//  SearchForISBNViewController.swift
//  Bookworm
//
//  Created by Philippe Marissal on 21.06.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import UIKit
import CoreData

///Extension of String to check if entered String only contains numbers, so if user enters something else than a valid isbn number, it returns false
extension String {
    
    var isNumeric: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
}

class SearchForISBNViewController: UIViewController, UITextFieldDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    lazy var context = appDelegate.persistentContainer.viewContext
    
    var bookData: Isbn?
    var enteredISBN: String?
    var savedISBNArray: [String] = []

    @IBOutlet weak var isbnInputfield: UITextField!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    ///Button, so User can instantly add a custom book without trying to enter the ISBN in the first place
    @IBAction func addBookManuallyButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "enterCustomBook", sender: self)
    }
    
    @IBAction func sendISBNSearchRequest(_ sender: Any) {
        searchForISBN(isbn: isbnInputfield.text!)
    }
    
    func searchForISBN(isbn: String){
        let isbnUserInput: String = isbn.replacingOccurrences(of: "-", with: "")    //removes '-' from the ISBN in case User copied an ISBN from the internet, where these characters are used in the ISBN

        if (self.savedISBNArray.contains(isbnUserInput)){
            let alert = UIAlertController(title: "ISBN already saved in Library", message: "There is already a Book for given ISBN saved in your Library", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            
            //make textField for the BookTitle slighthly red, so user sees, that he must enter something here (in addition to the Dialog)
            self.present(alert, animated: true)
        }
        else{
        
        //Read UserInput from Textinputfield and save it into a String, also remove '-' Characters from input, since often online you find isbn with '-' in it, so you can just copy&paste it.
        
        self.loadingIndicator.startAnimating()
        
        enteredISBN = isbnUserInput //pass entered isbn to variable, so it is accessible from outside this function
        
        if (isbnUserInput.isNumeric && (isbnUserInput.count == 10 || isbnUserInput.count == 13)){
            // Checks if user input only contains numbers as ISBN-Numbers only consists of numbers, not characters
            // Also Check if it is a valid ISBN Number with 10 or 13 Numbers
            
            
            // Insert isbn-Number given by user in URL for a search request
            let searchURL = "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbnUserInput)&format=json&jscmd=data"
            
                guard let url = URL(string: searchURL) else {
                    print("Error: cannot create URL")
                    return
                }
                let urlRequest = URLRequest(url: url)
                let session = URLSession.shared
                
                let task = session.dataTask(with: urlRequest) { data, response, error in
                    
                    if error != nil || data == nil {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            self.showNoConnectionDialog()
                        }
                        return
                    }
                    
                   guard let data = data else {
                        return
                    }
                    
                        do{
                            //Decode json data from API. Since you always get another structure / identifier per book, this has to be solved like this.
                            let dictionary = try JSONDecoder().decode([String:Isbn].self, from: data)
                            self.bookData = dictionary["ISBN:\(isbnUserInput)"]
                            
                            DispatchQueue.main.async {
                                if (self.bookData?.title != nil && self.bookData?.authors[0] != nil){
                                    //Only perform segue, if search found a book, otherwise an alert will be shown to tell the user, that there was no match for given ISBN.
                                    self.performSegue(withIdentifier: "showISBNDetail", sender: nil)
                                }
                                else{
                                    self.nothingFound()
                                }
                                self.loadingIndicator.stopAnimating()
                            }
                            return
                            
                        }catch{
                            
                            print(error)
                        }
                   
            }
            task.resume()
            
        }
        else{
            self.loadingIndicator.stopAnimating()
            
            let alert = UIAlertController(title: "Invalid Input", message: "You entered something else than an ISBN. Please only enter ISBN-Numbers", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSavedLibrary()
        loadSavedWishlist()
        self.isbnInputfield.delegate = self
        
    }
    
    ///Used to hide the Keyboard if User taps anywhere on the screen while the keyboard is shown
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    ///Show Dialog to inform User, that his device isn't connected to the Internet and so the App cant' make a request for given ISBN
    func showNoConnectionDialog(){
        let alert = UIAlertController(title: "No Connection", message: "Seems like you don't have access to the Internet. In this case, we can't search for given ISBN. Do you want to add a Book manually?", preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { ACTION in
            self.performSegue(withIdentifier: "enterCustomBook", sender: self)}))

        alert.addAction(UIAlertAction(title: "Abort", style: .cancel, handler: nil))
        
        //make textField for the BookTitle slighthly red, so user sees, that he must enter something here (in addition to the Dialog)
        self.present(alert, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    /// Shows Dialog to inform User, that the Request didn't result in a found book for given ISBN Number. Then User can choose to either try again or enter book manually
    func nothingFound(){
        let alert = UIAlertController(title: "Nothing found", message: "There were no matches for your entered ISBN.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Add Book manually", style: .default, handler: { ACTION in
            self.performSegue(withIdentifier: "enterCustomBook", sender: self)
        }))

        self.present(alert, animated: true)
        
    }
    
    
    
    //override the prepare function to send the book data to the BookDetailView
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "enterCustomBook"){
            let customBookAddView = segue.destination as! AddCustomBookController
            customBookAddView.isbnString = enteredISBN
        }
        
        if (segue.identifier == "showISBNDetail") {
            
            let bookDetailView = segue.destination as! SearchedBookDetailViewController
            
            bookDetailView.title = self.bookData?.title
            
            //only send cover URL to SearchedBookDetailView if there is a link for a cover picture
            if (self.bookData?.cover?.large != nil){
                bookDetailView.coverPictureURLString = self.bookData?.cover?.large!
            }
            bookDetailView.authorString = self.bookData?.authors[0].name
            bookDetailView.titleString = self.bookData?.title
            bookDetailView.releaseDateString = self.bookData?.publishDate
            bookDetailView.isbnNumberString = self.enteredISBN
            
            if (self.bookData?.publishers![0].name != nil){
                bookDetailView.publisherString = self.bookData?.publishers![0].name
            }
            
            //only send the number of pages to the view if it's not nil
            if (self.bookData?.numberOfPages != nil){
                bookDetailView.numberOfPages = bookData?.numberOfPages
            }
        }
    }
    
    ///Used to get all saved Books by their ISBN in the Bookshelf
    func loadSavedLibrary() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                savedISBNArray.append(data.value(forKey: "isbnNumber") as! String)
          }
            
        } catch {
            
            print("Failed")
        }
    }
    
    ///Used to get all saved Books by their ISBN in the Wishlist
    func loadSavedWishlist() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Wishlist")
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
