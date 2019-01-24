//
//  DemoDetailViewController.swift
//  MGJRouter_Swift
//
//  Created by 老渔翁 on 2019/1/17.
//  Copyright © 2019 老渔翁. All rights reserved.
//

import UIKit

class DemoDetailViewController: UIViewController {
    
    var resultTextView: UITextView = {
        let padding: CGFloat = 20.0
        let viewWith = UIScreen.main.bounds.width
        let viewHeight = UIScreen.main.bounds.height - 100
        let resultTextView = UITextView(frame: CGRect(x: padding, y: padding + 64, width: viewWith - padding * 2, height: viewHeight - padding * 2))
        resultTextView.layer.borderColor = UIColor.init(white: 0.8, alpha: 1).cgColor
        resultTextView.layer.borderWidth = 1
        resultTextView.isEditable = false
        resultTextView.contentInset = UIEdgeInsets(top: -64, left: 0, bottom: 0, right: 0)
        resultTextView.font = UIFont.systemFont(ofSize: 14)
        resultTextView.textColor = UIColor.init(white: 0.2, alpha: 1)
        resultTextView.contentOffset = CGPoint.zero
        
        return resultTextView
    }()
    
    var selectedSelector: Selector?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        view.addSubview(resultTextView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for obj in resultTextView.subviews {
            if obj.isKind(of: UIImageView.self) {
                obj.removeFromSuperview()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resultTextView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        perform(selectedSelector ?? #selector(test), with: nil, afterDelay: 0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        resultTextView.removeObserver(self, forKeyPath: "contentSize")
        resultTextView.text = ""
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let kPath = keyPath else {
            return
        }
        
        if kPath == "contentSize" {
            let contentHeight = resultTextView.contentSize.height
            let textViewHeight = resultTextView.frame.height
            resultTextView.setContentOffset(CGPoint(x: 0, y: CGFloat.maximum(contentHeight - textViewHeight, 0)), animated: true)
        }
    }
    
}

extension DemoDetailViewController {
    
    class func registerURL() {
        let detailViewController = DemoDetailViewController()
        DemoListViewController.register("基本使用") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoBasicUsage)
            return detailViewController
        }

        DemoListViewController.register("中文匹配") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoChineseCharacter)
            return detailViewController
        }

        DemoListViewController.register("自定义参数") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoParameters)
            return detailViewController
        }

        DemoListViewController.register("传入字典信息") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoUserInfo)
            return detailViewController
        }

        DemoListViewController.register("Fallback 到全局的 URL Pattern") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoFallback)
            return detailViewController
        }

        DemoListViewController.register("Open 结束后执行 Completion Block") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoCompletion)
            return detailViewController
        }

        DemoListViewController.register("基于 URL 模板生成 具体的 URL") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoGenerateURL)
            return detailViewController
        }

        DemoListViewController.register("取消注册 URL Pattern") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoDeregisterURLPattern)
            return detailViewController
        }

        DemoListViewController.register("同步获取 URL 对应的 Object") { () -> UIViewController? in
            detailViewController.selectedSelector = #selector(demoObjectForURL)
            return detailViewController
        }
    }
    
}

extension DemoDetailViewController {
    
    @objc func demoFallback() {
        MGJRouter.registerWithHandler("mgj://") { [weak self] (routerParameters) in
            self?.appendLog("匹配到了 url，以下是相关信息")
            self?.appendLog("routerParameters:\(routerParameters ?? [:])")
        }
        
        MGJRouter.registerWithHandler("mgj://foo/bar/none/exists") { [weak self] (routerParameters) in
            self?.appendLog("it should be triggered")
        }
        
        MGJRouter.open("mgj://foo/bar")
    }
    
    @objc func demoBasicUsage() {
        MGJRouter.registerWithHandler("mgj://foo/bar") { [weak self] (routerParameters) in
            self?.appendLog("匹配到了 url，以下是相关信息")
            self?.appendLog("routerParameters:\(routerParameters ?? [:])")
        }
        
        MGJRouter.open("mgj://foo/bar")
    }
    
    @objc func demoChineseCharacter() {
        MGJRouter.registerWithHandler("mgj://category/家居") { [weak self] (routerParameters) in
            self?.appendLog("匹配到了 url，以下是相关信息")
            self?.appendLog("routerParameters:\(routerParameters ?? [:])")
        }
        
        MGJRouter.open("mgj://category/家居")
    }
    
    @objc func demoUserInfo() {
        MGJRouter.registerWithHandler("mgj://category/travel") { [weak self] (routerParameters) in
            self?.appendLog("匹配到了 url，以下是相关信息")
            self?.appendLog("routerParameters:\(routerParameters ?? [:])")
        }
        
        MGJRouter.open("mgj://category/travel", ["user_id": "1900"], nil)
    }
    
    @objc func demoParameters() {
        MGJRouter.registerWithHandler("mgj://search/:query") { [weak self] (routerParameters) in
            self?.appendLog("匹配到了 url，以下是相关信息")
            self?.appendLog("routerParameters:\(routerParameters ?? [:])")
        }
        
        MGJRouter.open("mgj://search/bicycle?color=red")
    }
    
    @objc func demoCompletion() {
        MGJRouter.registerWithHandler("mgj://detail") { [weak self] (routerParameters) in
            self?.appendLog("匹配到了 url, 一会会执行 Completion 闭包")
            
            // 模拟 push 一个 VC
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                let completion = routerParameters?[MGJRouterParameterCompletion] as? ((Any?)->())
                completion?(nil)
            })
        }
        
        MGJRouter.open("mgj://detail", nil) { [weak self] (obj) in
            self?.appendLog("Open 结束，我是 Completion Block")
        }
    }
    
    @objc func demoGenerateURL() {
        let TEMPLATE_URL = "mgj://search/:keyword"
        MGJRouter.registerWithHandler(TEMPLATE_URL) { [weak self] (routerParameters) in
            self?.appendLog("routerParameters[keyword]:\(routerParameters?["keyword"] as? String ?? "")") // Hangzhou
        }
        
        MGJRouter.open(MGJRouter.generateURL(TEMPLATE_URL, ["Hangzhou"]) ?? "")
    }
    
    @objc func demoDeregisterURLPattern() {
        let TEMPLATE_URL = "mgj://search/:keyword"
        
        
        MGJRouter.registerWithHandler(TEMPLATE_URL) { [weak self] (routerParameters) in
            assert(false, "这里不会被触发")
            self?.appendLog("routerParameters[keyword]:\(routerParameters?["keyword"] as? String ?? "")") // Hangzhou
        }
        
        MGJRouter.deregister(TEMPLATE_URL)
        MGJRouter.open(MGJRouter.generateURL(TEMPLATE_URL, ["Hangzhou"]) ?? "")
        
        appendLog("如果没有运行到断点，就表示取消注册成功了")
    }
    
    @objc func demoObjectForURL() {
        MGJRouter.registerWithObjectHandler("mgj://search_top_bar") { (routerParameters) -> Any? in
            let searchTopBar = UIView()
            return searchTopBar
        }
        
        guard let searchTopBar = MGJRouter.object("mgj://search_top_bar")
            else {
            appendLog("同步获取 Object 失败")
            return
        }
        
        if Mirror.init(reflecting: searchTopBar).subjectType == UIView.self {
            appendLog("同步获取 Object 成功")
        } else {
            appendLog("同步获取 Object 失败")
        }
    }
    
    @objc func test() {
        print("selectedSelector 为 nil")
    }
}

extension DemoDetailViewController {
    
    func appendLog(_ log: String) {
        var currentLog = resultTextView.text ?? ""
        if currentLog.count > 0 {
            currentLog.append("\n----------\n\(log)")
        } else {
            currentLog = log
        }
        
        resultTextView.text = currentLog
        resultTextView.sizeThatFits(CGSize(width: view.frame.width, height: CGFloat.greatestFiniteMagnitude))
    }
}
