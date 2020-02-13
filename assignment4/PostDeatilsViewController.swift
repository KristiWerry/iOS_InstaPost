//
//  PostDeatilsViewController.swift
//  assignment4
//
//  Created by Macbook Air on 11/17/19.
//  Copyright © 2019 Macbook Air. All rights reserved.
//

import UIKit
import Alamofire

class PostDeatilsViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionView: UILabel!
    @IBOutlet weak var commentTextBox: UITextField!
    @IBOutlet weak var ratingsNumView: UILabel!
    @IBOutlet weak var ratingsAverageView: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var sliderValueText: UILabel!
    @IBOutlet weak var commentsTableView: UITableView!
    
    var postImage:UIImage = UIImage()
    var postDescription: String = ""
    var ratingAverage: Double = 0
    var ratingCount:Int = 0
    var comments:Array<String> = []
    var postId: Int = 0
    var alreadyRate:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //update the view with the data passed in
        imageView.image = postImage
        descriptionView.text = postDescription
        ratingsAverageView.text = "Rating: " + String(Double(round(ratingAverage*10)/10))
        ratingsNumView.text = String(ratingCount) + " Reviews"
        
        //to have the return button hide the keyboard
        commentTextBox.delegate = self
        
        //listen for keyboard events to move the view to show the text box
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        //stop listening for keyboard events
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    //have the text field show the value of the slider
    @IBAction func sliderMoved(_ sender: Any) {
        sliderValueText.text = String(Int(floor(slider.value)))
    }
    
    //upload the comment into the database
    @IBAction func commentButton(_ sender: Any) {
        hideKeyboard()
        
        if(commentTextBox.text == nil) {
            createAlert(title: "Oh No!", message: "Enter a comment.")
        }
        else {
            //get the login credentials
            let defaults = UserDefaults.standard
            let email = defaults.string(forKey: "email")
            let password = defaults.string(forKey: "password")
        
            let comment = commentTextBox.text
            //set up the parameters to send to the database
            let parameters = ["email": email!, "password": password!, "comment": comment!, "post-id":postId] as [String : Any]
            //upload comment
            Alamofire.request("https://bismarck.sdsu.edu/api/instapost-upload/comment", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    if(jsonArray["errors"] as! String == "none" && jsonArray["result"] as! String == "success") {
                        //comment has been uploaded
                    }
                    else {
                        self.createAlert(title: "Oh No!", message: jsonArray["errors"] as! String)
                    }
                case .failure(let error):
                    print(error)
                }
            }
            //add the new comment to the list of comments
            //and reload the table to avoid another download
            comments.append(comment!)
            commentsTableView.reloadData()
            
        }
    }
    //upload a rating to the database
    @IBAction func rateButton(_ sender: Any) {
        if (alreadyRate == false) {
            //get the login credentials
            let defaults = UserDefaults.standard
            let email = defaults.string(forKey: "email")
            let password = defaults.string(forKey: "password")
        
            let rating:Int = Int(sliderValueText.text!) ?? 0
            //set up the parameters to send to the database
            let parameters = ["email": email!, "password": password!, "rating": rating, "post-id":postId] as [String : Any]
            //upload rating
            Alamofire.request("https://bismarck.sdsu.edu/api/instapost-upload/rating", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    if(jsonArray["errors"] as! String == "none" && jsonArray["result"] as! String == "success") {
                        //rate uploaded
                        self.alreadyRate = true
                    }
                    else {
                        self.createAlert(title: "Oh No!", message: jsonArray["errors"] as! String)
                    }
                case .failure(let error):
                    print(error)
                }
            }
            //update ratings on this page so don't have to download the data again
            let newAverage = (ratingAverage * Double(ratingCount)) + Double(rating)
            ratingAverage = newAverage / (Double(ratingCount) + 1)
            ratingsAverageView.text = "Rating: " + String(Double(round(ratingAverage*10)/10))
            ratingCount+=1
            ratingsNumView.text = String(ratingCount) + " Reviews"
            alreadyRate = true
        }
        else {
            createAlert(title: "Oh No!", message: "You have already rated this post")
        }
        
    }
    
    func hideKeyboard() {
        commentTextBox.resignFirstResponder()
    }
    
    //pushes the view up to be able to see the text field while typing
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        if(notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification) {
            view.frame.origin.y = -keyboardRect.height
        } else {
            view.frame.origin.y = 0
        }
        
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
    
    //to show the list of comments
    //table view code
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableCell", for: indexPath)
        //sets the text of a cell to a comment in the list
        cell.textLabel!.text = comments[indexPath.row]
        
        return cell
    }
    
}
