//
//  Book.swift
//  Bookworm
//
//  Created by Philippe Marissal on 22.06.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import Foundation


class Books: Codable {
    let isbn: Isbn?

    enum CodingKeys: String, CodingKey {
        case isbn
    }
}

struct Isbn: Codable {
    let publishers: [Publisher]?
    let identifiers: Identifiers?
    let weight: String?
    let title: String
    let url: String?
    let numberOfPages: Int?
    let cover: Cover?
    let subjectPlaces: [Author]?
    let subjects: [Author]?
    let subjectPeople: [Author]?
    let key: String?
    let authors: [Author]
    let publishDate: String?
    let ebooks: [Ebook]?

    enum CodingKeys: String, CodingKey {
        case publishers = "publishers"
        case identifiers = "identifiers"
        case weight = "weight"
        case title = "title"
        case url = "url"
        case numberOfPages = "number_of_pages"
        case cover = "cover"
        case subjectPlaces = "subject_places"
        case subjects = "subjects"
        case subjectPeople = "subject_people"
        case key = "key"
        case authors = "authors"
        case publishDate = "publish_date"
        case ebooks = "ebooks"
    }
}

// MARK: - Author
struct Author: Codable {
    let url: String?
    let name: String

    enum CodingKeys: String, CodingKey {
        case url = "url"
        case name = "name"
    }
}

// MARK: - Cover
struct Cover: Codable {
    let small: URL?
    let large: URL?
    let medium: URL?

    enum CodingKeys: String, CodingKey {
        case small = "small"
        case large = "large"
        case medium = "medium"
    }
}

// MARK: - Ebook
struct Ebook: Codable {
    let formats: Formats?
    let previewURL: String?
    let availability: String?

    enum CodingKeys: String, CodingKey {
        case formats = "formats"
        case previewURL = "preview_url"
        case availability = "availability"
    }
}

// MARK: - Formats
struct Formats: Codable {
}

// MARK: - Identifiers
struct Identifiers: Codable {
    let isbn13: [String]?
    let openlibrary: [String]?
    let isbn10: [String]?
    let librarything: [String]?
    let goodreads: [String]?

    enum CodingKeys: String, CodingKey {
        case isbn13 = "isbn_13"
        case openlibrary = "openlibrary"
        case isbn10 = "isbn_10"
        case librarything = "librarything"
        case goodreads = "goodreads"
    }
}

// MARK: - Publisher
struct Publisher: Codable {
    let name: String?

    enum CodingKeys: String, CodingKey {
        case name = "name"
    }
}
