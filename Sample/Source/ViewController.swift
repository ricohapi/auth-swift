//
//  Copyright (c) 2016 Ricoh Company, Ltd. All Rights Reserved.
//  See LICENSE for more information
//

import UIKit

import RicohAPIAuth

class ViewController: UIViewController {

    var authClient = AuthClient(
        clientId: "### enter your client ID ###",
        clientSecret: "### enter your client secret ###"
    )
    
    @IBAction func tapHandler(_ sender: AnyObject) {
        authClient.setResourceOwnerCreds(
            userId: "### enter your user id ###",
            userPass: "### enter your user password ###"
        )
        
        DispatchQueue.global().async(execute: {
            self.authClient.session(){result, error in
                if error.isEmpty() {
                    print("access token : \(result.accessToken)")
                    DispatchQueue.main.async {
                        self.resultTextField.text = "connect!"
                    }
                } else {
                    print("status code: \(error.statusCode)")
                    print("error message: \(error.message)")
                    DispatchQueue.main.async {
                        self.resultTextField.text = "ERROR: \(error)"
                    }
                }
            }
        })
    }
    
    @IBOutlet weak var resultTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

