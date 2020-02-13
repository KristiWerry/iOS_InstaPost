//
//  HomeTableViewController.swift
//  assignment4
//
//  Created by Macbook Air on 11/15/19.
//  Copyright © 2019 Macbook Air. All rights reserved.
//

import UIKit
import Alamofire
import Network

class HomeTableViewController: UITableViewController {
    var postsList: Array<PostInfo> = [] //list of posts to show in the table view
    var postIds: Array<Int> = [] //list of post ids to show
    var subject: String = "" //either "" , hashtag, or user //indicates which posts to show
    var fullUrl:String = "" //the complete url for download from the database
    var usernameHashtagName:String = "" //the username or the hashtag name to show
    
    let monitor = NWPathMonitor() //used to check the internet connection
    var allPostDic: Dictionary<String, Any> = [:] //the dictionary of posts from a json file
    var userHashtagList: Dictionary<String,Any> = [:] //list of users or hashtags from a json file
    var downloadingMorePosts: Bool = true //a flag to download more posts
    var numberPostsToDownload: Int = 50 //the number of posts to download at a time

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Posts"
        
        //Get the correct url based on the subject to show
        if (subject == "hashtag") {
            let urlEnding = usernameHashtagName.replacingOccurrences(of: "#", with: "%23")
            fullUrl = "hashtags-post-ids?hashtag="+urlEnding
        }
        else if (subject == "user") {
            fullUrl = "nickname-post-ids?nickname="+usernameHashtagName
        }
        else {
            fullUrl = "post-ids" //get all posts
        }
        
        //check if internet connection
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.getPostsIds() //download the post ids using internet
            }
            else {
                //Not connected to internet
                if (self.subject != ""){
                    //read the user or hashtag json file based on the provided subject
                    self.readUserHashtagJson()
                    //After getting the post ids, read the file with all of the
                    //posts to find the ones in the list to show
                    var readDictionary = self.readPosts()
                    if(self.subject == "hashtag") { //get a subset of posts based on the hashtag
                        readDictionary = self.getUserHashtagIdsJson(dictionary: readDictionary)
                    }
                    else if (self.subject == "user") { //get a subset of posts based on user
                        readDictionary = self.getUserHashtagIdsJson(dictionary: readDictionary)
                    }
                    self.createPostInfoFromJson(dictionary: readDictionary)
                }
                else {
                    //show all posts if we have no subject
                    let readDictionary = self.readPosts()
                    //show every post
                    self.createPostInfoFromJson(dictionary: readDictionary)
                }
            }
        }
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
    }
    
    
    func readPosts() -> Dictionary<String,Any> {
        //reads the posts file and get a dictionary of post ids and the contents
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("posts.json")
            let data = try Data(contentsOf: fileUrl)
            let dictionary = try JSONSerialization.jsonObject(with: data)
            return dictionary as! Dictionary<String, Any>
            
        } catch {
            print(error)
        }
        return [:]
    }
    
    //compares the ids from the user or hashtag json and get the post
    //info from the posts json
    func getUserHashtagIdsJson(dictionary:Dictionary<String,Any>)->Dictionary<String,Any> {
        //the subset dictionary to pass back
        //the list of posts to show
        var userHashtagPosts: Dictionary<String,Any> = [:]
        //get the array of posts ids from the user or hashtags name
        let list = userHashtagList[usernameHashtagName] as! Array<Int>
        //find all the subset posts in the dictionary(that has every post's data)
        //copy over the post's data to the list of posts to show.
        //aka: use the list of post ids to get in post's data from the dictionary.
        for id in list {
            if(dictionary.keys.contains(String(id))) {
                userHashtagPosts[String(id)] = dictionary[String(id)]
            }
        }
        return userHashtagPosts
    }
    
    //get the data from the posts json file and convert them into
    //PostInfo to be shown in the table view
    func createPostInfoFromJson(dictionary:Dictionary<String,Any>) {
        //create an array of ids
        //for every id, create a postInfo with the given information
        let ids = Array(dictionary.keys)
        
        //create an empty post and fill it with the data given by the dictionary
        var post:PostInfo = PostInfo()
        for id in ids {
            let contents = dictionary[id] as! Dictionary<String,Any>
            post.id = Int(id)
            post.ratingCount = contents["ratings-count"] as? Int ?? 0
            post.ratingAverage = contents["ratings-average"] as? Double ?? 0.0
            post.description = contents["text"] as? String
            post.comments = contents["comments"] as? Array<String> ?? []
            post.hashtags = contents["hashtags"] as? Array<String> ?? []
            post.imageEncoding = contents["image"] as? String ?? ""
            if post.imageEncoding! == "" {
                post.image = UIImage(named: "no_image_available.jpeg")
            }
            else if let decodedImage = Data(base64Encoded: post.imageEncoding!) {
                let image = UIImage(data: decodedImage)
                post.image = image
            }
            //add the post to the list of posts to be displayed
            postsList.append(post)
        }
        //let the main thread reload the data to be show on the ui thread
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    func readUserHashtagJson() {
        //reads in from the user or hashtag file to get the list of posts for
        //each user or hashtag
        if (subject == "user") {
            do {
                let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("users.json")
                let data = try Data(contentsOf: fileUrl)
                let dictionary = try JSONSerialization.jsonObject(with: data)
                userHashtagList = dictionary as! Dictionary<String, Any>
            } catch {
                print(error)
            }
        }
        else if (subject == "hashtag") {
            do {
                let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("hashtags.json")
                let data = try Data(contentsOf: fileUrl)
                let dictionary = try JSONSerialization.jsonObject(with: data)
                userHashtagList = dictionary as! Dictionary<String, Any>
            } catch {
                print(error)
            }
        }
        //else show all posts / this function is not called
    }
    
    //only called when we downloaded a list of user or hashtag posts
    func updateUserHashtagJson() {
        //read in user or hashtag json in order to update the list of post ids
        readUserHashtagJson()
        //update list with in list of posts
        if userHashtagList.keys.contains(usernameHashtagName) {
            userHashtagList[usernameHashtagName] = postIds
        }
        //write to the appropriate file
        var jsonFile = ""
        if(subject == "user") {
            jsonFile = "users.json"
        }
        else if(subject == "hashtag") {
            jsonFile = "hashtags.json"
        }
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(jsonFile)
            try JSONSerialization.data(withJSONObject: userHashtagList).write(to: fileUrl)
            
        } catch {
            print(error)
        }
        
    }
    
    //download the list of post ids using internet
    func getPostsIds() {
        if(subject != "") { //either with a specific user or hashtag
            Alamofire.request("https://bismarck.sdsu.edu/api/instapost-query/" + fullUrl).validate(statusCode: 200..<300).responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    if(jsonArray["errors"] as! String == "none" && jsonArray["result"] as! String == "success") {
                        self.postIds = jsonArray["ids"] as! Array<Int>
                        //update the list of post ids for the specified user or hashtag
                        self.updateUserHashtagJson()
                        //download the specific post's data and possible image
                        for (index, id) in self.postIds.enumerated() {
                            if (index < self.numberPostsToDownload) {
                                self.downloadPostInfo(id: id)
                                self.downloadImages(id: id)
                            }
                        }
                        
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        else {
            //downloading all the posts ids
            Alamofire.request("https://bismarck.sdsu.edu/api/instapost-query/" + fullUrl).validate(statusCode: 200..<300).responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    self.postIds = jsonArray["result"] as! Array<Int>
                    //download the specific post's data and possible image
                    for (index, id) in self.postIds.enumerated() {
                        //only download a certain number of posts at first
                        if (index < self.numberPostsToDownload) {
                            self.downloadPostInfo(id: id)
                            self.downloadImages(id: id)
                        }
                    }
                case .failure(let error):
                    print(error)
                }
            }
            
        }
    }
    
    //download a post's information/contents given an id
    func downloadPostInfo(id:Int) {

        Alamofire.request("https://bismarck.sdsu.edu/api/instapost-query/post?post-id="+String(id))
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .success:
                    let jsonArray = response.result.value as! NSDictionary
                    //create a postInfo object to be shown
                    let post = self.createPostObj(dic: jsonArray)
                    //add the post to the list of posts shown in the table view
                    self.postsList.append(post)
                    //Not downloading anymore
                    self.downloadingMorePosts = false
                    //let the table view show the new data
                    self.tableView.reloadData()
                    //update the json list of post information
                    self.writePostFile()
                case .failure(let error):
                    print(error)
                }
        }
    }
    
    //download the possible image for a post using an id
    func downloadImages(id: Int) {
        Alamofire.request("https://bismarck.sdsu.edu/api/instapost-query/image?id=" + String(id)).validate(statusCode: 200..<300).responseJSON { response in
            switch response.result {
            case .success:
                let jsonArray = response.result.value as! NSDictionary
                if(jsonArray["errors"] as! String == "none" && jsonArray["result"] as! String == "success") {
                    let imageEncoding = jsonArray["image"] as! String
                    if let decodedImage = Data(base64Encoded: imageEncoding) {
                        let image = UIImage(data: decodedImage)
                        //update postInfo with image
                        for (index, post) in self.postsList.enumerated() {
                            if(post.id == id) {
                                self.postsList[index].imageEncoding = imageEncoding
                                self.postsList[index].image = image
                            }
                        }
                        //Not downloading anymore
                        self.downloadingMorePosts = false
                        //let the table view show the image
                        self.tableView.reloadData()
                        //update the json list of  post information with the image
                        self.writePostFile()
                    }
                }
            case .failure(let error):
                print(error)
            }
        
        }
    }
    
    //write/update the json with the posts info from the newly downloaded posts
    func writePostFile() {
        //get the current list of post to write
        var writePosts = postsList
        
        //if we are downloading posts of a user or hashtag,
        //download the currently saved posts to add the newly downloaded posts
        if(subject != "") {
            //Read and Parse through the data already stored
            let dictionary = readPosts()
            //create an array of ids
            //for every id, create a postInfo with the given information
            let ids = Array(dictionary.keys)
            //create an empty post and fill it with the data given by the dictionary
            var post:PostInfo = PostInfo()
            for id in ids {
                let contents = dictionary[id] as! Dictionary<String,Any>
                post.id = Int(id)
                post.ratingCount = contents["ratings-count"] as? Int ?? 0
                post.ratingAverage = contents["ratings-average"] as? Double ?? 0.0
                post.description = contents["text"] as? String
                post.comments = contents["comments"] as? Array<String> ?? []
                post.hashtags = contents["hashtags"] as? Array<String> ?? []
                post.imageEncoding = contents["image"] as? String ?? ""
                //dont need the information for the UI image
                //add the post to the list of posts to be displayed
                writePosts.append(post)
            }
        }
        
        //put the post data in a json format
        for post in writePosts {
            let contents:Dictionary<String, Any> = ["comments":post.comments,
                                                        "ratings-count": post.ratingCount ?? 0,
                                                    "ratings-average":post.ratingAverage ?? -1,
                                                        "hashtags":post.hashtags,
                                                        "text":post.description ?? "",
                                                        "image":post.imageEncoding ?? ""]
                                                        
            allPostDic[String(post.id ?? 0)] = contents
        }
        //write the list of post ids and the contents of the post to a json file
        //to be shown when no internet connection
        do {
            let fileUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("posts.json")
            try JSONSerialization.data(withJSONObject: allPostDic).write(to: fileUrl)
        } catch {
            print(error)
        }
    }
    
    //given a dictionary with a post id as a key and the value is the contents of the post
    //return a postInfo object that can be read and shown by the table view
    func createPostObj(dic:NSDictionary)->PostInfo {
        var post:PostInfo = PostInfo()
        if((dic["errors"] as! String) == "none" && dic["result"] as! String == "success") {
            let jsonPost:NSDictionary = dic["post"] as! NSDictionary
            post.id = jsonPost["id"] as? Int ?? 0
            post.username = usernameHashtagName
            post.ratingCount = jsonPost["ratings-count"] as? Int ?? 0
            post.ratingAverage = jsonPost["ratings-average"] as? Double ?? 0.0
            if(post.ratingAverage == -1.0) {
                post.ratingAverage = 0
            }
            post.picture = jsonPost["image"] as? Int ?? 0
            post.description = jsonPost["text"] as? String ?? ""
            post.comments = jsonPost["comments"] as? Array<String> ?? []
            post.hashtags = jsonPost["hashtags"] as? Array<String> ?? []
        }
        return post
    }
    
    //When the user reaches the bottom of the table view,
    //download more posts and load them to the view
    func downloadMorePosts() {
        for (index, id) in postIds.enumerated() {
            if ((index >= numberPostsToDownload) && (index < numberPostsToDownload + 25)) {
                self.downloadPostInfo(id: id)
                self.downloadImages(id: id)
            }
        }
        numberPostsToDownload += 25
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postsList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell else { return UITableViewCell() }
        

        //show the data stored in the postInfo object
        cell.postUsername.text = postsList[indexPath.row].username
        cell.postDescription.text = postsList[indexPath.row].description
        var postAverage:String = String(0)
        if(postsList[indexPath.row].ratingAverage != 0.0) {
            let average = postsList[indexPath.row].ratingAverage!
            postAverage = String(Double(round(average*10)/10))
        }
        cell.postRating.text = "Rating: " + postAverage
        cell.postImage.image = postsList[indexPath.row].image
        
        return cell
    }
    
    //nagivate to the detial view of a selected post
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = (storyboard?.instantiateViewController(identifier: "PostDeatilsViewController") as? PostDeatilsViewController)!
        post.postImage = postsList[indexPath.row].image ?? UIImage()
        post.postDescription = postsList[indexPath.row].description ?? ""
        post.ratingCount = postsList[indexPath.row].ratingCount ?? 0
        post.ratingAverage = postsList[indexPath.row].ratingAverage ?? 0
        post.comments = postsList[indexPath.row].comments
        post.postId = postsList[indexPath.row].id ?? 0
        self.navigationController?.pushViewController(post, animated: true)
    }
    
    //checks if the user has scrolled to the bottom of the table view controller
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentOffsetY = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentOffsetY
        if (distanceFromBottom < height && !downloadingMorePosts) {
            downloadingMorePosts = true
            downloadMorePosts()
        }
    }
    

}
