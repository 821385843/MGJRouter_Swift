//
//  DemoListViewController.swift
//  MGJRouter_Swift
//
//  Created by 老渔翁 on 2019/1/17.
//  Copyright © 2019 老渔翁. All rights reserved.
//

import UIKit

fileprivate let reusIdentifier = "cell"

class DemoListViewController: UIViewController {
    
    static let shared = DemoListViewController()
    
    var titleWithHandlers: [String: Any]?
    var titles: [String]?
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reusIdentifier)
        
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Thread.sleep(forTimeInterval: 5)

        view.backgroundColor = UIColor.white
        title = "MGJRouter_Swift"
        
        view.addSubview(tableView)
    }
}

extension DemoListViewController {
    
    class func register(_ title: String, _ handler: (() -> UIViewController?)?) {
        if shared.titleWithHandlers == nil {
            shared.titleWithHandlers = [String: Any]()
            shared.titles = [String]()
        }
        
        shared.titles?.append(title)
        shared.titleWithHandlers?[title] = handler
    }
    
}

extension DemoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let titleWithHandlersArr = DemoListViewController.shared.titleWithHandlers else {
            return 0
        }
        return titleWithHandlersArr.keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusIdentifier)
        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.text = DemoListViewController.shared.titles?[indexPath.row]
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let titleWithHandlersArr = DemoListViewController.shared.titleWithHandlers,
              let titlesArr = DemoListViewController.shared.titles
        else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        let handler = titleWithHandlersArr[titlesArr[indexPath.row]] as? (() -> UIViewController?)
        
        guard let viewController = handler?() else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
    
}
