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
    
    // Lazy instatiation of CardView Array and Sheesh View
    
    lazy var cards:[CardView] = {
        var viewArray = [CardView]()
        
        for i in 0..<CARD_COUNT {
            let newCard = createView(withNumber: i + 1)
            viewArray.append(newCard)
        }
        
        return viewArray
    }()
    
    // When view appears load card stack and set delegate
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        cardStack.loadCards(withCardArray: cards, animated: true)
        cardStack.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
}


// MARK:  Card Stack Delegate
extension ViewController: CardStackDelegate {
    
    func addCalmDownView() {
        
        let width: CGFloat = 220
        let height: CGFloat = 50
        
        let frame = CGRect(x: self.view.frame.width/2 - width/2, y: self.view.frame.height/2 - height/2, width: width, height: height)
        
        let calmDownView = SheeshView(frame: frame)
        calmDownView.alpha = 0
        
        view.addSubview(calmDownView)
        
        // animate in
        UIView.animate(withDuration: 0.5) {
            calmDownView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .transitionCurlUp) {
                calmDownView.alpha = 0
            } completion: { _ in
                calmDownView.removeFromSuperview()
            }
        }

    }
    
    func cardWasTapped(_ card: CardView) {
        // When card is tapped loop through subviews to find our label
        for view in card.subviews {
            // once label is found add alert view to recognize tap gesture
            if let textView = view as? UILabel {
                let alertViewController = UIAlertController(title: "Congradulations!",
                                                            message: "You tapped card #\(textView.text!)! Isn't that great?",
                                                            preferredStyle: .alert)
                
                let yesAction = UIAlertAction(title: "Yes!", style: .default) { _ in
                    self.addCalmDownView()
                }
                
                let yesserAction = UIAlertAction(title: "YES!!!", style: .default) { _ in
                    self.addCalmDownView()
                }
                
                alertViewController.addAction(yesAction)
                alertViewController.addAction(yesserAction)
                
                present(alertViewController, animated: true)
            }
        }
    }
    
    func cardWasSwiped(_ card: CardView, onCardStack CardStack: CardStack) {
         
    }
    
}

