//
//  DraggableCardView.swift
//  Swipeable Stack View
//
//  Created by Nathan Kellert on 1/25/19.
//  Copyright (c) 2019 noobs2ninjas. All rights reserved.
//

import UIKit

public protocol CardViewDelegate: AnyObject {
    func cardWasSwiped(_ card: CardView)
    
    /// Called when a user taps the card.
    /// - Parameters:
    ///   - card: The CardView that was tapped.
    ///   - shouldHighlight: Currently is always true but will determine if card changes visually confirm tap was detected.
    func cardWasTapped(_ card: CardView, shouldHighlight:Bool)
    
    /// Called to give delegate the ability to disable disable dragging on specific card.
    /// - Parameter card: The card the user is attempting to drag.
    /// - Returns: A boolean on weather or not to recognize pan gesture aka drag.
    func shouldDragCard(_ card: CardView) -> Bool
    
    /// Called to notify delegate when a drag has concluded on a card.
    /// - Parameter card: The card the user finished dragging.
    func dragEndedOnCard(_ card: CardView)
}

public protocol AnimatorDelegate: class {
    func removeBehavior(_ behavior: UIDynamicBehavior)
    func addBehavior(_ behavior:UIDynamicBehavior)
    func addGravity(toCard card: CardView)
    func removeGravity(fromCard card: CardView)
}

open class CardView: UIView {
    
    // MARK:Constants and Variable
    internal let snapDistance = 0.499 /// If user does not drag beyond this distance the card will be dragged back.
    
    // TODO: Change delegates to set functions
    weak var delegate: CardViewDelegate!
    weak var animatorDelegate: AnimatorDelegate!

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!

    private var snapBehavior: UISnapBehavior?
    private var attachmentBehavior: UIAttachmentBehavior?
    private var dynamicItemBehavior: UIDynamicItemBehavior?

    fileprivate var lastTime: CFAbsoluteTime!
    fileprivate var angularVelocity: CGFloat = 0.0
    fileprivate var lastAngle: Float = 0.0
    fileprivate var initialCenter: CGPoint?

    fileprivate var selectedView: SelectedView?
    private var originalFrame: CGRect?

    open var isOriginal = true
    
    /// Is called before user animation begins as notification.
    /// To prevent user interaction inherit CardViewDelegate's shouldDragCard.
    internal func snapshotReady(){}
    
    /// Is called before user animation begins as notification.
    /// To prevent user interaction inherit CardViewDelegate's shouldDragCard.
    internal func willBeginDrag(){}
    
    /// Function is called when user interaction ends and card is returned to its original position without being removed.
    internal func didEndDrag(){}


    // MARK: Lifecycle
    
    /// Called to initialize with CGRect.zero frame
    public init() {
        super.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    /// Initializes CardView as a container view.
    /// Parameter view: UIView which holds cards content. Constraints are added to keep same frame as CardView
    public init(frame: CGRect, view: UIView) {
        super.init(frame: frame)
        setup()
        addSubview(view)

        // Add constraints to view if user chooses to use CardView as a container
        addConstraints(toView: view)
    }
    
    /// Called to initialize CardView with CGRect.zero frame which is used as a container for  the view given.
    /// Parameter view: UIView which holds cards content. Constraints are added to keep same frame as CardView
    public init(view: UIView) {
        super.init(frame: CGRect.zero)
        
        setup()
        addSubview(view);

        //Add constraints to view if user chooses to use CardView as a container
        addConstraints(toView: view)
    }
    
    // Remove behaviors and gesture recognizers when deinitializing to avoid leaks
    deinit {
        
        if snapBehavior != nil {
            animatorDelegate.removeBehavior(snapBehavior!)
        }

        if attachmentBehavior != nil {
            animatorDelegate.removeBehavior(attachmentBehavior!)
        }

        if dynamicItemBehavior != nil {
            animatorDelegate.removeBehavior(dynamicItemBehavior!)
        }
        
        snapBehavior = nil
        attachmentBehavior = nil
        dynamicItemBehavior = nil

        gestureRecognizers?.removeAll()
    }
    
    // Used to add constraints to a content view.
    private func addConstraints(toView view: UIView) {
        NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0).isActive = true
    }
    
    // MARK: Setup
    private func setup() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized))
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.delegate = self

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRecognized))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
    }

    public func finishSetup(){
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
        snapshotReady()
    }

    // MARK: GestureRecognizers
    @objc private func tapRecognized(_ recogznier: UITapGestureRecognizer) {
        delegate.cardWasTapped(self, shouldHighlight: true)
    }
    
    private var cardStack: UIView {
        return self.superview!.superview!
    }

    @objc private func panGestureRecognized(gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        
        case .began:
            if !delegate.shouldDragCard(self) {
                break
            }
            
            self.originalFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            
            willBeginDrag()

            applyPlainShadow()
        
            if initialCenter == nil {
                initialCenter = superview!.center
            }

            checkAndRemoveBehaviors()

            // Find where finger is on card and apply that offset as we compare card to superview.
            let point = gesture.location(in: self)
            let offset = UIOffset(horizontal: CGFloat(point.x - frame.width/2),
                                  vertical: CGFloat(point.y - frame.height/2))

            let anchor: CGPoint = gesture.location(in: superview!.superview!)

            // This is used for velocity and to give clean predictable angles
            lastTime = CFAbsoluteTimeGetCurrent()
            lastAngle = angleOfView(self)

            setAttachmentBehavior(withOffset: offset, andAnchor: anchor)
            break
        case .changed:
            
            attachmentBehavior!.anchorPoint = gesture.location(in: cardStack)
            break
        case .ended:

            let velocity: CGPoint = gesture.velocity(in: cardStack)
            let scalarVelocity: Float = sqrtf(Float((velocity.x * velocity.x) + (velocity.y * velocity.y)))
            
            // If scalarVelocity is not enough we just snap it back
            if scalarVelocity < 300 {
                addSnapBehavior(toPoint: initialCenter!)
                break
            }
            
            // Fling card off by applying gravity and force behaviors.
            animatorDelegate.removeBehavior(attachmentBehavior!)
            gesture.isEnabled = false
            dynamicItemBehavior = getDynamicBehavior(withVelocity: velocity)
            animatorDelegate.addBehavior(dynamicItemBehavior!)
            animatorDelegate.addGravity(toCard: self)
            
            break
        default: break
        }
    }
    
    
    /// Used to change view to show card is selected.
    private func setSelected(_ selected: Bool, withImage image:UIImage?, andColor color: UIColor?, andTime time: TimeInterval) {
        if selected {
            if selectedView == nil {
                selectedView = SelectedView(frame: originalFrame ?? CGRect(x: 0, y: 0, width: frame.width, height: frame.height), image: image, color: color)
                selectedView!.bounds = selectedView!.frame
                selectedView?.alpha = 0
            }
            
            addSubview(selectedView!)

            UIView.animate(withDuration: time) {
                self.selectedView?.alpha = 1
            }
            
        } else {
            
            UIView.animate(withDuration: time, animations: {
                self.selectedView?.alpha = 0
            }) { _ in
                self.selectedView?.removeFromSuperview()
                self.selectedView = nil
            }
        }
    }

    //MARK: Behavior Functions
    fileprivate func setAttachmentBehavior(withOffset offset: UIOffset, andAnchor anchor: CGPoint) {
        attachmentBehavior = UIAttachmentBehavior(item: self, offsetFromCenter: offset, attachedToAnchor: anchor)
        attachmentBehavior?.action = {
            let time = CFAbsoluteTimeGetCurrent()
            let angle = self.angleOfView(self)
            
            // If time has passed set angular velocity
            if time > self.lastTime! {
                self.angularVelocity = CGFloat(Double(angle - self.lastAngle) / (time - self.lastTime));
            }

            self.lastTime = time;
            self.lastAngle = angle;
        }
        animatorDelegate.addBehavior(attachmentBehavior!)
    }
    
    /// Used to snap card to point
    public func addSnapBehavior(toPoint point: CGPoint, completion: (()->Void)? = nil) {
        
        if attachmentBehavior != nil {
            animatorDelegate.removeBehavior(attachmentBehavior!)
        }
        
        panGestureRecognizer.isEnabled = false
        snapBehavior = UISnapBehavior(item: self, snapTo: point)
        animatorDelegate?.addBehavior(snapBehavior!)
        animatorDelegate.removeGravity(fromCard: self)
        
        snapBehavior?.action = {
            guard let view = self.superview?.superview, self.snapBehavior != nil else {
                self.checkAndRemoveBehaviors()
                self.snapBehavior = nil
                return
            }
            
            let center: CGPoint = self.convert(self.center, to: view)
            
            if self.distance(a: point, b: center) <= 0.499 {
                self.animatorDelegate.removeBehavior(self.snapBehavior!)
                self.panGestureRecognizer.isEnabled = true
                self.didEndDrag()
                self.layer.shadowColor = UIColor.clear.cgColor
                completion?()
            }

        }
    }
    
    // Create behavior to perform fling by adding velocity and angular velocity and adding weight.
    fileprivate func getDynamicBehavior(withVelocity velocity: CGPoint) -> UIDynamicItemBehavior {
        
        let dynamicBehavior = UIDynamicItemBehavior(items: [self])
        dynamicBehavior.addLinearVelocity(velocity, for: self)
        dynamicBehavior.addAngularVelocity(angularVelocity, for: self)
        dynamicBehavior.density = 5

        //when dynamic behavior performs an action
        dynamicBehavior.action = {
            //check to see if draggable card is in superview frame
            guard let view = self.superview?.superview?.superview, let rect = self.superview?.convert(self.frame, to: view) else {
                self.checkAndRemoveBehaviors()
                self.snapBehavior = nil
                return
            }
            
            if !rect.intersects(view.frame){
                self.checkAndRemoveBehaviors()
                self.snapBehavior = nil
                self.delegate.cardWasSwiped(self)
            }
        }
        return dynamicBehavior
    }

    // MARK: Gesture calculation func
    fileprivate func distance(a: CGPoint, b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }

    fileprivate func angleOfView(_ view: UIView) -> Float {
        return atan2(Float(view.transform.b), Float(view.transform.a))
    }

    // MARK: Behavior Management
    public func checkAndRemoveBehaviors() {
        
        if snapBehavior != nil {
            animatorDelegate.removeBehavior(snapBehavior!)
            snapBehavior = nil
        }

        if attachmentBehavior != nil {
            animatorDelegate.removeBehavior(attachmentBehavior!)
            attachmentBehavior = nil
        }

        if dynamicItemBehavior != nil {
            animatorDelegate.removeBehavior(dynamicItemBehavior!)
            dynamicItemBehavior = nil
        }
        
        if animatorDelegate != nil {
            animatorDelegate.removeGravity(fromCard: self)
        }
    }

    private func sendAndResetGesture(_ gesture: UIPanGestureRecognizer) {
        // Stop card from recognizing gesture until card is snapped back to its origin and we've removed all current behaviors.
        gesture.isEnabled = false
        checkAndRemoveBehaviors()
        animatorDelegate.addBehavior(snapBehavior!)
        gesture.isEnabled = true
    }
    
    // Used to show that card is picked up
    private func applyPlainShadow() {
        UIView.animate(withDuration: 0.4) {
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOffset = CGSize.zero
            self.layer.shadowOpacity = 0.8
            self.layer.shadowRadius = 8
        }
    }
    
    // Shadow removed if the card snapped back
    private func removeShadow() {
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowOpacity = 0
        self.layer.shadowRadius = 0
    }
}

// MARK: UIGestureRecognizerDelegate
extension CardView: UIGestureRecognizerDelegate {

    // Make recognizer play nice with UIControls
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIControl)
    }

    // Make recognizer play nice with other gestures accept for edge pan gestures.
    // We need that space
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let panGesture = gestureRecognizer is UIPanGestureRecognizer
        let isEdgePanGesture = otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
        return panGesture && isEdgePanGesture
    }

}
