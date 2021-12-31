//
//  MGJRouterModel.swift
//  MGJRouter_Swift
//
//  Created by xiewei on 2021/12/29.
//  Copyright © 2021 谢伟. All rights reserved.
//

import Foundation

public class MGJRouterModel: NSObject {
    
    var pathComponent: String?
    var handler: MGJRouterHandler?
    var objectHandler: MGJRouterObjectHandler?
    
    var subRouterModels: [MGJRouterModel]?
}

