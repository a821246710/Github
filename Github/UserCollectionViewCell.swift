//
//  UserCollectionViewCell.swift
//  Github
//
//  Created by Joey on 2020/7/21.
//  Copyright © 2020 Joey. All rights reserved.
//

import UIKit
import Kingfisher

class UserCollectionViewCell: UICollectionViewCell {
    private let avatarImgView = UIImageView()
    private let nameLbl = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .lightGray
        
        avatarImgView.layer.cornerRadius = 50
        avatarImgView.layer.borderWidth = 2
        avatarImgView.layer.borderColor = UIColor.darkGray.cgColor
        avatarImgView.clipsToBounds = true
        
        nameLbl.textColor = .black
        nameLbl.textAlignment = .center
        nameLbl.font = .boldSystemFont(ofSize: 15)
        nameLbl.numberOfLines = 0
        
        avatarImgView.translatesAutoresizingMaskIntoConstraints = false
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImgView)
        contentView.addSubview(nameLbl)
        
        avatarImgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        avatarImgView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        avatarImgView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        avatarImgView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        nameLbl.topAnchor.constraint(equalTo: avatarImgView.bottomAnchor, constant: 20).isActive = true
        nameLbl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
        nameLbl.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        nameLbl.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(avatarURL: URL?, name: String?) {
        nameLbl.text = name
        avatarImgView.kf.setImage(with: avatarURL)
    }
}
