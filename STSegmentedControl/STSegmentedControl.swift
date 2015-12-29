//
//  STSegmentedControl.swift
//  Search500
//
//  Created by Strong on 15/11/26.
//  Copyright © 2015年 Strong. All rights reserved.
//

import UIKit

@objc public protocol STSegmentedControlDelegate: UIBarPositioningDelegate {
    
}

let STSegmentedControlNoSegment = -1

public class STSegmentedControl: UIControl, UIBarPositioning {

    public weak var delegate: STSegmentedControlDelegate? {
        didSet {
            barPosition = delegate!.positionForBar!(self)
        }
    }
    var _items: [AnyObject] = []
    public var items: [AnyObject] {
        set {
            if _items.count != 0 {
                self.removeAllSegments()
            }
            
            if newValue.count == 0 {
                _items.removeAll()
                return
            }
            
            _items = newValue
            if _items[0] is UIImage {
                isImageMode = true
            }
            
            for item in _items {
                if item is String {
                    continue
                }
                if item is UIImage {
                    continue
                }
                
                assert(true, "cannot include different objects in the array(UIImage or String)")
            }
            
            if !isImageMode {
                for _ in _items {
                    self.counts.append(0)
                }
            }
            
            insertAllSegments()
        }
        get {
            return _items
        }
    }
    
    public var selectedSegmentIndex = STSegmentedControlNoSegment
    public var numberOfSegments: Int {
        get {
            return items.count
        }
    }

    override public var frame: CGRect {
        didSet {
            _width = CGRectGetWidth(frame)
            _height = CGRectGetHeight(frame)

            super.frame = frame
            layoutIfNeeded()
        }
    }

    override public var tintColor: UIColor! {
        didSet {
            if self.items.count == 0 || self.initializing {
                return
            }
            super.tintColor = tintColor
            
            self.setTitleColor(tintColor, forState: .Highlighted)
            self.setTitleColor(tintColor, forState: .Selected)
        }
    }
    
    var _height: CGFloat = 0.0
    public var height: CGFloat {
        set {
            _height = newValue
            layoutSubviews()
        }
        get {
            if _height != 0 {
                return _height
            }
            if showsCount {
                return 56.0
            }
            return 30.0
        }
    }
    
    var _width: CGFloat = 0.0
    public var width: CGFloat {
        set {
            _width = newValue
            layoutSubviews()
        }
    
        get {
            if _width != 0 {
                return _width
            }
            if self.superview == nil {
                return 0
            }
            
            return (self.superview?.bounds.size.width)!
        }
    }

    public var selectionIndicatorHeight : CGFloat = 2.0
    public var animationDuration: Double = 0.2
    
    var _font: UIFont!
    public var font: UIFont {
        set {
            if _font.fontName == newValue.fontName && _font.pointSize == newValue.pointSize {
                return
            }
            _font = newValue
            configureSegments()
        }
        get {
            return _font
        }
    }
    
    public var hairlineColor: UIColor {
        set {
            if initializing {
                return
            }
            self.hairline.backgroundColor = newValue
        }
        get {
            return self.hairline.backgroundColor!
        }
    }
    public var numberFormatter: NSNumberFormatter! {
        didSet {
            configureSegments()
        }
    }
    
    public var _showsCount: Bool = false
    public var showsCount: Bool {
        set {
            _showsCount = newValue
        }
        get {
            if isImageMode {
                return true
            }
            
            return _showsCount
        }
    }
    
    public var _autoAdjustSelectionIndicatorWidth: Bool!
    public var autoAdjustSelectionIndicatorWidth: Bool {
        set {
            _autoAdjustSelectionIndicatorWidth = newValue
        }
        get {
            if isImageMode {
                return false
            }
            
            return _autoAdjustSelectionIndicatorWidth
        }
    }
    
    public var inverseTitles = false
    public var bouncySelectionIndicator = false
    
    public var _showsGroupingSeparators : Bool = false
    public var showsGroupingSeparators : Bool {
        set {
            if _showsGroupingSeparators == newValue {
                return
            }
            
            _showsGroupingSeparators = newValue
            configureSegments()
        }
        get {
            return _showsGroupingSeparators
        }
    }
    
    public var adjustsFontSizeToFitWidth = false
    public var adjustsButtonTopInset : Bool!
    
    public var disableSelectedSegment = true
    
    @objc public var barPosition = UIBarPosition.Any
    
    var initializing = false
    var selectionIndicator: UIView!
    var hairline: UIView!
    var colors: [String: UIColor] = [:]
    var counts: [Int] = []
    var scrollOffset = CGPointZero
    var isTransitioning = false
    var isImageMode = false
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public convenience init(items: [AnyObject]) {
        self.init(frame: CGRectZero)
        commonInit()
        self.items = items
    }
    
    func commonInit() {
        initializing = true
        
        _showsCount = true
        selectedSegmentIndex = -1
        selectionIndicatorHeight = 2.0
        animationDuration = 0.2
        _autoAdjustSelectionIndicatorWidth = false
        adjustsButtonTopInset = false
        disableSelectedSegment = false
        _font = UIFont.systemFontOfSize(15.0)
        
        selectionIndicator = UIView.init()
        selectionIndicator.backgroundColor = self.tintColor
        self.addSubview(selectionIndicator)
        
        hairline = UIView.init()
        hairline.backgroundColor = UIColor.lightGrayColor()
        self.addSubview(hairline)
        
        initializing = false
    }
    
    override public func sizeThatFits(size: CGSize) -> CGSize {
        var width:CGFloat = 0
        if self.width != 0 {
            width = self.width
        }
        else if self.superview == nil {
            width = 0
        }
        else {
            width = self.superview!.bounds.size.width
        }
        
        return CGSizeMake(width, self.height)
    }
   
    override public func sizeToFit() {
        var rect = self.frame
        rect.size = self.sizeThatFits(rect.size)
        self.frame = rect
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.sizeToFit()
        
        if self.buttons().count == 0 {
            selectedSegmentIndex = STSegmentedControlNoSegment
        }
        else if selectedSegmentIndex < 0 {
            selectedSegmentIndex = 0
        }
        
        for (index, button) in self.buttons().enumerate() {
            let width = self.bounds.size.width / CGFloat(numberOfSegments)
            let height = self.bounds.size.height
            let x = width * CGFloat(index)
            
            let rect = CGRectMake(x, 0.0, width, height)
            button.frame = rect
            
            if adjustsButtonTopInset == true {
                let topInset = (barPosition == UIBarPosition.Top || barPosition == UIBarPosition.TopAttached ) ? -4.0: 4.0
                button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, CGFloat(topInset), 0.0)
            }
            else {
                button.titleEdgeInsets = UIEdgeInsetsZero
            }
            
            if (index == selectedSegmentIndex) {
                button.selected = true
            }
        }
        
        self.configureAccessoryViews()
    }
    
    func buttons() -> [UIButton] {
        var buttons = [UIButton]()
        
        for view in self.subviews {
            if view is UIButton {
                buttons.append(view as! UIButton)
            }
        }
        
        return buttons
    }
    
    override public func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        if let _ = newSuperview {
            self.layoutIfNeeded()
        }
    }
    
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        
        if self.backgroundColor == nil {
            self.backgroundColor = UIColor.whiteColor()
        }
        
        self.configureSegments() 
        self.layoutIfNeeded()
    }
    
    override public func layoutIfNeeded() {
        if self.superview == nil {
            return
        }
        
        super.layoutIfNeeded()
    }
    
    override public func intrinsicContentSize() -> CGSize {
        return CGSizeMake(self.width, self.height)
    }
    
    func buttonAtIndex(segment: Int) -> UIButton? {
        if self.items.count > 0 && segment < self.buttons().count {
            return self.buttons()[segment]
        }
        
        return nil
    }
    
    func selectedButton() -> UIButton? {
        if selectedSegmentIndex >= 0 {
            return buttonAtIndex(selectedSegmentIndex)
        }
        
        return nil
    }
    
    func stringForSegmentAtIndex(segment: Int) -> String? {
        if isImageMode {
            return nil
        }
        
        let button = buttonAtIndex(segment)
        if let _button = button {
            return _button.attributedTitleForState(UIControlState.Normal)?.string
        }
        
        return nil
    }
    
    func titleForSegmentAtIndex(segment: Int) -> String? {
        if isImageMode {
            return nil
        }
        
        if showsCount {
            let title = stringForSegmentAtIndex(segment)
            if title == nil {
                return nil
            }
            else {
                let components = title!.componentsSeparatedByString("\n")
                if components.count == 2 {
                    return components[inverseTitles ? 0 : 1]
                }
                
                return nil
            }
        }
        if items[segment] is UIImage {
            return nil
        }
        
        return items[segment] as? String
    }
    
    func countForSegmentAtIndex(segment: Int) -> Int {
        if isImageMode {
            return 0
        }
        
        return segment < self.counts.count ? self.counts[segment] : 0
    }
    
    func titleColorForState(state: UIControlState) -> UIColor? {
        if isImageMode {
            return nil
        }
        
//        let key = String(format: "UIControlState%d", state.rawValue)
        let key = "UIControlState\(state.rawValue)"
        let color = colors[key]
        if color == nil {
            switch state {
            case UIControlState.Normal:        return UIColor.darkGrayColor()
            case UIControlState.Highlighted:    return self.tintColor
            case UIControlState.Disabled:       return UIColor.lightGrayColor()
            case UIControlState.Selected:       return self.tintColor
            default:                            return self.tintColor
            }
        }
        
        return color
    }
    
    func selectionIndicatorRect() -> CGRect {
        let button = self.selectedButton()
        if button == nil {
            return CGRectZero
        }
        
        let item = _items[button!.tag]
        if item is String {
            if (item as! NSString).length == 0 {
                return CGRectZero
            }
        }
        
        var frame = CGRectZero
        frame.origin.y = (barPosition.rawValue > UIBarPosition.Bottom.rawValue) ? 0.0 : (button!.frame.height - selectionIndicatorHeight)
        
        if autoAdjustSelectionIndicatorWidth {
            let attributedString = button!.attributedTitleForState(UIControlState.Selected)!
            var width = attributedString.size().width
            if width > button!.frame.width {
               width = button!.frame.width
            }
            
            frame.size = CGSizeMake(width, selectionIndicatorHeight)
            frame.origin.x = (button!.frame.width * CGFloat(selectedSegmentIndex)) + (button!.frame.width - frame.width) / 2.0
        }
        else {
            frame.size = CGSizeMake(button!.frame.width, selectionIndicatorHeight)
            frame.origin.x = button!.frame.width * CGFloat(selectedSegmentIndex)
        }
        
        return frame
    }
    
    func hairlineRect() -> CGRect {
        var frame = CGRectMake(0.0, 0.0, self.frame.width, 0.5)
        frame.origin.y = (barPosition.rawValue > UIBarPosition.Bottom.rawValue) ? 0.0 : self.frame.height
        return frame
    }
    
    func appropriateFontSizeForTitle(title: String) -> CGFloat {
        var fontSize: CGFloat = 14.0
        let minFontSize: CGFloat = 8.0
        
        if adjustsFontSizeToFitWidth == false {
            return fontSize
        }
        
        let buttonWidth = round(self.bounds.width / CGFloat(self.numberOfSegments))
        let constraintSize = CGSizeMake(buttonWidth, CGFloat(MAXFLOAT))
        
        repeat {
            let font = UIFont(name: _font.fontName, size: fontSize)
            let strTitle = title as NSString
            let textRect = strTitle.boundingRectWithSize(constraintSize, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font!], context: nil)
            
            if textRect.width <= constraintSize.width {
                return fontSize
            }
            
            fontSize -= CGFloat(1.0)
        } while (fontSize > minFontSize)
        
        return fontSize
    }
    
    func setScrollOffset(scrollOffset: CGPoint, contentSize: CGSize) {
        autoAdjustSelectionIndicatorWidth = false
        bouncySelectionIndicator = false
        
        var offset:CGFloat = 0.0
        
        if self.scrollOffset.x != scrollOffset.x {
            offset = scrollOffset.x / (contentSize.width / CGFloat(numberOfSegments))
        }
        else if self.scrollOffset.y != scrollOffset.y {
            offset = scrollOffset.y / (contentSize.height / CGFloat(numberOfSegments))
        }
        
        let buttonWidth = round(self.width / CGFloat(numberOfSegments))
        
        var indicatorRect = selectionIndicator.frame
        indicatorRect.origin.x = buttonWidth * offset
        selectionIndicator.frame = indicatorRect
        
        let index = Int(offset)
        if offset == trunc(offset) && selectedSegmentIndex != index {
            self.unselectAllButtons()
            let button = self.buttonAtIndex(index)
            button?.selected = true
            
            selectedSegmentIndex = index
            
            self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
        }
        
        self.scrollOffset = scrollOffset
        
    }
    
    func setSelectedSegmentIndex(segment: Int, animated: Bool) {
        if selectedSegmentIndex == segment || self.isTransitioning {
            return
        }
        
        self.unselectAllButtons()
        
        self.userInteractionEnabled = false
        
        selectedSegmentIndex = segment
        isTransitioning = true
        
        func animations() -> () {
            self.selectionIndicator.frame = self.selectionIndicatorRect()
        }
        
        func completion(finished: Bool) -> () {
            self.userInteractionEnabled = true
            isTransitioning = false
        }
        
        if animated {
            let duration = self.selectedSegmentIndex < 0 ? 0.0 : self.animationDuration
            let damping: CGFloat = !self.bouncySelectionIndicator ? 0.0: 0.65
            let velocity: CGFloat = !self.bouncySelectionIndicator ? 0.0 : 0.5
            
            UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options:[.BeginFromCurrentState, .CurveEaseInOut], animations: animations, completion: completion)
        }
        else {
            animations()
            completion(false)
        }
    }
    
    func setTintColor(tintColor: UIColor, forSegmentAtIndex segment: Int) {
        assert(segment < self.numberOfSegments, "cannot asign a tint color to non-existing segment")
        assert(segment >= 0, "cannot assign a tint color to a negative segment")
        
        let button = self.buttonAtIndex(segment)
        button?.backgroundColor = tintColor
    }
    
    func setTitle(title: String, forSegmentAtIndex segment: Int) {
        if isImageMode {
            return
        }
        
        assert(segment <= self.numberOfSegments, "cannot assign a title to non-existing segment")
        assert(segment >= 0, "cannot assign a title to a negative segment")
        
        var items:[AnyObject] = self.items
//        let items = NSMutableArray(array: self.items)
        if segment >= self.numberOfSegments {
//            items[self.numberOfSegments] = title
            items.insert(title, atIndex: self.numberOfSegments)
            self.addButtonForSegment(segment)
        }
        else {
            items[segment] = title
            self.setCount(self.countForSegmentAtIndex(segment), forSegmentAtIndex: segment)
        }
        
        _items = items as [AnyObject]
    }
    
    func setCount(count: Int, forSegmentAtIndex segment: Int) {
        if self.items.count == 0 || isImageMode {
            return
        }
        
        assert(segment < self.numberOfSegments, "cannot assign a count to non-existing segment")
        assert(segment >= 0, "cannot assign a title to a negative segment")
        
//        self.counts[segment] = count
        self.counts.insert(count, atIndex: segment)
        
        self.configureSegments()
    }
    
    func setImage(image: UIImage, forSegmentAtIndex segment: Int) {
        if !isImageMode {
            return
        }
        
        assert(segment <= self.numberOfSegments, "cannot assign a count to non-existing segment")
        assert(segment >= 0, "cannot assign a title to a negative segment")
        
        var items:[AnyObject] = self.items
//        let items = NSMutableArray(array: self.items)
        if segment >= self.numberOfSegments {
//            items[self.numberOfSegments] = image
            items.insert(image, atIndex: self.numberOfSegments)
            self.addButtonForSegment(segment)
        }
        else {
            items[segment] = image
        }
        
        self.configureButtonImage(image, forSegment: segment)
        
        _items = items as [AnyObject]
    }
    
    func setAttributedTitle(attributedString: NSAttributedString, forSegmentAtIndex segment: Int) {
        let button = self.buttonAtIndex(segment)
        button?.titleLabel?.numberOfLines = self.showsCount ? 2 : 1
        
        if let rButton = button {
            rButton.setAttributedTitle(attributedString, forState: .Normal)
            rButton.setAttributedTitle(attributedString, forState: .Highlighted)
            rButton.setAttributedTitle(attributedString, forState: .Selected)
            rButton.setAttributedTitle(attributedString, forState: .Disabled)
            
            self.setTitleColor(self.titleColorForState(.Normal)!, forState: .Normal)
            self.setTitleColor(self.titleColorForState(.Highlighted)!, forState: .Highlighted)
            self.setTitleColor(self.titleColorForState(.Disabled)!, forState: .Disabled)
            self.setTitleColor(self.titleColorForState(.Selected)!, forState: .Selected)
            
            self.configureAccessoryViews()
        }
    }
    
    func setTitleColor(color: UIColor, forState state: UIControlState) {
        if isImageMode {
            return
        }
        
        for button in self.buttons() {
            let attString = button.attributedTitleForState(state)
            if attString == nil {
                continue
            }
            
            let attributedString = NSMutableAttributedString.init(attributedString: attString!)
            let string = attributedString.string
            
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.Center
            style.lineBreakMode = NSLineBreakMode.ByWordWrapping
            style.minimumLineHeight = 20.0
            
            attributedString.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSMakeRange(0, string.characters.count))
            
            if showsCount {
                let components = string.componentsSeparatedByString("\n")
                if components.count < 2 {
                    return
                }
                
                let count = components[inverseTitles ? 1 : 0]
                let title = components[inverseTitles ? 0 : 1]
                
                let fontSizeForTitle = self.appropriateFontSizeForTitle(title)
                
                attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: _font.fontName, size: 19.0)!, range: (string as NSString).rangeOfString(count))
                attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: _font!.fontName, size: fontSizeForTitle)!, range: (string as NSString).rangeOfString(title))
                
                if state == UIControlState.Normal {
                    let topColor = inverseTitles ? color.colorWithAlphaComponent(0.5) : color
                    let bottomColor = inverseTitles ? color : color.colorWithAlphaComponent(0.5)
                    
                    let topLength = inverseTitles ? (title as NSString).length : (count as NSString).length
                    let bottomLength = inverseTitles ? (count as NSString).length : (title as NSString).length
                    
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: topColor, range: NSMakeRange(0, topLength))
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: bottomColor, range: NSMakeRange(topLength, bottomLength + 1))
                }
                else {
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSMakeRange(0, (string as NSString).length))
                    
                    if state == .Selected {
                        self.selectionIndicator.backgroundColor = color
                    }
                }
            }
            else {
                attributedString.addAttribute(NSFontAttributeName, value: self.font, range: NSMakeRange(0, (attributedString.string as NSString).length))
                attributedString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSMakeRange(0, (attributedString.string as NSString).length))
            }
            
            button.setAttributedTitle(attributedString, forState: state)
        }
        
        let key = "UIControlState\(state.rawValue)"
        self.colors[key] = color
    }
    
    func setDisplayCount(count: Bool) {
        if showsCount == count {
            return
        }
        
        showsCount = count
        
        self.configureSegments()
    }
    
    func setEnabled(enabled: Bool, forSegmentAtIndex segment: Int) {
        let button = self.buttonAtIndex(segment)
        button?.enabled = enabled
    }
    
    func insertAllSegments() {
        for i in 0...numberOfSegments - 1 {
            self.addButtonForSegment(i)
        }
        
        if isImageMode || self.window != nil {
            self.configureSegments()
        }
    }
    
    func addButtonForSegment(segment: Int) {
        let button = UIButton(type: .Custom)
        button.addTarget(self, action: "willSelectedButton:", forControlEvents: .TouchDown)
        button.addTarget(self, action: "didSelectButton:", forControlEvents: [.TouchDragOutside, .TouchUpInside, .TouchDragEnter, .TouchDragExit, .TouchCancel, .TouchUpInside, .TouchUpOutside])
        
        button.backgroundColor = UIColor.clearColor()
        button.opaque = true
        button.clipsToBounds = true
        button.adjustsImageWhenHighlighted = false
        button.exclusiveTouch = true
        button.tag = segment
        
        self.insertSubview(button, belowSubview: selectionIndicator)
    }
    
    func configureSegments() {
        for button in self.buttons() {
            self.configureButtonForSegment(button.tag)
        }
        
        self.configureAccessoryViews()
    }
    
    func configureAccessoryViews() {
        selectionIndicator.frame = self.selectionIndicatorRect()
        selectionIndicator.backgroundColor = self.tintColor
        
        hairline.frame = self.hairlineRect()
    }
    
    func configureButtonForSegment(segment: Int) {
        assert(segment < numberOfSegments, "cannot configure a button for a non-existing segment")
        assert(segment >= 0, "cannot configure a button for a negative segment")
        
        let item = items[segment]
        
        if item is NSString {
            self.configureButtonTitle(item as! String, forSegment: segment)
        }
        
        if item is UIImage {
            self.configureButtonImage(item as! UIImage, forSegment: segment)
        }
    }
    
    func configureButtonTitle(title: String, forSegment segment: Int) {
        let mutableTitle = NSMutableString(string: title)
        
        if showsCount {
            let count = self.countForSegmentAtIndex(segment)
            
            let breakString = "\n"
            var countString = ""
            
            if numberFormatter != nil {
                countString = self.numberFormatter.stringFromNumber(count)!
            }
            else if self.numberFormatter == nil && showsGroupingSeparators == true {
                countString = self.dynamicType.defaultFormatter().stringFromNumber(count)!
            }
            else {
                countString = "\(count)"
            }
            
            let resultString = inverseTitles ? breakString.stringByAppendingString(countString) : countString.stringByAppendingString(breakString)
            
            mutableTitle.insertString(resultString, atIndex: inverseTitles ? (title as NSString).length : 0)
        }
        
        let attributeString = NSMutableAttributedString(string: mutableTitle as String)
        self.setAttributedTitle(attributeString, forSegmentAtIndex: segment)
    }
    
    func configureButtonImage(image: UIImage, forSegment segment: Int) {
        let button = self.buttonAtIndex(segment)
        
        button?.setImage(image, forState: .Normal)
    }
    
    func willSelectedButton(sender: AnyObject) {
        let button = sender as! UIButton
        
        if selectedSegmentIndex != button.tag  && isTransitioning == false {
            self.setSelectedSegmentIndex(button.tag, animated: true)
            self.sendActionsForControlEvents(.ValueChanged)
        }
        else if !disableSelectedSegment {
            self.sendActionsForControlEvents(.ValueChanged)
        }
    }
    
    func didSelectButton(sender: AnyObject) {
        let button = sender as! UIButton
        
        button.highlighted = false
        button.selected = true
    }
    
    func unselectAllButtons() {
        self.buttons().forEach { (button) -> () in
            button.setValue(false, forKey: "selected")
            button.setValue(false, forKey: "highlighted")
        }
    }
    
    func enableAllButtonsInteraction(enable: Bool) {
        self.buttons().forEach { (button) -> () in
            button.setValue(enable, forKey: "userInteractionEnabled")
        }
    }
    
    func removeAllSegments() {
        if isTransitioning {
            return
        }
        
        self.buttons().forEach { (button) -> () in
            button.removeFromSuperview()
        }
        
        _items.removeAll()
        counts.removeAll()
    }
    
    class func defaultFormatter() -> NSNumberFormatter {
        struct StaticDefaultFormatter {
            static var formatter: NSNumberFormatter? = nil
            static var oncePredicate: dispatch_once_t = 0
        }
        dispatch_once(&StaticDefaultFormatter.oncePredicate) { () -> Void in
            StaticDefaultFormatter.formatter = NSNumberFormatter()
            StaticDefaultFormatter.formatter!.numberStyle = .DecimalStyle
            StaticDefaultFormatter.formatter!.groupingSeparator = NSLocale.currentLocale().objectForKey(NSLocaleGroupingSeparator) as! String
        }
        
        return StaticDefaultFormatter.formatter!
    }
}
