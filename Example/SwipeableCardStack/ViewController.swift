//
//  ViewController.swift
//  SwipeableCardStack
//
//  Created by noobs2ninjas on 07/05/2020.
//  Copyright (c) 2020 noobs2ninjas. All rights reserved.
//

import UIKit
import SwipeableCardStack

class ViewController: UIViewController {
    
    @IBOutlet var cardStack: CardStack!
    
    var views = [CardView]()
    
    var cards = 10

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        for i in 0..<10 {
            views.append(createView(withNumber: i))
        }
        
        cardStack.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        cardStack.loadCards(withCardArray: views, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createView(withNumber number: Int) -> CardView {
        
        
        let textLabel = UILabel(frame: .zero)
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 18)
        textLabel.textAlignment = .center
        textLabel.text = "\(number)"
        textLabel.backgroundColor = .gray
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        return CardView(view: textLabel)
    }

}

extension ViewController: CardStackDelegate {
    
}

