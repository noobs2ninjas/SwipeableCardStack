///
//  DraggableCardView.swift
//  Swipeable Stack View
//
//  Created by Nathan Kellert on 1/25/19.
//  Copyright (c) 2019 Yalantis. All rights reserved.
//

import UIKit

public protocol StackViewDelegate: AnyObject {
    func cardWasSwiped(_ card: CardView, onStackView stackView: StackView)
    func cardWasTapped(_ card: CardView)
    func shouldReloadEmptyStackView(_ stackView: StackView) -> Bool
    func shouldDragCard(_ card:CardView, onStackView stackView: StackView) -> Bool
    func cardDidShow(_ card: CardView, onStackView stackView: StackView)
    func dragEndedOnCard(_ card: CardView, onStackView stackView: StackView)
}

public extension StackViewDelegate {
    func cardWasSwiped(_ card: CardView, onStackView stackView: StackView) {}
    func cardWasTapped(_ card: CardView) {}
    func shouldReloadEmptyStackView(_ stackView: StackView) -> Bool { return true }
    func shouldDragCard(_ card:CardView, onStackView stackView: StackView) -> Bool { return true }
    func cardDidShow(_ card: CardView, onStackView stackView: StackView) {}
    func dragEndedOnCard(_ card: CardView, onStackView stackView: StackView) {}
}

open class StackView: UIView {

    public var delegate: StackViewDelegate!
    
    public private(set) var index: Int!
    public private(set) var isSelected = false
    public private(set) var cardSelected: CardView?

    fileprivate var originalArray = [CardView]()
    fileprivate var currentArray = [CardView]()
    fileprivate var shouldReset = false
    fileprivate var waitingCards: [CardView]?
    fileprivate var isAnimating = false
    fileprivate var shouldLoad = false


    // MARK: Gravity Behavior Functions

    fileprivate lazy var animator: UIDynamicAnimator =  {
        return UIDynamicAnimator(referenceView: superview ?? self)
    }()

    fileprivate lazy var gravityBehavior: UIGravityBehavior = {
        let newGavityBehavior = UIGravityBehavior(items: [])
        newGavityBehavior.magnitude = 3
        self.animator.addBehavior(newGavityBehavior)
        return newGavityBehavior
    }()

    // MARK: Initialization Functions
    public init(frame: CGRect, cardArray: [CardView]?) {
        super.init(frame: frame)
        if cardArray != nil {
            self.originalArray = setupCards(inArray: cardArray!)
            self.currentArray = originalArray
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    fileprivate func snapCards(inCardArray cardArray: [CardView], withCompletion completion: @escaping (()->Void)) {
        var cardsCompleted = 0
        for card in cardArray {

            //We add snap behavior to fix z axis quickly
            card.addSnapBehavior(toPoint: self.center, completion: {
                cardsCompleted += 1
                card.removeFromSuperview()
                card.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
                if cardsCompleted == cardArray.count {
                    completion()
                }
            })
        }
    }

    // MARK: Card Loading
    private func loadCards(_ animated: Bool) {
        if animated { self.alpha = 0 }
        if currentArray.count == 0 { return }
        for index in 0...(currentArray.count - 1) {
            let card = currentArray[index]
            card.delegate = self
            let isTop = index == 0
            card.isUserInteractionEnabled = isTop
            isTop ? addSubview(card) : insertSubview(card, belowSubview: currentArray[index - 1])
        }

        if animated {
            self.transform = CGAffineTransform.identity.scaledBy(x: 0.1, y: 0.1)

            UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseIn, animations: {
                self.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
                self.alpha = 1
            }, completion: { (completed) in
                for card in self.currentArray{
                    card.finishSetup()
                    self.isUserInteractionEnabled = true
                }

                self.isAnimating = false

                if let newCards = self.waitingCards, !newCards.isEmpty {
                    self.waitingCards?.removeAll()
                    self.waitingCards = nil
                    self.loadCards(withCardArray: newCards, animated: true)

                }

            })
        }
    }

    fileprivate func setupCards(inArray cardArray: [CardView]) -> [CardView]{
        for card in cardArray{
            card.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            card.animatorDelegate = self
            card.delegate = self
        }
        return cardArray
    }

    override open func layoutSubviews() {

        if shouldReset && !isAnimating {
            isAnimating = true
            self.isUserInteractionEnabled = false
            self.alpha = 0
            var snapArray = [CardView]()
            for card in currentArray {
                card.animatorDelegate = self
                addSubview(card)
                let center: CGPoint = card.convert(card.center, to: card.superview!.superview!)
                center != self.center ? snapArray.append(card) : card.removeFromSuperview()
            }

            if snapArray.count > 0 {
                snapCards(inCardArray: snapArray, withCompletion: {
                    self.loadCards(true)
                })
            }else{
                isAnimating = true
                self.loadCards(true)
            }

            shouldReset = false
        }else if shouldLoad {
            isAnimating = true
            self.loadCards(true)
        }
        super.layoutSubviews()
    }

    fileprivate func clear() {
        for card in currentArray{
            card.removeFromSuperview()
        }
        currentArray.removeAll()
    }

    open func reloadStack(_ animated: Bool) {
        clear()
        currentArray = originalArray
        shouldReset = true
        setNeedsLayout()
    }

    open func loadCards(withCardArray cardArray: [CardView], animated: Bool) {
        if !isAnimating {
            if !originalArray.isEmpty {
                clear()
                originalArray.removeAll()
            }
            originalArray = setupCards(inArray: cardArray)
            currentArray = originalArray
            isAnimating = true
            loadCards(true)
        } else {
            waitingCards = cardArray
        }
    }

    open func addCard(_ card: CardView) {
        // TODO: Create que that allows cards to be added between touches.
        // Strange things happen if loading cards while view is being interacted with
        isUserInteractionEnabled = false

        //Find the last card and disable user interaction so we can add the card at the back.
        if let card = currentArray.last { card.isUserInteractionEnabled = false }
        originalArray.insert(card, at: 0)
        currentArray.insert(card, at: 0)

        //TODO: in the future allow adding of cards to original array
        //mark card as not original so it can be removed from the original array when swiped
        card.isOriginal = false

        // TODO: Allow maintaining of users frame
        //for now we assume the cards will be the same size as the stack view
        card.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        card.animatorDelegate = self
        card.delegate = self
        card.isUserInteractionEnabled = false
        card.alpha = 0
        addSubview(card)

        //Animate card in
        UIView.animate(withDuration: 0.5, animations: {
            card.alpha = 1
        }) { (completed) in
            card.finishSetup()
            card.snapshotReady()
            card.isUserInteractionEnabled = true
            self.isUserInteractionEnabled = true
        }
    }
}

extension StackView: CardViewDelegate {

    public func dragEndedOnCard(_ card: CardView) {
        delegate.dragEndedOnCard(card, onStackView: self)
    }

    public func cardWasSwiped(_ card: CardView) {
        if !card.isOriginal { originalArray.removeFirst() }
        else { delegate.cardWasSwiped(card, onStackView: self) }

        currentArray.removeFirst()

        print(currentArray.count)
        if currentArray.isEmpty{
            if delegate.shouldReloadEmptyStackView(self) {
                reloadStack(true)
            }
        } else {
            delegate.cardDidShow(currentArray.first!, onStackView: self)
            currentArray.first!.isUserInteractionEnabled = true
        }

        card.removeFromSuperview()
    }

    @objc func unselectCard(_ timer: Timer) {
        if cardSelected != nil { cardSelected = nil }
        timer.invalidate()
    }

    public func cardWasTapped(_ card: CardView, shouldHighlight: Bool) {

        // TODO: Add tap effect
        if shouldHighlight && cardSelected == nil{
            //let selectedData = stackDelegate.selectedProperties()
            //card.setSelected(true, withImage: selectedData.image, andColor: selectedData.color, andTime: 0.2)
            cardSelected = card

            let timer = Timer(fireAt: Date().addingTimeInterval(0.2), interval: 0.2, target: self, selector: #selector(unselectCard), userInfo: nil, repeats: false)

            RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
        }

        delegate.cardWasTapped(card)
    }

    public func shouldDragCard(_ card: CardView) -> Bool {
        return delegate.shouldDragCard(card, onStackView: self)
    }
}

extension StackView: AnimatorDelegate {

    public func addGravity(toCard card: CardView) {
        gravityBehavior.addItem(card)
    }

    public func removeGravity(fromCard tile: CardView) {
        gravityBehavior.removeItem(tile)
    }

    public func addBehavior(_ behavior: UIDynamicBehavior) {
        animator.addBehavior(behavior)
    }

    public func removeBehavior(_ behavior: UIDynamicBehavior) {
        animator.removeBehavior(behavior)
    }
}
