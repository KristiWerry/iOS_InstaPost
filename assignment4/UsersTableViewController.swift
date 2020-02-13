//
//  UsersTableViewController.swift
//  assignment4
//
//  Created by Macbook Air on 11/15/19.
//  Copyright © 2019 Macbook Air. All rights reserved.
//

import UIKit
import Alamofire
import Network

class UsersTableViewController: UITableViewController {
    private var usersList:Array<String> = [] //list of users to show in the table view
    let monitor = NWPathMonitor() //used the check internet connection
    //The dictionary from the json file
    private var usersDictionary:Dictionary<String, Any> = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check if connected to the internet
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.downloadJson() //download the information using internet
            } else {
                self.checkFileExists() //check if the users.json file exists so it can be read
            }
        }
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)

    }
    
    //write the json file with the new data from the database
    //use the username as the keys and provide an empty array of strings
    //as the value which will home the post ids from that user
    func writeFile() {
        var dictionary: [String: Any] = [:]
        
        for user in usersList {
            let emptyArray: Array<String> = []
            dictionary[user] = emptyArray
        }
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("users.json")
            try JSONSerialization.data(withJSONObject: dictionary).write(to: fileUrl)
            
        } catch {
            print(error)
        }
    }
    
    //check if users.json file we created, aka if the user has downloading information
    //from the last time connected to internet
    func checkFileExists() {
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("users.json")
            let filepath = fileUrl.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filepath) {
                //if the file exists, read the file in to present the data
                readFile()
            }
            else {
                //file doesn't exists. Don't show any data
            }
        } catch (let errors) {
            print(errors)
        }
    }
       
    //read the data in from users.json.
    func readFile() {
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("users.json")
            let data = try Data(contentsOf: fileUrl)
            let dictionary = try JSONSerialization.jsonObject(with: data)
            usersDictionary = dictionary as! Dictionary<String, Any>
            //the list of users are the keys in the dictionary from the json file
            usersList = Array(usersDictionary.keys)
        } catch {
            print(error)
        }
        //Let the main thread reload the data in the table
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    //downloads the list of users from the database using internet
    func downloadJson() {
        Alamofire.request("https://bismarck.sdsu.edu/api/instapost-query/nicknames")
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    //set the list of users to the reponse from the database
                    self.usersList = jsonArray["nicknames"] as! Array<String>
                    //write the list of users to the users.json file to be read with
                    //no internet
                    self.writeFile()
                    //show the data in the table
                    self.tableView.reloadData()
                case .failure(let error):
                    print(error)
                }

        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersCell", for: indexPath)

        //sets the text of a cell to a user name in the list
        cell.textLabel!.text = usersList[indexPath.row]

        return cell
    }
    
    //when a cell is selected, nagivate to the home table view to show the list of
    //list of posts
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = (storyboard?.instantiateViewController(identifier: "HomeTableViewController") as? HomeTableViewController)!
        //pass the name of the user to the next view
        post.subject = "user"
        post.usernameHashtagName = usersList[indexPath.row]
        self.navigationController?.pushViewController(post, animated: true)
    }
    

}
