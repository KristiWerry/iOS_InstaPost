//
//  HashtagsTableViewController.swift
//  assignment4
//
//  Created by Macbook Air on 11/15/19.
//  Copyright © 2019 Macbook Air. All rights reserved.
//

import UIKit
import Alamofire
import Network

class HashtagsTableViewController: UITableViewController {
    @IBOutlet var tableV: UITableView!
    
    var hashtagsList:Array<String> = [] //list of hashtags to show in the table view
    let monitor = NWPathMonitor() //used the check internet connection
    //The dictionary from the json file
    private var hashtagsDictionary:Dictionary<String, Any> = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check if connected to the internet
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                //download the information using internet
                self.downloadJson()
            } else {
                //check if the users.json file exists so it can be read
                self.checkFileExists()
            }
        }
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
        
    }
    
    //write the json file with the new data from the database
    //use the hashtag as the keys and provide an empty array of strings
    //as the value which will home the post ids with that hashtag
    func writeFile() {
        var dictionary: [String: Any] = [:]
        
        for user in hashtagsList {
            let emptyArray: Array<String> = []
            dictionary[user] = emptyArray
        }
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("hashtags.json")
            try JSONSerialization.data(withJSONObject: dictionary).write(to: fileUrl)
            
        } catch {
            print(error)
        }
    }
    
    //check if hashtags.json file we created, aka if the user has downloading information
    //from the last time connected to internet
    func checkFileExists() {
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("hashtags.json")
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
    
    //read the data in from hashtags.json
    func readFile() {
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("hashtags.json")
            let data = try Data(contentsOf: fileUrl)
            let dictionary = try JSONSerialization.jsonObject(with: data)
            hashtagsDictionary = dictionary as! Dictionary<String, Any>
            //the list of hashtags are the keys in the dictionary from the json file
            hashtagsList = Array(hashtagsDictionary.keys)
        } catch {
            print(error)
        }
        //let the main thread reload the data in the table
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    //downloads the list of hashtags from the database using internet
    func downloadJson() {
        Alamofire.request("https://bismarck.sdsu.edu/api/instapost-query/hashtags")
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    //set the list of hashtags to the reponse from the database
                    self.hashtagsList = jsonArray["hashtags"] as! Array<String>
                    //write the list of hashtags to the hashtags.json file to be read with
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
        return hashtagsList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HashtagCell", for: indexPath)

        //sets the text of a cell to a hashtag name in the list
        cell.textLabel!.text = hashtagsList[indexPath.row]

        return cell
    }
    
    //when a cell is selected, nagivate to the home table view to show the list of
    //list of posts
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = (storyboard?.instantiateViewController(identifier: "HomeTableViewController") as? HomeTableViewController)!
        //pass the name of the hashtag to the next view
        post.subject = "hashtag"
        post.usernameHashtagName = hashtagsList[indexPath.row]
        self.navigationController?.pushViewController(post, animated: true)
    }
    
}
