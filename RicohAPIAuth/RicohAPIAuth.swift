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

public class AuthClient {
    let clientId: String?
    let clientSecret: String?
    var userId = ""
    var userPass = ""
    var accessToken: String? = nil
    var refreshToken: String? = nil
    var expire: NSDate? = nil
    
    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    public func setResourceOwnerCreds(userId userId: String, userPass: String) {
        self.userId = userId
        self.userPass = userPass
    }
    
    public func session(completionHandler: (AuthResult, AuthError) -> Void) {
        token(){(data, resp, err) in
            if err != nil {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: nil, message: "request failed: \(err!.code): \(err!.domain)"))
                return
            }
            
            let httpresp = resp as! NSHTTPURLResponse
            let statusCode = httpresp.statusCode
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
            
            if !httpresp.isSucceeded() {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "received error: \(dataString)"))
                return
            }
            
            do {
                let dataDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                let authToken = dataDictionary["access_token"]!
                if authToken != nil {
                    self.discovery(authToken: authToken as! String, completionHandler: completionHandler)
                } else {
                    completionHandler(
                        AuthResult(accessToken: nil),
                        AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
                }
            } catch {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
            }
        }
    }
    
    public func getAccessToken(completionHandler: (AuthResult, AuthError) -> Void) -> Void {
        if accessToken == nil {
            completionHandler(
                AuthResult(accessToken: nil),
                AuthError(statusCode: nil, message: "wrong usage: use the session method to get an access token."))
            return
        }
        
        if NSDate().compare(expire!) == NSComparisonResult.OrderedAscending {
            completionHandler(
                AuthResult(accessToken: accessToken!),
                AuthError(statusCode: nil, message: nil))
            return
        }
        
        refresh(completionHandler)
    }
    
    func token(completionHandler completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> Void {
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
    
    func discovery(authToken authToken: String, completionHandler: (AuthResult, AuthError) -> Void) -> Void {
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
            if err != nil {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: nil, message: "request failed: \(err!.code): \(err!.domain)"))
                return
            }
            
            let httpresp = resp as! NSHTTPURLResponse
            let statusCode = httpresp.statusCode
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
            
            if !httpresp.isSucceeded() {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "received error: \(dataString)"))
                return
            }
            
            do {
                let dataDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                let udc2Dictionary = dataDictionary["https://ucs.ricoh.com/scope/api/udc2"]!!
                let accessToken = udc2Dictionary["access_token"]!
                if accessToken != nil {
                    self.accessToken = (accessToken as! String)
                    self.expire = NSDate().dateByAddingTimeInterval(Double(udc2Dictionary["expires_in"] as! Int))
                    self.refreshToken = (udc2Dictionary["refresh_token"] as! String)
                    completionHandler(
                        AuthResult(accessToken: (accessToken as! String)),
                        AuthError(statusCode: nil, message: nil))
                } else {
                    completionHandler(
                        AuthResult(accessToken: nil),
                        AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
                }
            } catch {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
            }
        }
    }
    
    func refresh(completionHandler: (AuthResult, AuthError) -> Void) -> Void {
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
            if err != nil {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: nil, message: "request failed: \(err!.code): \(err!.domain)"))
                return
            }
            
            let httpresp = resp as! NSHTTPURLResponse
            let statusCode = httpresp.statusCode
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
            
            if !httpresp.isSucceeded() {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "received error: \(dataString)"))
                return
            }
            
            do {
                let dataDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                let accessToken = dataDictionary["access_token"]!
                if accessToken != nil {
                    self.accessToken = (accessToken as! String)
                    self.expire = NSDate().dateByAddingTimeInterval(Double(dataDictionary["expires_in"] as! Int))
                    self.refreshToken = (dataDictionary["refresh_token"] as! String)
                    completionHandler(
                        AuthResult(accessToken: (accessToken as! String)),
                        AuthError(statusCode: nil, message: nil))
                } else {
                    completionHandler(
                        AuthResult(accessToken: nil),
                        AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
                }
            } catch {
                completionHandler(
                    AuthResult(accessToken: nil),
                    AuthError(statusCode: statusCode, message: "invalid response: \(dataString)"))
            }
        }
    }
}
