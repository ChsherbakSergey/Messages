//
//  ProfileModels.swift
//  Messages
//
//  Created by Sergey on 11/25/20.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let type: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
