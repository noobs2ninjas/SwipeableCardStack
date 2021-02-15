//
//  ViewController.swift
//  SwipeableCardStack
//
//  Created by noobs2ninjas on 07/05/2020.
//  Copyright (c) 2020 noobs2ninjas. All rights reserved.
//

import UIKit
import SwipeableCardStack

let CARD_COUNT = 10

class ViewController: UIViewController {
    
    @IBOutlet var cardStack: CardStack!
    @IBOutlet var messageView: MessageView!
    
    var index = 0 /// tracks what index we are on for swipe messages
    var firstLoad = false /// Make sure we only load view array and stack once
    
    // Lazy instatiation of CardView Array and Sheesh View
    lazy var cards:[CardView] = {
        var viewArray = [CardView]()
        
        for i in 0..<CARD_COUNT {
            let newCard = createView(withNumber: i + 1)
            viewArray.append(newCard)
        }
        
        return viewArray
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        messageView.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !firstLoad else {
            return
        }
        
        firstLoad = true
        
        // When view appears load card stack and set delegate
        cardStack.loadCards(withCardArray: cards, animated: true)
        cardStack.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Used to create card with a label that has a number for text.
    func createView(withNumber number: Int) -> CardView {
        
        let textLabel = UILabel(frame: .zero)
        textLabel.textColor = .white
        textLabel.font = .systemFont(ofSize: 18)
        textLabel.textAlignment = .center
        textLabel.text = "\(number)"
        textLabel.backgroundColor = .darkGray
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        return CardView(view: textLabel)
    }
    
    func addMessageView(withText text:String) {
        messageView.text = text
        // animate in
        UIView.animate(withDuration: 0.5) {
            self.messageView.alpha = 1
        } completion: { _ in
            // Wait half a second and animate out
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .transitionCurlUp) {
                self.messageView.alpha = 0
            }
        }
    }
}


// MARK:  Card Stack Delegate
extension ViewController: CardStackDelegate {
    
    func cardWasTapped(_ card: CardView) {
        // When card is tapped loop through subviews to find our label
        for view in card.subviews {
            // once label is found add alert view to recognize tap gesture
            if let textView = view as? UILabel {
                let alertViewController = UIAlertController(title: "Congradulations!",
                                                            message: "You tapped card #\(textView.text!)! Isn't that great?",
                                                            preferredStyle: .alert)
                
                let yesAction = UIAlertAction(title: "Yes!", style: .default) { _ in
                    self.addMessageView(withText: "Calm the hell down. Sheesh.")
                }
                
                let yesserAction = UIAlertAction(title: "YES!!!", style: .default) { _ in
                    self.addMessageView(withText: "Calm the hell down. Sheesh.")
                }
                
                alertViewController.addAction(yesAction)
                alertViewController.addAction(yesserAction)
                
                present(alertViewController, animated: true)
            }
        }
    }
    
    func cardWasSwiped(_ card: CardView, onCardStack CardStack: CardStack) {
        let array = ["Nice", "Great! You figured it out.", "Ok. Guess we dont need that card.", "Is this some kind of sick game to you!?", "What was wrong with that one!?", "You're a monster!!!", "Fine. Throw them all away!!!", "You're a sick sick puppy."]
        
        if index < array.count {
            addMessageView(withText: array[index])
            index += 1
        }
        
    }
    
}

