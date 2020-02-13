//
//  SignUpViewController.swift
//  assignment4
//
//  Created by Macbook Air on 11/15/19.
//  Copyright © 2019 Macbook Air. All rights reserved.
//

import UIKit
import Alamofire
import Network

class SignUpViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    let monitor = NWPathMonitor() //used to check internet connection
    let defaults = UserDefaults.standard //used to save login info to system preferences
    var email:String = ""
    var password:String = ""
    var isConnected:Bool = false //internet connection
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        nicknameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        //check internet connection
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
    
    override func viewDidAppear(_ animated: Bool) {
        //we cannot sign up a person without internet
        if(!isConnected) {
            createAlert(title: "Oh No!", message: "Please connect to Internet before signing up.")
        }
    }
        
    func hideKeyboard() {
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        nicknameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    
    //ui delegate methods
    //Making the return button on the keyboard be able to hide the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideKeyboard()
        return true
    }
    
    //when the user pushes the sign up button, first check if there is internet
    //then get the parameters from the text fields
    @IBAction func signupButton(_ sender: Any) {
        hideKeyboard()
        
        if(!isConnected) {
            createAlert(title: "Oh No!", message: "Please connect to Internet before signing up.")
        }
        else {
            let firstName:String = firstNameTextField.text ?? ""
            let lastName:String = lastNameTextField.text ?? ""
            let username:String = nicknameTextField.text ?? ""
            email = emailTextField.text ?? ""
            password = passwordTextField.text ?? ""
            if (password.count < 3) {
                //error
                createAlert(title: "Oh No!", message: "Password is too short")
            }
        
            let parameters = ["firstname": firstName, "lastname": lastName, "nickname": username, "email": email, "password": password]
            //check the database if the provided username has already been taken
            checkNickName(nickname: username, parameters: parameters)
        
        }
    }
    
    //check if the nickname exists
    //if so, notify the user to pick a different username/nickname
    func checkNickName(nickname:String, parameters:Dictionary<String,Any>) {
        Alamofire.request("https://bismarck.sdsu.edu/api/instapost-query/nickname-exists?nickname="+nickname).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let utf8Text = response.result.value as? NSDictionary{
                    if (utf8Text["result"] as? Bool == true) {
                        //error
                        //Sign up fail with provided username since it already exists
                        self.createAlert(title: "Oh No!", message: "Nickname already exists")
                    }
                    else {
                        //if the username doesn't exist already, add the new user
                        self.addNewUser(parameters: parameters)
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
        
    }
    
    //Add the user to the database with the provided parameters
    func addNewUser(parameters:Dictionary<String, Any>) {
        Alamofire.request("https://bismarck.sdsu.edu/api/instapost-upload/newuser", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
            switch response.result {
            case .success:
                let jsonArray = response.result.value as! NSDictionary
                if(jsonArray["errors"] as! String == "none" && jsonArray["result"] as! String == "success") {
                    //save the email and password to system preferences to be used later
                    //when posting, commenting, or rating within the application
                    self.defaults.set(self.email, forKey: "email")
                    self.defaults.set(self.password, forKey: "password")
                    //if the sign up was successful, log into the application
                    self.navigateToHomePage()
                }
                else {
                    self.createAlert(title: "Oh No!", message: jsonArray["errors"] as! String)
                }
            case .failure(let error):
                print(error)
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
