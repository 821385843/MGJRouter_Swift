//
//  MGJMacro.swift
//  MGJRouter_Swift
//
//  Created by 老渔翁 on 2019/1/14.
//  Copyright © 2019 老渔翁. All rights reserved.
//

public let MGJRouterParameterURL = "MGJRouterParameterURL"
public let MGJRouterParameterCompletion = "MGJRouterParameterCompletion"
public let MGJRouterParameterUserInfo = "MGJRouterParameterUserInfo"

let MGJ_ROUTER_WILDCARD_CHARACTER = "~"
let specialCharacters = "/?&."

/**
 *  routerParameters 里内置的几个参数会用到上面定义的 string
 */
public typealias MGJRouterHandler = (_ routerParameters: [String: Any]?) -> Void

/**
 *  需要返回一个 object，配合 objectForURL: 使用
 */
public typealias MGJRouterObjectHandler = (_ routerParameters: [String: Any]?) -> Any?
