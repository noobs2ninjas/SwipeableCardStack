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
    func cardWasTapped(_ card: CardView, shouldHighlight:Bool)
    func shouldDragCard(_ card: CardView) -> Bool
    func dragEndedOnCard(_ card: CardView)
}

public protocol AnimatorDelegate: class {
    func removeBehavior(_ behavior: UIDynamicBehavior)
    func addBehavior(_ behavior:UIDynamicBehavior)
    func addGravity(toCard card: CardView)
    func removeGravity(fromCard card: CardView)
}

open class CardView: UIView {

    weak var delegate: CardViewDelegate!
    weak var animatorDelegate: AnimatorDelegate!

    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!

    fileprivate var snapBehavior: UISnapBehavior?
    fileprivate var attachmentBehavior: UIAttachmentBehavior?
    fileprivate var dynamicItemBehavior: UIDynamicItemBehavior?

    fileprivate var lastTime: CFAbsoluteTime!
    fileprivate var angularVelocity: CGFloat = 0.0
    fileprivate var lastAngle: Float = 0.0
    fileprivate var initialCenter: CGPoint?

    private var selectedView: SelectedView?
    private var originalFrame: CGRect?

    open var isOriginal = true

    internal func snapshotReady(){}
    internal func willBeginDrag(){}
    internal func didEndDrag(){}


    // MARK: Lifecycle
    public init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public init(frame: CGRect, view: UIView) {
        super.init(frame: frame)
        setup()
        addSubview(view);

        //Add constraints to view if user chooses to use CardView as a container
        addConstraints(toView: view)
    }

    public init(view: UIView) {
        super.init(frame: CGRect.zero)
        
        setup()
        addSubview(view);

        //Add constraints to view if user chooses to use CardView as a container
        addConstraints(toView: view)
    }

    fileprivate func addConstraints(toView view: UIView) {
        NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0).isActive = true
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

    private func setup() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized))
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.delegate = self

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRecognized))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
    }

    open func finishSetup(){
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
        snapshotReady()
    }

    //MARK: GestureRecognizers
    @objc func tapRecognized(_ recogznier: UITapGestureRecognizer) {
        delegate.cardWasTapped(self, shouldHighlight: true)
    }

    @objc func panGestureRecognized(gesture: UIPanGestureRecognizer) {

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

            //Find where finger is on card and apply that offset as we compare card to superview.
            let point = gesture.location(in: self)
            let offset = UIOffset(horizontal: CGFloat(point.x - frame.width/2),
                                  vertical: CGFloat(point.y - frame.height/2))

            let anchor: CGPoint = gesture.location(in: superview!.superview!)

            // This is used for velocity and to give clean predictable angles
            lastTime = CFAbsoluteTimeGetCurrent()
            lastAngle = angleOfView(self)

            addAttachmentBehavior(withOffset: offset, andAnchor: anchor)
            break
        case .changed:
            
            let anchorPoint = gesture.location(in: superview!.superview!)
            attachmentBehavior!.anchorPoint = anchorPoint
            break
        case .ended:

            let velocity: CGPoint = gesture.velocity(in: superview!.superview)
            let scalarVelocity: Float = sqrtf(Float((velocity.x * velocity.x) + (velocity.y * velocity.y)))
            
            // If scalarVelocity is not enough we just snap it back
            if scalarVelocity < 300 {
                addSnapBehavior(toPoint: initialCenter!)
                break
            }
            
            //Fling card off by applying gravity and force behaviors.
            animatorDelegate.removeBehavior(attachmentBehavior!)
            gesture.isEnabled = false
            dynamicItemBehavior = getDynamicBehavior(withVelocity: velocity)
            animatorDelegate.addBehavior(dynamicItemBehavior!)
            animatorDelegate.addGravity(toCard: self)
            
            break
        default: break
        }
    }

    public func setSelected(_ selected: Bool, withImage image:UIImage?, andColor color: UIColor?, andTime time: TimeInterval){
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
            }, completion: { (completed) in
                self.selectedView?.removeFromSuperview()
                self.selectedView = nil
            })
        }
    }

    //MARK: Behavior Functions
    fileprivate func addAttachmentBehavior(withOffset offset: UIOffset, andAnchor anchor: CGPoint) {
        attachmentBehavior = UIAttachmentBehavior(item: self, offsetFromCenter: offset, attachedToAnchor: anchor)
        attachmentBehavior?.action = {
            let time = CFAbsoluteTimeGetCurrent()
            let angle = self.angleOfView(self)

            if time > self.lastTime! {
                self.angularVelocity = CGFloat(Double(angle - self.lastAngle) / (time - self.lastTime));
            }

            self.lastTime = time;
            self.lastAngle = angle;
        }
        animatorDelegate.addBehavior(attachmentBehavior!)
    }

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
                self.layer.shadowColor = UIColor.clear.cgColor
                self.didEndDrag()
                completion?()
            }
            
        }
    }

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

    // MARK: Gesture calculation functions
    fileprivate func distance(a: CGPoint, b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }

    fileprivate func angleOfView(_ view: UIView) -> Float {
        return atan2(Float(view.transform.b), Float(view.transform.a))
    }

    // MARK: Behavior Management
    open func checkAndRemoveBehaviors() {
        if snapBehavior != nil{
            animatorDelegate.removeBehavior(snapBehavior!)
        }

        if attachmentBehavior != nil{
            animatorDelegate.removeBehavior(attachmentBehavior!)
            attachmentBehavior = nil
        }

        if dynamicItemBehavior != nil{
            animatorDelegate.removeBehavior(dynamicItemBehavior!)
            dynamicItemBehavior = nil
        }
        if animatorDelegate != nil{
            animatorDelegate.removeGravity(fromCard: self)
        }
    }

    private func sendAndResetGesture(_ gesture: UIPanGestureRecognizer) {
        gesture.isEnabled = false
        checkAndRemoveBehaviors()
        animatorDelegate.addBehavior(snapBehavior!)
        gesture.isEnabled = true
    }

    private func applyPlainShadow() {
        UIView.animate(withDuration: 0.4) {
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOffset = CGSize.zero
            self.layer.shadowOpacity = 0.8
            self.layer.shadowRadius = 8
        }
    }

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
        return (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIScreenEdgePanGestureRecognizer)
    }

}
