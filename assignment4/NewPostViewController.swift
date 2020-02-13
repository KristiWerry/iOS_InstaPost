//
//  NewPostViewController.swift
//  assignment4
//
//  Created by Macbook Air on 11/15/19.
//  Copyright © 2019 Macbook Air. All rights reserved.
//

import UIKit
import Alamofire

class NewPostViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var hashtagTextField: UITextField!
    @IBOutlet weak var hashtagTableView: UITableView!
    
    var hashtags:Array<String> = []
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //to be able to hide the keyboard on return
        descriptionTextField.delegate = self
        hashtagTextField.delegate = self
    }
    
    //when button is clicked, let the user go into the device's photo library
    @IBAction func addImageButton(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    //get the image the user selected
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.editedImage] as? UIImage else {
            //no image found
            return
        }
        //show the image selected in the view
        imagePreview.image = image
    }
    
    //adds a hashtag (but first parses the input)
    @IBAction func hashtagButton(_ sender: Any) {
        hideKeyboard()
        if(hashtagTextField.text == nil) {
            hashtagTextField.text = ""
            return
        }
        else if(hashtagTextField.text!.count < 2) {
            createAlert(title: "Oh No!", message: "Hashtag is too short")
            hashtagTextField.text = ""
            return
        }
        else {
            var inputText = hashtagTextField.text!
            if(inputText.contains(" ") || inputText.contains(",")) {
                createAlert(title: "Oh No!", message: "Input one hashtag at a time please.")
                hashtagTextField.text = ""
                return
            }
            else if (inputText.hasPrefix("#")) {
                hashtags.append(inputText)
                hashtagTableView.reloadData()
            }
            else {
                inputText = "#" + inputText
                //add the hashtag to the list of hashtags
                hashtags.append(inputText)
                //upload the table with the new value
                hashtagTableView.reloadData()
            }
        }
        //clear the text field
        hashtagTextField.text = ""
    }
    
    //upload the input data as a post to the database
    @IBAction func postButton(_ sender: Any) {
        if(descriptionTextField.text!.count > 144) {
            createAlert(title: "Oh No!", message: "Description has too many characters.")
            return
        }
        else {
            //get user credentials
            let defaults = UserDefaults.standard
            let email = defaults.string(forKey: "email")
            let password = defaults.string(forKey: "password")
            let description = descriptionTextField.text ?? ""
            //set up the parameters to be sent to the database
            let parameters = ["email": email!, "password": password!, "text": description, "hashtags": hashtags] as [String : Any]
            //upload the post
            Alamofire.request("https://bismarck.sdsu.edu/api/instapost-upload/post", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    if(jsonArray["errors"] as! String == "none" && jsonArray["result"] as! String == "success") {
                        //rating has been uploaded
                        //upload the possible image with the post id passed back
                        self.uploadImage(id: jsonArray["id"] as! Int)
                    }
                    else {
                        self.createAlert(title: "Oh No!", message: jsonArray["errors"] as! String)
                    }
                case .failure(let error):
                    print(error)
                }
            }
            
        }
        
    }
    
    func uploadImage(id:Int) {
        if(imagePreview.image == nil) {
            //no image choice
            //don't upload if there is no image
        }
        else {
            //get user credentials
            let defaults = UserDefaults.standard
            let email = defaults.string(forKey: "email")
            let password = defaults.string(forKey: "password")
            //encode the image into a base 64 string
            let imageData = imagePreview.image!.pngData()?.base64EncodedString()
            //set up the parameters to be sent to the database
            let parameters = ["email": email!, "password": password!, "image": imageData!, "post-id": id] as [String : Any]
            //upload the image to the database
            Alamofire.request("https://bismarck.sdsu.edu/api/instapost-upload/image", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    if(jsonArray["errors"] as! String == "none" && jsonArray["result"] as! String == "success") {
                        //image has been uploaded
                    }
                    else {
                        self.createAlert(title: "Oh No!", message: jsonArray["errors"] as! String)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        
    }
    
    func hideKeyboard() {
        descriptionTextField.resignFirstResponder()
        hashtagTextField.resignFirstResponder()
    }
    
    //ui delegate
    //Making the return button on the keyboard be able to hide the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideKeyboard()
        return true
    }

    //creates a popup alert with a given title and message
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel) { (action) in
            //do something
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    //table view code
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HashtagTableCell", for: indexPath)
        //sets the text of a cell to a hashtag in the list
        cell.textLabel!.text = hashtags[indexPath.row]
        
        return cell
    }

}
