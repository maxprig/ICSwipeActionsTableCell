
import UIKit

public protocol ICSwipeActionsTableCellDelegate : NSObjectProtocol {
    func swipeCellButtonPressedWithTitle(title: String, indexPath: NSIndexPath)
}

public class ICSwipeActionsTableCell: UITableViewCell {
    
    // MARK: - types

    /// Tuple type with title string and background color.
    typealias ICButtonTitleWithColor = (title: String, color: UIColor)
    
    /// Tuple type with title string, title and background color.
    typealias ICButtonTitleWithTextAndBackgroundColor = (title: String, color: UIColor, textColor: UIColor)
    
    /// Tuple type with title string, title font, title and background color.
    typealias ICButtonTitleWithFontTextAndBackgroundColor = (title: String, font: UIFont, textColor: UIColor, color: UIColor)
    
    // MARK: - properties

    
    /// Array of button title properties that will be displayed on the right, this can be one of four types:
    /// 1. Plain string:
    ///     // cell.rightButtonsTitles = ["Title 1", "Title 2"]
    ///
    /// 2. ICButtonTitleWithColor type:
    ///     // cell.rightButtonsTitles = [(title: "Title 1", color: UIColor.blackColor()), (title: "Title 2", color: UIColor.redColor())]
    ///
    /// 3. ICButtonTitleWithTextAndBackgroundColor type:
    ///     // [(title: "Title 1", color: UIColor.blackColor(), textColor:UIColor.whiteColor()), (title: "Title 2", color: UIColor.redColor(), textColor:UIColor.whiteColor())]
    ///
    /// 4. ICButtonTitleWithFontTextAndBackgroundColor type:
    ///     // [(title: "Title 1", font: UIFont.systemFontOfSize(22), textColor: UIColor.whiteColor(), color: UIColor.redColor())]
    ///
    /// Cell will recognise provided type automatically. All you need to worry about is the type that suits you best.
    public var rightButtonsTitles: [Any] = []
    
    /// Array of button title properties that will be displayed on the left, this can be one of four types:
    /// 1. Plain string:
    ///     // cell.leftButtonsTitles = ["Title 1", "Title 2"]
    ///
    /// 2. ICButtonTitleWithColor type:
    ///     // cell.leftButtonsTitles = [(title: "Title 1", color: UIColor.blackColor()), (title: "Title 2", color: UIColor.redColor())]
    ///
    /// 3. ICButtonTitleWithTextAndBackgroundColor type:
    ///     // [(title: "Title 1", color: UIColor.blackColor(), textColor:UIColor.whiteColor()), (title: "Title 2", color: UIColor.redColor(), textColor:UIColor.whiteColor())]
    ///
    /// 4. ICButtonTitleWithFontTextAndBackgroundColor type:
    ///     // [(title: "Title 1", font: UIFont.systemFontOfSize(22), textColor: UIColor.whiteColor(), color: UIColor.redColor())]
    ///
    /// Cell will recognise provided type automatically. All you need to worry about is the type that suits you best.
    public var leftButtonsTitles: [Any] = []
    
    ///  Buttons transiitons animation time. Default is 0.3, you can change it to whatever you like.
    public var animationDuration = 0.3
    
    ///  Buttons resize themselfes to the size of the title, this property will be applide to left and right margin between the title and button side. Default value is 16.
    public var buttonsSideMargins: CGFloat = 16.0
    
    ///  Flag indicating if the buttons should all be sized according to the biggest one. Default is no, meaning that every button will be the size of it's title.
    public var buttonsEqualSize = false
    
    /// The delegate that will respond to cell action callbacks.
    public var delegate: ICSwipeActionsTableCellDelegate?
  
    /// Buttons view corner radius, this property is applied to both left and right views. Default value is 0.0 (no rounded corner)
    public var buttonsViewCornerRadius: CGFloat = 0.0
  
    /// Buttons view edge inset, this property is useful to add margin on all sides of the buttons views. Default value is UIEdgeZero (no margin corner)
    public var buttonsViewEdgeInsets: UIEdgeInsets = UIEdgeInsetsZero
  
    /// Layout orientation of the buttons, this property defines if the buttons are stacked horizontally or vertically. `buttonsEqualSize` ans `buttonsSideMargins` have no impact when orientation is Vertical. Default is Horizontal.
    public var buttonsViewLayoutOrientation: ButtonsViewLayoutOrientationType = .Horizontal
  
    /// Front View.
    @IBOutlet public weak var frontView: UIView? {
      didSet {
        _animatableView = frontView!
      }
    }
  
    public enum ButtonsViewLayoutOrientationType {
        case Horizontal
        case Vertical
    }
  
    // MARK: - private properties

    private var _panRec: UIPanGestureRecognizer?
    private var _tapRec: UITapGestureRecognizer?
  
    private var _initialContentViewCenter = CGPointZero
    private var _currentContentViewCenter = CGPointZero
    
    private var _rightButtonsView: UIView?
    private var _rightButtonsViewWidth: CGFloat = 0.0
    private var _rightSwipeExpanded = false
    private var _leftButtonsView: UIView?
    private var _leftButtonsViewWidth: CGFloat = 0.0
    private var _leftSwipeExpanded = false
    private var _buttonsAreHiding = false
    
    private var _currentTouchInView = CGPointZero
    private var _currentTableView: UITableView?
    private var _currentTableViewOverlay: ICTableViewOvelay?

    private var _animatableView: UIView

    // MARK: - NSObject

    required public init(coder aDecoder: NSCoder) {
        self._animatableView = UIView()
        super.init(coder: aDecoder)!
        setupEverythigng()
    }

    deinit {
        removeTableOverlay()
    }
    
    // MARK: - UIView

    public override func layoutSubviews() {
        super.layoutSubviews()
        _initialContentViewCenter = self.contentView.center
    }

    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        _currentTouchInView = self.convertPoint(point, toView:self.contentView)
        if _leftSwipeExpanded || _rightSwipeExpanded {
            if _rightButtonsView != nil {
                let p = self.convertPoint(point, toView: _rightButtonsView)
                if CGRectContainsPoint((_rightButtonsView?.bounds)!, p) {
                    return _rightButtonsView?.hitTest(p, withEvent: event)
                }
            } else if _leftButtonsView != nil {
                let p = self.convertPoint(point, toView: _leftButtonsView)
                if CGRectContainsPoint((_leftButtonsView?.bounds)!, p) {
                    return _leftButtonsView?.hitTest(p, withEvent: event)
                }
            }
        }
        return super.hitTest(point, withEvent: event)
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        removeTableOverlay()
    }
    
    // MARK: - UITableViewCell

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self._animatableView = UIView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupEverythigng()
    }

    
    // MARK: - ICSwipeActionsTableCell

    
    /// Call this function to hide the buttons programmaticaly with animation. For non animated version use hideButtons(animated: Bool).
    func hideButtons() {
        hideButtons(animated: true)
    }
    /// Call this function to hide the buttons programmaticaly.
    ///
    /// :param: animated optional parameter to determint if the action should be animated or not. Default value is true.
    func hideButtons(animated animated: Bool) {
        hideButtonsAnimated(animated, velocity: CGPointZero)
    }
    

    // MARK: - ICSwipeActionsTableCell internal

    internal func viewPanned(panRec: UIPanGestureRecognizer) {
        let velocity = panRec.velocityInView(self)
        if (velocity.x < 0) { // view panned left
            if (panRec.state == .Began) {
                self.handleLeftPanGestureBegan()
            }
        } else {
            if (panRec.state == .Began) {
                self.handleRightPanGestureBegan()
            }
        }
        
        self.handlePanGestureChanged(panRec)
        
        if (panRec.state == .Ended) {
            self.handlePanGestureEnded(panRec, velocity: velocity)
        }
        
    }
    
    internal func viewTapped(tapRec: UITapGestureRecognizer) {
        hideButtons()
    }
    
    internal func buttonTouchUpInside(sender: UIButton) {
        if delegate != nil {
            let indexPath = self.currentTableView()?.indexPathForCell(self)
            if indexPath != nil {
                self.delegate!.swipeCellButtonPressedWithTitle(sender.titleLabel!.text!, indexPath: indexPath!)
            }
        }
    }

    
    // MARK: - ICSwipeActionsTableCell ()
    
    // MARK: - Setup

    private func setupEverythigng() {
        _animatableView = contentView
        self.addPanGestureRecognizer()
    }
    
    private func addPanGestureRecognizer() {
        _panRec = UIPanGestureRecognizer(target: self, action: "viewPanned:")
        if let validPan = _panRec {
            validPan.delegate = self
            self.addGestureRecognizer(validPan)
        }
    }
    
    private func addTapGestureRecognizer() {
        removeTapGestureRecognizer()
        _tapRec = UITapGestureRecognizer(target: self, action: "viewTapped:")
        if let validTap = _tapRec {
            validTap.cancelsTouchesInView = true
            validTap.delegate = self
            self.addGestureRecognizer(validTap)
        }
    }
    
    private func removeTapGestureRecognizer() {
        if _tapRec != nil {
            self.removeGestureRecognizer(_tapRec!)
            _tapRec = nil
        }
    }
    
    // MARK: - Button views

    private func addLeftButtonsView() {
        if leftButtonsTitles.count > 0 && _leftButtonsView == nil {
            _leftButtonsView = prepareButtonsView(leftButtonsTitles)
            _leftButtonsViewWidth = _leftButtonsView!.frame.size.width
            _leftButtonsView?.frame = CGRectMake(-_leftButtonsViewWidth, 0, _leftButtonsViewWidth, self.contentView.frame.size.height)
            _leftButtonsView?.frame = self.addEdgesFromFrame(_leftButtonsView?.frame)
            _leftButtonsView?.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.contentView.addSubview(_leftButtonsView!)
        }
    }
    
    private func addRightButtonsView() {
        if rightButtonsTitles.count > 0 && _rightButtonsView == nil {
            _rightButtonsView = prepareButtonsView(rightButtonsTitles)
            _rightButtonsViewWidth = _rightButtonsView!.frame.size.width
            _rightButtonsView?.frame = CGRectMake(self.contentView.frame.size.width-(_rightButtonsView?.frame.size.width)!, 0, _rightButtonsViewWidth, self.contentView.frame.size.height)
            _rightButtonsView?.frame = self.addEdgesFromFrame(_rightButtonsView?.frame)
            _rightButtonsView?.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.contentView.insertSubview(_rightButtonsView!, atIndex: 0)
        }
    }
    
    private func addButtonViews() {
        unselect()
        addRightButtonsView()
        addLeftButtonsView()
        addTapGestureRecognizer()
    }
    
    private func prepareButtonsView(buttonsTitles: [Any]) -> UIView {
        if buttonsTitles.count > 0 {
            let view = UIView(frame: CGRectMake(0, 0, 0, self.contentView.frame.size.height))
            if self.buttonsViewLayoutOrientation == .Vertical {
                view.frame = CGRectMake(0, 0, self.contentView.frame.size.width/2, 0)
            }
            view.layer.cornerRadius = self.buttonsViewCornerRadius
            view.clipsToBounds = true
          
            var maxButtonsSize: CGFloat = 0
            
            for buttonProperty in buttonsTitles {
                let button = self.createButtonWith(buttonProperty)
              
                if self.buttonsViewLayoutOrientation == .Horizontal {
                    button.frame = CGRectMake(view.frame.size.width, 0, button.frame.size.width + 2 * buttonsSideMargins, view.frame.size.height)
                    view.frame = CGRectMake(0, 0, view.frame.size.width + button.frame.width, view.frame.size.height)
                    view.addSubview(button)
                    maxButtonsSize = max(maxButtonsSize, button.frame.width)
                } else {
                    button.frame = CGRectMake(0, view.frame.size.height, view.frame.size.width, self.contentView.frame.size.height / CGFloat(buttonsTitles.count))
                    view.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height + button.frame.height)
                    view.addSubview(button)
                    maxButtonsSize = max(maxButtonsSize, button.frame.height)
                }
            }
            if buttonsEqualSize && self.buttonsViewLayoutOrientation == .Horizontal {
                view.frame = CGRectMake(0, 0, maxButtonsSize * CGFloat(buttonsTitles.count), view.frame.size.height)
                var currentX: CGFloat = 0
                for button in view.subviews {
                    button.frame = CGRectMake(currentX, 0, maxButtonsSize, view.frame.size.height)
                    currentX += maxButtonsSize
                }
            }
            return view
        }
        return UIView()
    }

    private func addEdgesFromFrame (frame: CGRect?) -> CGRect {
        if let frame_ = frame {
            return CGRectMake(frame_.origin.x + self.buttonsViewEdgeInsets.left,
                              frame_.origin.y + self.buttonsViewEdgeInsets.top,
                              frame_.size.width - self.buttonsViewEdgeInsets.left - self.buttonsViewEdgeInsets.right,
                              frame_.size.height - self.buttonsViewEdgeInsets.top - self.buttonsViewEdgeInsets.bottom)
        } else {
            return CGRectZero
        }
    }

    private func createButtonWith(buttonProperty: Any) -> UIButton {
        let buttonFullProperties = self.buttonsPropertiesFromObject(buttonProperty)
        let button = UIButton(type: .Custom)
        button.setTitle(buttonFullProperties.title, forState: .Normal)
        button.backgroundColor = buttonFullProperties.color
        button.setTitleColor(buttonFullProperties.textColor, forState: .Normal)
        button.titleLabel?.font = buttonFullProperties.font
        button.sizeToFit()
        button.addTarget(self, action: "buttonTouchUpInside:", forControlEvents: .TouchUpInside)
        return button
    }
    
    private func buttonsPropertiesFromObject(buttonProperty: Any) -> ICButtonTitleWithFontTextAndBackgroundColor {
        var buttonTitle = ""
        var backgroundColor = self.anyColor()
        var titleColor = UIColor.whiteColor()
        var titleFont = UIFont.systemFontOfSize(15.0)
        if let stringTitle = buttonProperty as? String {
            buttonTitle = stringTitle
        } else if let colorTouple = buttonProperty as? ICButtonTitleWithColor {
            buttonTitle = colorTouple.title
            backgroundColor = colorTouple.color
        } else if let colorAndTextTouple = buttonProperty as? ICButtonTitleWithTextAndBackgroundColor {
            buttonTitle = colorAndTextTouple.title
            backgroundColor = colorAndTextTouple.color
            titleColor = colorAndTextTouple.textColor
        } else if let colorAndTitleAttrsTouple = buttonProperty as? ICButtonTitleWithFontTextAndBackgroundColor {
            buttonTitle = colorAndTitleAttrsTouple.title
            backgroundColor = colorAndTitleAttrsTouple.color
            titleFont = colorAndTitleAttrsTouple.font
            titleColor = colorAndTitleAttrsTouple.textColor
        }
        return (title: buttonTitle, font: titleFont, textColor: titleColor, color: backgroundColor)
    }
    
    private func anyColor() -> UIColor {
        let hue:CGFloat = (CGFloat)( arc4random() % 256 ) / 256.0  //  0.0 to 1.0
        let saturation:CGFloat = (CGFloat)( arc4random() % 128 ) / 256.0  //  0.0 to 1.0
        let brightness:CGFloat = (CGFloat)( arc4random() % 128 ) / 256.0  + 0.5 //  0.0 to 1.0
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    private func removeRightButtonsView() {
        _rightButtonsView?.removeFromSuperview()
        _rightButtonsView = nil
        _buttonsAreHiding = false
    }
    
    private func removeLeftButtonsView() {
        _leftButtonsView?.removeFromSuperview()
        _leftButtonsView = nil
        _buttonsAreHiding = false
    }
    
    private func hideButtonsAnimated(animated: Bool, velocity: CGPoint) {
        if !_buttonsAreHiding {
            let newContentViewCenter = CGPointMake(self.contentView.center.x, self.contentView.center.y)
            _currentContentViewCenter = newContentViewCenter
            _rightSwipeExpanded = false
            _leftSwipeExpanded = false
            _buttonsAreHiding = true
            removeTableOverlay()
            
            func completion() {
                self.removeLeftButtonsView()
                self.removeRightButtonsView()
                self.restoreTableSelection()
                self.removeTapGestureRecognizer()
                self._initialContentViewCenter = self._animatableView.center
            }
            
            if animated {
                var hideAnimationDuration = animationDuration
                if velocity != CGPointZero {
                    let currentDelta: Double = Double(_initialContentViewCenter.x) - Double(self._animatableView.center.x)
                    let xVelocity: Double = Double(velocity.x)
                    hideAnimationDuration = currentDelta / xVelocity
                    if hideAnimationDuration < 0.0 || hideAnimationDuration > animationDuration {
                        hideAnimationDuration = animationDuration
                    }
                }
                UIView.animateWithDuration(hideAnimationDuration, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
                    self._animatableView.center = newContentViewCenter
                    }) { (completed) -> Void in
                        completion()
                }
            } else {
                self._animatableView.center = newContentViewCenter
                completion()
            }
        }
    }

    
    // MARK: - GestureHandlers

    private func handleLeftPanGestureBegan() {
        if !_rightSwipeExpanded && rightButtonsTitles.count > 0 {
            addButtonViews()
            _rightSwipeExpanded = true
        }
    }
    
    private func handleRightPanGestureBegan() {
        if !_leftSwipeExpanded && leftButtonsTitles.count > 0 {
            addButtonViews()
            _leftSwipeExpanded = true
        }
    }
    
    private func unselect() {
        if (self.selected) {
            self.selected = false
        }
    }
    
    private func handlePanGestureEnded(panRec: UIPanGestureRecognizer, velocity: CGPoint) {
        var newContentViewCenter = CGPointZero

        if (velocity.x < 0) { // view panned left
            if _rightSwipeExpanded {
                newContentViewCenter = CGPointMake(_initialContentViewCenter.x - _rightButtonsViewWidth, self.contentView.center.y)
            } else {
                hideButtonsAnimated(true, velocity: velocity)
            }
        } else { // view panned right
            if _leftSwipeExpanded {
                newContentViewCenter = CGPointMake(_initialContentViewCenter.x + _leftButtonsViewWidth, self.contentView.center.y)
            } else {
                hideButtonsAnimated(true, velocity: velocity)
            }
        }
        if newContentViewCenter != CGPointZero {
            _currentContentViewCenter = newContentViewCenter
            self.addTableOverlay()

            UIView.animateWithDuration(animationDuration, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
                self._animatableView.center = newContentViewCenter
                },  completion: { (Bool) -> Void in
                self._initialContentViewCenter = self._animatableView.center
            })
        }
    }
    
    private func handlePanGestureChanged(panRec: UIPanGestureRecognizer) {
        let translation = panRec.translationInView(self)
        
        let newCenter = CGPointMake(_initialContentViewCenter.x + translation.x, _animatableView.center.y)
        let panIsWithinRightMotionRange = (contentView.center.x - newCenter.x) < _rightButtonsViewWidth
        let panIsWithinLeftMotionRange = (newCenter.x - contentView.center.x) < _leftButtonsViewWidth
        if (panIsWithinLeftMotionRange && panIsWithinRightMotionRange) { // no more then buttons width
            self._animatableView.center = newCenter
            _currentContentViewCenter = newCenter
            if _leftSwipeExpanded && (newCenter.x - _animatableView.center.x) < 0 { // view changed from left to right expansion
                _leftSwipeExpanded = false
                _rightSwipeExpanded = true
            } else if _rightSwipeExpanded && ( _animatableView.center.x - newCenter.x) < 0 {
                _rightSwipeExpanded = false
                _leftSwipeExpanded = true
            }
        }
    }
  
    public override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == _panRec) {
            
            if (self.editing) {
                return false
            }
            
            let translation = _panRec?.translationInView(self)
            if (fabs(translation!.y) > fabs(translation!.x)) {
                return false
            }
        }
        return true
    }
    
    
    // MARK: - parent TableView
    
    private func currentTableView() -> UITableView? {
        if (_currentTableView == nil) {
            var view = self.superview;
            while (view != nil) {
                if (view!.isKindOfClass(UITableView.self)) {
                    _currentTableView = view as? UITableView
                }
                view = view!.superview
            }
        }
        return _currentTableView
    }
    
    private func restoreTableSelection() {
        let tableView = currentTableView()
        let myIndexPath = tableView?.indexPathForCell(self)
        if myIndexPath != nil {
            let selectedRows = tableView?.indexPathsForSelectedRows
            if selectedRows != nil {
                if selectedRows!.contains(myIndexPath!) {
                    self.selected = true
                }
            }
        }
    }
    
    // MARK: - Table view overlay
    
    class ICTableViewOvelay: UIView {
        var parentCell : ICSwipeActionsTableCell?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.backgroundColor = UIColor.clearColor()
        }

        required init(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)!
        }
        
        override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
            if parentCell != nil {
                if CGRectContainsPoint(parentCell!.bounds, self.convertPoint(point, toView: parentCell)) {
                    return nil
                }
            }
            parentCell?.hideButtons()
            return nil;
        }
    }

    private func addTableOverlay() {
        if let table = self.currentTableView() {
            _currentTableViewOverlay = ICTableViewOvelay(frame: table.frame)
            _currentTableViewOverlay?.parentCell = self
            table.addSubview(_currentTableViewOverlay!)
        }
    }
    
    private func removeTableOverlay() {
        _currentTableViewOverlay?.removeFromSuperview()
        _currentTableViewOverlay = nil
    }

}
