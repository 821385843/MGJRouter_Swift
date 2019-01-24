//
//  MGJRouter.swift
//  MGJRouter_Swift
//
//  Created by 老渔翁 on 2019/1/17.
//  Copyright © 2019 老渔翁. All rights reserved.
//

import UIKit

public class MGJRouter: NSObject {
    
    static let shared = MGJRouter()
    
    /**
     *  保存了所有已注册的 URL
     *  结构类似 ["beauty": [":id": ["_", 闭包]]]
     
     */
    lazy var routes = NSMutableDictionary()
    
    /// 注册 URLPattern 对应的 Handler，在 handler 中可以初始化 VC，然后对 VC 做各种操作
    ///
    /// - Parameters:
    ///   - URLPattern: 带上 scheme，如 mgj://beauty/:id
    ///   - handler: 该 闭包 会传一个字典，包含了注册的 URL 中对应的变量。假如注册的 URL 为 mgj://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
    public class func registerWithHandler(_ urlPattern: String, _ toHandler: MGJRouterHandler?) {
        shared.add(urlPattern, toHandler)
    }
    
    /// 注册 URLPattern 对应的 ObjectHandler，需要返回一个 object 给调用方
    ///
    /// - Parameters:
    ///   - urlPattern: 带上 scheme，如 mgj://beauty/:id
    ///   - toObjectHandler: 该 block 会传一个字典，包含了注册的 URL 中对应的变量。
    ///                      假如注册的 URL 为 mgj://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
    ///                      自带的 key 为 @"url" 和 @"completion" (如果有的话)
    public class func registerWithObjectHandler(_ urlPattern: String, toObjectHandler: MGJRouterObjectHandler?) {
        shared.add(urlPattern, toObjectHandler)
    }
    
    /// 取消注册某个 URL Pattern
    ///
    /// - Parameter urlPattern: URLPattern
    public class func deregister(_ urlPattern: String) {
        shared.remove(urlPattern)
    }
    
    /// 打开此 URL
    /// 会在已注册的 URL -> Handler 中寻找，如果找到，则执行 Handler
    ///
    /// - Parameter url: 带 Scheme，如 mgj://beauty/3
    public class func open(_ url: String) {
        open(url, nil)
    }
    
    /// 打开此 URL，同时当操作完成时，执行额外的代码
    ///
    /// - Parameters:
    ///   - _url: 带 Scheme 的 URL，如 mgj://beauty/4
    ///   - completion: URL 处理完成后的 callback，完成的判定跟具体的业务相关
    public class func open(_ url: String, _ completion: ((_ result: Any?)->())?) {
        open(url, nil, completion)
    }
    
    /// 打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
    ///
    /// - Parameters:
    ///   - _url: 带 Scheme 的 URL，如 mgj://beauty/4
    ///   - userInfo: 附加参数
    ///   - completion: URL 处理完成后的 callback，完成的判定跟具体的业务相关
    public class func open(_ url: String, _ userInfo: [String: Any]?,_ completion: ((_ result: Any?)->())?) {
        guard let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let parameters = shared.extractParameters(urlString, false)
            else {
                return
        }
        
        print(parameters)
        for (key, value) in parameters {
            if Mirror(reflecting: value).subjectType is NSString.Type {
                parameters[key] = (value as! NSString).replacingPercentEscapes(using: String.Encoding.utf8.rawValue)
            }
        }
        
        if parameters.allKeys.count > 0 {
            if completion != nil {
                parameters[MGJRouterParameterCompletion] = completion
            }
            
            if userInfo != nil {
                parameters[MGJRouterParameterUserInfo] = userInfo
            }
            
            
            if parameters["block"] != nil {
                let handler = parameters["block"] as? MGJRouterHandler
                if handler != nil {
                    parameters.removeObject(forKey: "block")
                    handler?(parameters as? [String : Any])
                } else {
                    let objectHandler = parameters["block"] as? MGJRouterObjectHandler
                    parameters.removeObject(forKey: "block")
                    _ = objectHandler?(parameters as? [String : Any])
                }
            }
        }
    }
    
    /// 查找谁对某个 URL 感兴趣，如果有的话，返回一个值
    ///
    /// - Parameter url: 带 Scheme，如 mgj://beauty/3
    /// - Returns: 返回值
    public class func object(_ url: String) -> Any? {
        return object(url, nil)
    }
    
    /// 查找谁对某个 URL 感兴趣，如果有的话，返回一个值
    ///
    /// - Parameters:
    ///   - url: 带 Scheme，如 mgj://beauty/3
    ///   - userInfo: 附加参数
    /// - Returns: 返回值
    public class func object(_ url: String, _ userInfo: [String: Any]?) -> Any? {
        guard let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let parameters = shared.extractParameters(urlString, false)
            else {
                return nil
        }
        
        let handler = parameters["block"] as? MGJRouterObjectHandler
        if handler != nil {
            if userInfo != nil {
                parameters[MGJRouterParameterUserInfo] = userInfo
            }
            parameters.removeObject(forKey: "block")
            return handler?(parameters as? [String : Any])
        }
        
        return nil
    }
    
    /// 是否可以打开URL
    ///
    /// - Parameter url: 带 Scheme，如 mgj://beauty/3
    /// - Returns: 返回 Bool 值
    public class func canOpen(url: String) -> Bool {
        return (shared.extractParameters(url, false) != nil)
    }
    
    public class func canOpen(url: String, _ matchExactly: Bool) -> Bool {
        return (shared.extractParameters(url, true) != nil)
    }
    
    /// 调用此方法来拼接 urlpattern 和 parameters
    ///
    /// #define MGJ_ROUTE_BEAUTY @"beauty/:id"
    /// [MGJRouter generateURLWithPattern:MGJ_ROUTE_BEAUTY, @[@13]];
    ///
    /// - Parameters:
    ///   - pattern: url pattern 比如 @"beauty/:id"
    ///   - parameters: 一个数组，数量要跟 pattern 里的变量一致
    /// - Returns: 返回生成的URL String
    public class func generateURL(_ pattern: String, _ parameters: [String]) -> String? {
        var startIndexOfColon = 0
        
        var placeholders = [String]()
        
        for i in 0..<pattern.count {
            let character = "\((pattern as NSString).character(at: i))"
            if character == ":" {
                startIndexOfColon = i
            }
            
            if (specialCharacters.range(of: character) != nil && i > (startIndexOfColon + 1) && startIndexOfColon > 0) {
                let range = NSRange(location: startIndexOfColon, length: (i - startIndexOfColon))
                let placeholder = (pattern as NSString).substring(with: range)
                
                if !shared.checkIfContains(placeholder) {
                    placeholders.append(placeholder)
                    startIndexOfColon = 0
                }
            }
            
            if i == pattern.count - 1 && startIndexOfColon > 0 {
                let range = NSRange(location: startIndexOfColon, length: (i - startIndexOfColon + 1))
                let placeholder = (pattern as NSString).substring(with: range)
                
                if !shared.checkIfContains(placeholder) {
                    placeholders.append(placeholder)
                }
            }
        }
        
        var parsedResult = pattern
        for i in 0..<placeholders.count {
            let index = (parameters.count > i ? i : parameters.count - 1)
            parsedResult = parsedResult.replacingOccurrences(of: placeholders[i], with: parameters[index])
        }
        
        return parsedResult
    }
}

extension MGJRouter {
    func add(_ urlPattern: String, _ objectHandler: MGJRouterObjectHandler?) {
        let subRoutes = add(urlPattern)
        if objectHandler != nil {
            subRoutes?["_"] = objectHandler
        }
    }
    
    func add(_ urlPattern: String, _ handler: MGJRouterHandler?) {
        let subRoutes = add(urlPattern)
        if handler != nil {
            subRoutes?["_"] = handler
        }
    }
    
    func add(_ urlPattern: String) -> NSMutableDictionary? {
        guard let pathComponentsArr = pathComponents(urlPattern) else {
            return nil
        }
        
        var subRoutes = routes
        
        for component in pathComponentsArr {
            if subRoutes[component] == nil {
                subRoutes[component] = NSMutableDictionary()
            }
            
            if let subRoute = subRoutes[component] as? NSMutableDictionary {
                subRoutes = subRoute
            }
        }
        return subRoutes
    }
    
    func pathComponents(_ fromURL: String) -> [String]? {
        var url = fromURL as NSString
        var pathComponents = [String]()
        
        if url.range(of: "://").location != NSNotFound {
            let pathSegments = url.components(separatedBy: "://")
            // 如果 URL 包含协议，那么把协议作为第一个元素放进去
            pathComponents.append(pathSegments.first ?? "")
            
            // 如果只有协议，那么放一个占位符
            url = pathSegments.last as NSString? ?? ""
            if url.length == 0 {
                pathComponents.append(MGJ_ROUTER_WILDCARD_CHARACTER)
            }
        }
        
        let urlString = url as String
        guard let pathComponentsArr = URL(string: urlString)?.pathComponents else {
            return pathComponents
        }
        
        for pathComponent in pathComponentsArr {
            if pathComponent == "/" {
                continue
            }
            
            if (pathComponent as NSString).substring(to: 1) == "?" {
                break
            }
            pathComponents.append(pathComponent)
        }
        
        return pathComponents
    }
    
    func extractParameters(_ fromURL: String, _ matchExactly: Bool) -> NSMutableDictionary? {
        let parameters = NSMutableDictionary()
        
        parameters[MGJRouterParameterURL] = fromURL
        
        print(parameters)
        
        var subRoutes = routes
        guard let pathComponentsArr = pathComponents(fromURL) else {
            return nil
        }
        
        var found = false
        
        print(routes)
        for pathComponent in pathComponentsArr {
            // 对 key 进行排序，这样可以把 ~ 放到最后
            let subRoutesKeys = subRoutes.allKeys.sorted { (key1, key2) -> Bool in
                switch (key1 as! String).compare(key2 as! String).rawValue {
                case 1:
                    return true
                case 0,-1:
                    return false
                default:
                    return false
                }
            }
            
            for key in subRoutesKeys as! [String] {
                if key == pathComponent || key == MGJ_ROUTER_WILDCARD_CHARACTER {
                    found = true
                    subRoutes = subRoutes[key] as! NSMutableDictionary
                    break;
                } else if key.hasPrefix(":") {
                    found = true
                    subRoutes = subRoutes[key] as! NSMutableDictionary
                    var newKey = (key as NSString).substring(from: 1)
                    var newPathComponent = pathComponent
                    
                    // 再做一下特殊处理，比如 :id.html -> :id
                    if checkIfContains(key) {
                        let specialCharacterSet = CharacterSet.init(charactersIn: specialCharacters)
                        guard let initRange = key.rangeOfCharacter(from: specialCharacterSet) else {
                            return nil
                        }
                        let range = nsRange(initRange, key)
                        if range.location != NSNotFound {
                            // 把 pathComponent 后面的部分也去掉
                            newKey = (newKey as NSString).substring(to: range.location - 1)
                            let suffixToStrip = (key as NSString).substring(from: range.location)
                            newPathComponent = (newPathComponent as NSString).replacingOccurrences(of: suffixToStrip, with: "")
                        }
                    }
                    parameters[newKey] = newPathComponent
                    break
                } else if matchExactly {
                    found = false
                }
            }
            
            if !found && (subRoutes["_"] == nil) {
                return nil
            }
        }
        
        // Extract Params From Query.
        guard let queryItems = URLComponents.init(url: URL(string: fromURL)!, resolvingAgainstBaseURL: false)?.queryItems else {
            if (subRoutes["_"] != nil) {
                parameters["block"] = subRoutes["_"]
            }
            
            return parameters
        }
        
        for item in queryItems {
            parameters[item.name] = item.value
        }
        
        if (subRoutes["_"] != nil) {
            parameters["block"] = subRoutes["_"]
        }
        
        return parameters
    }
    
    func remove(_ urlPattern: String) {
        guard var pathComponentsArr = pathComponents(urlPattern) else {
            return
        }
        
        // 只删除该 pattern 的最后一级
        if pathComponentsArr.count >= 1 {
            // 假如 URLPattern 为 a/b/c, components 就是 @"a.b.c" 正好可以作为 KVC 的 key
            let components = pathComponentsArr.joined(separator: ".")
            guard var route = routes.value(forKeyPath: components) as? NSMutableDictionary else {
                return
            }
            
            if route.count >= 1 {
                let lastComponent = pathComponentsArr.last ?? ""
                pathComponentsArr.removeLast()
                
                // 有可能是根 key，这样就是 self.routes 了
                route = routes
                if pathComponentsArr.count > 0{
                    let componentsWithoutLast = pathComponentsArr.joined(separator: ".")
                    route = routes.value(forKeyPath: componentsWithoutLast) as! NSMutableDictionary
                }
                route.removeObject(forKey: lastComponent)
            }
        }
    }
    
    func checkIfContains(_ specialCharacter: String) -> Bool {
        let specialCharactersSet = CharacterSet.init(charactersIn: specialCharacters)
        
        guard let range = specialCharacter.rangeOfCharacter(from: specialCharactersSet) else {
            return false
        }
        return nsRange(range, specialCharacter).location != NSNotFound
    }
    
    func nsRange(_ fromRange: Range<String.Index>, _ specialCharacter: String) -> NSRange {
        return NSRange(fromRange, in: specialCharacter)
    }
}
