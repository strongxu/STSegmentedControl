//
//  ViewController.swift
//  STSegmentedControlExample
//
//  Created by Strong on 15/12/24.
//  Copyright © 2015年 Strong. All rights reserved.
//

import UIKit

let DEBUG_IMAGE = false

class ViewController: UITableViewController, STSegmentedControlDelegate {

    var control: STSegmentedControl!
    var menuItems: [AnyObject]!
    
    override func loadView() {
        super.loadView()
        
        self.title = NSStringFromClass(STSegmentedControl.self)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addSegment:")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshSegments:")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if DEBUG_IMAGE {
            menuItems = [UIImage(named: "icn_clock")!, UIImage(named: "icn_emoji")!, UIImage(named: "icn_gift")!]
        }
        else {
            menuItems = ["Tweets", "Following", "Followers"];
        }
        self.tableView.tableHeaderView = self.getControl()
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.clipsToBounds = true
        
        updateControlCounts()
    }
    
    func getControl() -> STSegmentedControl {
        if (control == nil) {
            control = STSegmentedControl(items: menuItems)
            control.delegate = self
            control.selectedSegmentIndex = 1
            control.bouncySelectionIndicator = false
            control.height = 60.0
            
            control.addTarget(self, action: "didChangeSegment:", forControlEvents: .ValueChanged);
        }
        return control;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell!.textLabel?.textColor = UIColor.darkGrayColor()
        }
        
        if DEBUG_IMAGE {
            cell!.textLabel?.text = String(format: "Cell #%d", indexPath.row + 1)
        }
        else {
            cell!.textLabel?.text = String(format:"%@ #%d", (control.titleForSegmentAtIndex(control.selectedSegmentIndex)?.capitalizedString)!,  indexPath.row + 1)
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    func addSegment(sender: AnyObject) {
        let newSegment = control.numberOfSegments
        
        if DEBUG_IMAGE {
            control.setImage(UIImage(named: "icn_clock")!, forSegmentAtIndex: newSegment)
        }
        else {
            control.setTitle("Favorites", forSegmentAtIndex: newSegment)
            control.setCount(Int(arc4random()%10000), forSegmentAtIndex: newSegment)
        }
    }
    
    func refreshSegments(sender: AnyObject) {
        let array = NSMutableArray(array: menuItems)
        let count = array.count
        for index in 0...count - 1 {
            let nElements = UInt32(count - index)
            let n = Int(arc4random() % nElements) + index
            array.exchangeObjectAtIndex(index, withObjectAtIndex: n)
        }
        
        menuItems = array as [AnyObject]
        control.items = menuItems
        self.updateControlCounts()
    }
    
    func updateControlCounts() {
        control.setCount(Int(arc4random()%10000), forSegmentAtIndex: 0)
        control.setCount(Int(arc4random()%10000), forSegmentAtIndex: 1)
        control.setCount(Int(arc4random()%10000), forSegmentAtIndex: 2)
    }
    
    func didChangeSegment(control: STSegmentedControl) {
        self.tableView.reloadData()
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .Bottom
    }
}

