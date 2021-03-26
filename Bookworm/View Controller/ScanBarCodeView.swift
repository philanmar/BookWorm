//
//  ScanBarCodeView.swift
//  Bookworm
//
//  Created by Philippe Marissal on 18.06.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import AVFoundation
import UIKit
import CoreData


class ScanBarCodeView: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var scanSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var ISBNCode: String?
    var bookData: Isbn?
    var savedISBNArray: [String] = []
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    lazy var context = appDelegate.persistentContainer.viewContext
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        scanBarcode()
    }
    
    func scanBarcode(){
        scanSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video)
            else {
                return
        }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        }
        catch {
            return
        }
        
        if (scanSession.canAddInput(videoInput)) {
            scanSession.addInput(videoInput)
        }
        else {
            scanFailed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (scanSession.canAddOutput(metadataOutput)) {
            scanSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417]
        }
        else {
            scanBarcode()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: scanSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        scanSession.startRunning()
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
    
    func scanFailed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
        scanSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (scanSession?.isRunning == false) {
            scanSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (scanSession?.isRunning == true) {
            scanSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        scanSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            barCodeFound(code: stringValue)
        }
        
        dismiss(animated: true)
    }
    
    func barCodeFound(code: String) {
        
        if (self.savedISBNArray.contains(code)){
            let alert = UIAlertController(title: "ISBN already saved in Library", message: "There is already a Book for given ISBN saved in your Library", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            
            //make textField for the BookTitle slighthly red, so user sees, that he must enter something here (in addition to the Dialog)
            self.present(alert, animated: true)
        }
        else{
        
        self.loadingIndicator.startAnimating()
        
        
            let searchURL = "https://openlibrary.org/api/books?bibkeys=ISBN:\(code)&format=json&jscmd=data"
                guard let url = URL(string: searchURL) else {
                    print("Error: cannot create URL")
                    return
                }
                let urlRequest = URLRequest(url: url)
                let session = URLSession.shared
                
                let task = session.dataTask(with: urlRequest) { data, response, error in
                    
                    //First check, if there's a active Internet Connection. If there's none, the request will give an Error. In this case, show Dialog
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
                            self.ISBNCode = code
                            let dictionary = try JSONDecoder().decode([String:Isbn].self, from: data)
                            self.bookData = dictionary["ISBN:\(code)"]
                            

                            DispatchQueue.main.async {
                                if (self.bookData?.title != nil && self.bookData?.authors[0] != nil){
                                    //Only perform segue, if search found a book
                                    self.performSegue(withIdentifier: "showBarcodeDetail", sender: nil)
                                }
                                else{
                                    //If there was
                                      let alert = UIAlertController(title: "Nothing found", message: "There were no matches for your entered ISBN.", preferredStyle: .alert)
                                          
                                          alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                                          
                                          alert.addAction(UIAlertAction(title: "Add Book manually", style: .default, handler: { ACTION in
                                              self.performSegue(withIdentifier: "enterCustomBook", sender: self)
                                          }))

                                          self.present(alert, animated: true)
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
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBarcodeDetail" {
            
            let bookDetailView = segue.destination as! SearchedBookDetailViewController
            bookDetailView.title = self.bookData?.title
            
            //only send cover URL to SearchedBookDetailView if there is a link for a cover picture
            if (self.bookData?.cover?.large != nil){
                bookDetailView.coverPictureURLString = self.bookData?.cover?.large!
            }
            bookDetailView.authorString = self.bookData?.authors[0].name
            bookDetailView.titleString = self.bookData?.title
            bookDetailView.releaseDateString = self.bookData?.publishDate
            bookDetailView.isbnNumberString = self.ISBNCode
            
            if (self.bookData?.publishers![0].name != nil){
                bookDetailView.publisherString = self.bookData?.publishers![0].name
            }
            
            //only send the number of pages to the view if it's not nil
            if (self.bookData?.numberOfPages != nil){
                bookDetailView.numberOfPages = bookData?.numberOfPages
            }
        }
        
        if (segue.identifier == "enterCustomBook"){
            let customBookAddView = segue.destination as! AddCustomBookController
            customBookAddView.isbnString = ISBNCode
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


