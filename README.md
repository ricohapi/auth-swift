# Ricoh Auth Client for Swift

This open-source library allows you to integrate Ricoh API's [Authorization and Discovery Service](http://docs.ricohapi.com/docs/authorization-and-discovery-service/) into your Swift app.

Learn more at http://docs.ricohapi.com/

## Requirements

* Swift 2.2+
* Xcode 7.3.1+

You'll also need

* Ricoh API Client Credentials (client_id & client_secret)
* Ricoh ID (user_id & password)

If you don't have them, please register yourself and your client from [THETA Developers Website](http://contest.theta360.com/).

## Installation
* Clone Ricoh Auth Client for Swift by running the following command:
```sh
$ git clone https://github.com/ricohapi/auth-swift.git
```

* Open the new `auth-swift` folder, and drag the `RicohAPIAuth.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon.
    > Whether it is above or below all the other Xcode groups does not matter.

* Choose RicohAPIAuth scheme at the scheme menu of Xcode and run it.

## Sample Flow

```swift
// Import
import RicohAPIAuth

// Set your Ricoh API Client Credentials
var authClient = AuthClient(
    clientId: "<your_client_id>",
    clientSecret: "<your_client_secret>"
)

// Set your Ricoh ID
authClient.setResourceOwnerCreds(
    userId: "<your_user_id>",
    userPass: "<your_password>"
)

// Open a new session
authClient.session(){result, error in
if !error.isEmpty() {
    print("status code: \(error.statusCode)")
    print("error message: \(error.message)")
} else {
    print("access token : \(result.accessToken)")
}
```

## SDK API Samples

### Constructor
```swift
var authClient = AuthClient(
    clientId: "<your_client_id>",
    clientSecret: "<your_client_secret>"
)
```

### Set resource owner credentials
```swift
authClient.setResourceOwnerCreds(
    userId: "<your_user_id>",
    userPass: "<your_password>"
)
```

### Open a new session
```swift
authClient.session(){result, error in
if error.isEmpty() {
    print("access token : \(result.accessToken)")
    // do something
}
```

### Resume a preceding session
```swift
// This method resumes a preceding session if it is closed.
authClient.getAccessToken(){result, error in
if error.isEmpty() {
    print("access token : \(result.accessToken)")
    // do something
}
```