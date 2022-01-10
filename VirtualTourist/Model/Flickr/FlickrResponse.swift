//
//  FlickrResponse.swift
//  VirtualTourist
//
//  Created by 嶋田省吾 on 2022/01/07.
//

import Foundation

struct PhotoList: Codable {
    let photos: Photos
    let stat: String
}

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [photo]
}

struct photo: Codable {
    let id : String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
