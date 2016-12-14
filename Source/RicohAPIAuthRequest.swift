//
//  Copyright (c) 2016 Ricoh Company, Ltd. All Rights Reserved.
//  See LICENSE for more information
//

import Foundation

class RicohAPIAuthRequest {
    static func get(url: String, queryParams: Dictionary<String, String>, header: Dictionary<String, String>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var requestUrl = url
        if queryParams.count > 0 {
            requestUrl += "?" + joinParameters(params: queryParams)
        }
        sendRequest(
            url: requestUrl,
            method: "GET",
            header: header,
            params: [String: String](),
            completionHandler: completionHandler
        )
    }
    
    static func post(url: String, header: Dictionary<String, String>, params: Dictionary<String, String>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        sendRequest(
            url: url,
            method: "POST",
            header: header,
            params: params,
            completionHandler: completionHandler
        )
    }
    
    static func upload(url: String, header: Dictionary<String, String>, data: Data, completionHandler: @escaping (Data?, URLResponse?, NSError?) -> Void) {
        sendRequestToUpload(
            url: url,
            method: "POST",
            header: header,
            data: data,
            completionHandler: completionHandler
        )
    }
    
    static func download(url: String, header: Dictionary<String, String>, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) {
        sendRequestToDownload(
            url: url,
            method: "GET",
            header: header,
            completionHandler: completionHandler
        )
    }
    
    static func delete(url: String, header: Dictionary<String, String>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        sendRequest(
            url: url,
            method: "DELETE",
            header: header,
            params: [String: String](),
            completionHandler: completionHandler
        )
    }
    
    static func sendRequest(url: String, method: String, header: Dictionary<String, String>, params: Dictionary<String, String>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = generateRequest(url: url, method: method, header: header, params: params)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    static func sendRequestToUpload(url: String, method: String, header: Dictionary<String, String>, data: Data, completionHandler: @escaping (Data?, URLResponse?, NSError?) -> Void) {
        let request = generateRequest(url: url, method: method, header: header, params: [String: String]())
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.uploadTask(with: request as URLRequest, from: data, completionHandler: completionHandler as! (Data?, URLResponse?, Error?) -> Void)
        task.resume()
    }
    
    static func sendRequestToDownload(url: String, method: String, header: Dictionary<String, String>, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) {
        let request = generateRequest(url: url, method: method, header: header, params: [String: String]())
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.downloadTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    static func generateRequest(url: String, method: String, header: Dictionary<String, String>, params: Dictionary<String, String>) -> URLRequest {
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = joinParameters(params: params).data(using: String.Encoding.utf8)
        return request
    }
    
    static func joinParameters(params: Dictionary<String, String>) -> String {
        return params.map({(key, value) in
            return "\(key)=\(value)"
        }).joined(separator: "&")
    }
}
