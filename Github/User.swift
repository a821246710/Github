//
//  User.swift
//  Github
//
//  Created by Joey on 2020/7/21.
//  Copyright © 2020 Joey. All rights reserved.
//

import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let avatarURLString: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "login"
        case avatarURLString = "avatar_url"
        
        case id
    }
}
