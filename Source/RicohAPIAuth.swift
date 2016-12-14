//
//  Copyright (c) 2016 Ricoh Company, Ltd. All Rights Reserved.
//  See LICENSE for more information
//

import Foundation

public struct AuthResult {
    public var accessToken: String? = nil
}

public struct AuthError {
    public let statusCode: Int?
    public let message: String?
    
    public func isEmpty() -> Bool {
        return (statusCode == nil) && (message == nil)
    }
}

open class AuthClient {
    let clientId: String?
    let clientSecret: String?
    var userId = ""
    var userPass = ""
    var accessToken: String? = nil
    var refreshToken: String? = nil
    var expire: Date? = nil
    let expireMargin: Double = -10
    
    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    open func setResourceOwnerCreds(userId: String, userPass: String) {
        self.userId = userId
        self.userPass = userPass
    }
    
    open func session(_ completionHandler: @escaping (AuthResult, AuthError) -> Void) {
        token(){(data, resp, err) in
            if let err = err {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: nil, message: "request failed: \(err.localizedDescription)"))
                return
            }
            
            let httpresp = resp as! HTTPURLResponse
            let statusCode = httpresp.statusCode
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as! String
            
            if !httpresp.isSucceeded() {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "received error: \(dataString)"))
                return
            }
            
            do {
                let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                guard let dictionary = dataDictionary as? [String: Any], let authToken = dictionary["access_token"] as? String else {
                    completionHandler(
                        AuthResult(accessToken: nil),
                        AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
                    return
                }
                self.discovery(authToken: authToken, completionHandler: completionHandler)
            } catch {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
            }
        }
    }
    
    open func getAccessToken(_ completionHandler: @escaping (AuthResult, AuthError) -> Void) -> Void {
        if accessToken == nil {
            completionHandler(
                AuthResult(accessToken: nil),
                AuthError(statusCode: nil, message: "wrong usage: use the session method to get an access token."))
            return
        }
        
        if Date().compare(expire!.addingTimeInterval(expireMargin)) == ComparisonResult.orderedAscending {
            completionHandler(
                AuthResult(accessToken: accessToken!),
                AuthError(statusCode: nil, message: nil))
            return
        }
        
        refresh(completionHandler)
    }
    
    func token(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> Void {
        RicohAPIAuthRequest.post(
            url: "https://auth.beta2.ucs.ricoh.com/auth/token",
            header: [
                "content-type" : "application/x-www-form-urlencoded"
            ],
            params: [
                "client_id" : clientId!,
                "client_secret" : clientSecret!,
                "username" : userId,
                "password" : userPass,
                "scope" : "https://ucs.ricoh.com/scope/api/auth https://ucs.ricoh.com/scope/api/discovery https://ucs.ricoh.com/scope/api/udc2",
                "grant_type" : "password"
            ],
            completionHandler: completionHandler
        )
    }
    
    func discovery(authToken: String, completionHandler: @escaping (AuthResult, AuthError) -> Void) -> Void {
        RicohAPIAuthRequest.post(
            url: "https://auth.beta2.ucs.ricoh.com/auth/discovery",
            header: [
                "content-type" : "application/x-www-form-urlencoded",
                "Authorization" : "Bearer \(authToken)"
            ],
            params: [
                "scope" : "https://ucs.ricoh.com/scope/api/udc2"
            ]
        ){(data, resp, err) in
            if let err = err {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: nil, message: "request failed: \(err.localizedDescription)"))
                return
            }
            
            let httpresp = resp as! HTTPURLResponse
            let statusCode = httpresp.statusCode
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as! String
            
            if !httpresp.isSucceeded() {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "received error: \(dataString)"))
                return
            }
            
            do {
                let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                guard let dictionary = dataDictionary as? [String: Any],
                    let udc2Dictionary = dictionary["https://ucs.ricoh.com/scope/api/udc2"] as? [String: Any],
                    let accessToken = udc2Dictionary["access_token"] as? String else {
                    completionHandler(
                        AuthResult(accessToken: nil),
                        AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
                    return
                }
                self.accessToken = accessToken
                self.expire = Date().addingTimeInterval(Double(udc2Dictionary["expires_in"] as! Int))
                self.refreshToken = (udc2Dictionary["refresh_token"] as! String)
                completionHandler(
                    AuthResult(accessToken: accessToken),
                    AuthError(statusCode: nil, message: nil))
            } catch {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
            }
        }
    }
    
    func refresh(_ completionHandler: @escaping (AuthResult, AuthError) -> Void) -> Void {
        RicohAPIAuthRequest.post(
            url: "https://auth.beta2.ucs.ricoh.com/auth/token",
            header: [
                "content-type" : "application/x-www-form-urlencoded"
            ],
            params: [
                "client_id" : clientId!,
                "client_secret" : clientSecret!,
                "refresh_token" : refreshToken!,
                "grant_type" : "refresh_token"
            ]
        ){(data, resp, err) in
            if let err = err {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: nil, message: "request failed: \(err.localizedDescription)"))
                return
            }
            
            let httpresp = resp as! HTTPURLResponse
            let statusCode = httpresp.statusCode
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as! String
            
            if !httpresp.isSucceeded() {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "received error: \(dataString)"))
                return
            }
            
            do {
                let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                guard let dictionary = dataDictionary as? [String: Any],
                    let accessToken = dictionary["access_token"] as? String,
                    let expiresIn = dictionary["expires_in"] as? Int,
                    let refreshToken = dictionary["refresh_token"] as? String else {
                    completionHandler(
                        AuthResult(accessToken: nil),
                        AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
                    return
                }
                self.accessToken = accessToken
                self.expire = Date().addingTimeInterval(Double(expiresIn))
                self.refreshToken = refreshToken
                completionHandler(
                    AuthResult(accessToken: accessToken),
                    AuthError(statusCode: nil, message: nil))
            } catch {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
            }
        }
    }
}
