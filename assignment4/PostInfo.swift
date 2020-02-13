//
//  PostInfo.swift
//  assignment4
//
//  Created by Macbook Air on 11/16/19.
//  Copyright © 2019 Macbook Air. All rights reserved.
//

import Foundation
import UIKit

struct PostInfo {
    var id: Int? = nil
    var username: String? = nil
    var ratingCount: Int? = nil
    var ratingAverage: Double? = nil
    var picture: Int? = nil
    var image:UIImage? = UIImage(named: "no_image_available.jpeg")
    var imageEncoding:String? = ""
    var description: String? = nil
    var comments: Array<String> = []
    var hashtags: Array<String> = []
    
}
