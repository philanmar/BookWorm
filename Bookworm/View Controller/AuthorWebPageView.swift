//
//  AuthorWebPageView.swift
//  Bookworm
//
//  Created by Philippe Marissal on 01.07.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import UIKit
import WebKit

//Extension to create working urls
extension String {
    func stringByAddingPercentEncodingForRFC3986() -> String? {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
}

class AuthorWebPageView: UIViewController,WKUIDelegate {

    var webView: WKWebView!
    var authorName: String?
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the URL to show the Wikipedia Page for the given Author
        var wikiURL = "https://m.wikipedia.org/wiki?search="
        wikiURL.append((authorName?.stringByAddingPercentEncodingForRFC3986())!)
        
        webView.load(NSURLRequest(url: NSURL(string: wikiURL)! as URL) as URLRequest)
    }
    
}
