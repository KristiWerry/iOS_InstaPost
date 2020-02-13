//
//  LogInViewController.swift
//  assignment4
//
//  Created by Macbook Air on 11/15/19.
//  Copyright © 2019 Macbook Air. All rights reserved.
//

import UIKit
import Alamofire
import Network

class LogInViewController: UIViewController, UITextFieldDelegate {
    var isConnected: Bool = false //internet connections
    let monitor = NWPathMonitor() //used to check internet connection
    let defaults = UserDefaults.standard //used to save login info to system preferences
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //check if connected to internet
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.isConnected = true
            } else {
                self.isConnected = false
            }
        }
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
    }
    
    func hideKeyboard() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    //ui delegate methods
    //Making the return button on the keyboard be able to hide the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideKeyboard()
        return true
    }
    
    @IBAction func loginButton(_ sender: Any) {
        hideKeyboard()
        //get the text from the input fields
        let email:String = emailTextField.text ?? ""
        let password:String = passwordTextField.text ?? ""
        if (password.count < 3) {
            //show error if the password is less then 3 characters long
            createAlert(title: "Oh No!", message: "Password is too short")
        }
        
        if(isConnected) {
            //replace the @ symbol for the url
            let emailAuth = email.replacingOccurrences(of: "@", with: "%40")
            //log in using the database
        Alamofire.request("https://bismarck.sdsu.edu/api/instapost-query/authenticate?email="+emailAuth+"&password="+password).validate().responseJSON { response in
                switch response.result {
                case .success:
                    if let utf8Text = response.result.value as? NSDictionary{
                        if (utf8Text["result"] as? Bool == true) {
                            //save the successful sign in to system preferences
                            self.defaults.set(email, forKey: "email")
                            self.defaults.set(password, forKey: "password")
                            //if the login was successful, navigate to  the application
                            self.navigateToHomePage()
                        }
                        else {
                            self.createAlert(title: "Oh No!", message: "Cannot Login")
                        }
                    }
                case .failure(let error):
                    self.defaults.set("", forKey: "email")
                    self.defaults.set("", forKey: "password")
                    print(error)
                }
            }
        }
        else { //if we don't have internet connection
            //let the user sign in if the login was the most recent successful login
            //by comparing the input to the values in system preferences
            let previousEmail = defaults.string(forKey: "email") ?? ""
            let previousPassword = defaults.string(forKey: "password") ?? ""
            //if the login was successful, navigate to  the application
            if (previousEmail == email && previousPassword == password) {
                self.navigateToHomePage()
            }
            else {
                //if not successful, alert the user
                createAlert(title: "Oh No!", message: "Cannot Login. Connect to Internet.")
            }
            
        }
    }
    
    //log into the main page of the application if the sign up was successful
    func navigateToHomePage() {
        let post = (storyboard?.instantiateViewController(identifier: "TabBarController") as? TabBarController)!
        self.navigationController?.pushViewController(post, animated: true)
    }
    
    //creates a popup alert with a given title and message
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel) 
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
