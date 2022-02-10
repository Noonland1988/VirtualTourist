//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by 嶋田省吾 on 2022/01/03.
//

import Foundation
import CoreLocation
import UIKit

class FlickrClient{
    
    class func requestPhotosURL(coordinate: CLLocationCoordinate2D, page: Int) -> URL {
        let base = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
        let apiKey = "950730e7af5bd0aa79ed64c59522f784"
        let accuracy = 11
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        let page = page
        
        let requestAddress = base + "&api_key=\(apiKey)" + "&accuracy=\(accuracy)" + "&lat=\(latitude)" + "&lon=\(longitude)" + "&per_page=10" + "&page=\(page)" + "&format=json&nojsoncallback=1"
        return URL(string: requestAddress)!
    }
    
    
    
    //MARK: HTTPRequestHandlers
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) ->Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    print("no data")
                    completion(nil,error)
                }
                return
          }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    print("found responseObject")
                    completion(responseObject, nil)
                }
            } catch { //handling error if needed... not implemented at the moment
                DispatchQueue.main.async {
                    print("handling error")
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func getPhotoImageURL(serverId: String, id: String, secret: String, sizeSuffix: String) -> String {
        let imageAddress = "https://live.staticflickr.com" + "/\(serverId)" + "/\(id)_\(secret)_\(sizeSuffix).jpg"
        return imageAddress
//        let imageURL = URL(string: imageAddress)
//        print(imageAddress)
//        do {
//            let data = try Data(contentsOf: imageURL!)
//            completion(UIImage(data: data), nil)
//        } catch {
//            print(error)
//            completion(nil, error)
//        }
    }
    
    
}
