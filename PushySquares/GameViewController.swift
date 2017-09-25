import UIKit
import SwiftyAnimate

class GameViewController: UIViewController, GameDelegate {

    @IBOutlet var boardView: GameBoardView!
    @IBOutlet var statusBar: StatusBar!
    let game = Game(map: .standard, playerCount: 4)
    
    var swipeUpGR: UISwipeGestureRecognizer!
    var swipeDownGR: UISwipeGestureRecognizer!
    var swipeLeftGR: UISwipeGestureRecognizer!
    var swipeRightGR: UISwipeGestureRecognizer!
    
    var allGR: [UIGestureRecognizer] {
        return [swipeUpGR, swipeDownGR, swipeRightGR, swipeLeftGR]
    }
    
    override func viewDidLoad() {
        repositionViews(size: view.frame.size)
        
        boardView.game = self.game
        
        game.delegate = self
        
        swipeUpGR = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeDownGR = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
        swipeLeftGR = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        swipeRightGR = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        swipeUpGR.direction = .up
        swipeDownGR.direction = .down
        swipeLeftGR.direction = .left
        swipeRightGR.direction = .right
        
        allGR.forEach { self.view.addGestureRecognizer($0) }
        
        self.statusBar.setNewSquareIn(value: self.game.currentPlayer.turnsUntilNewSquare)
        self.statusBar.setCurrentTurn(value: self.game.currentPlayer.color)
        self.statusBar.setLives(players: self.game.players)
    }
    
    func swipedUp() {
        game.moveUp()
    }
    
    func swipedDown() {
        game.moveDown()
    }
    
    func swipedLeft() {
        game.moveLeft()
    }
    
    func swipedRight() {
        game.moveRight()
    }
    
    func playerDidMakeMove(direction: Direction?, originalPositions: [Position], destroyedSquarePositions: [Position], greyedOutPositions: [Position], newSquareColor: Color?) {
        var moveAnim = Animate()
        
        for position in originalPositions {
            let squareView = boardView.viewWithTag(position.hashValue) as! SquareView
            let squareViewMove: Animate
            switch direction! {
            case .down:
                squareViewMove = squareView.moveDown
            case .up:
                squareViewMove = squareView.moveUp
            case .left:
                squareViewMove = squareView.moveLeft
            case .right:
                squareViewMove = squareView.moveRight
            }
            moveAnim = moveAnim.and(animation: squareViewMove)
        }
        
        var destroyedAnim = Animate()
        for position in destroyedSquarePositions {
            let squareView = boardView.viewWithTag(position.hashValue) as! SquareView
            destroyedAnim = destroyedAnim.and(animation: squareView.destroyed)
        }
        moveAnim = moveAnim.then(animation: destroyedAnim)
        
        var greyOutAnim = Animate()
        for position in greyedOutPositions {
            let squareView = boardView.viewWithTag(position.hashValue) as! SquareView
            greyOutAnim = greyOutAnim.and(animation: squareView.greyOut)
        }
        moveAnim = moveAnim.then(animation: greyOutAnim)
        
        if let color = newSquareColor {
            boardView.addSquareView(at: game.spawnpoints[color]!, color: GameBoardView.colorToUIColor[color]!)
            let squareView = boardView.viewWithTag(game.spawnpoints[color]!.hashValue) as! SquareView
            squareView.alpha = 0
            moveAnim = moveAnim.then(animation: squareView.appear)
        }
        
        allGR.forEach { $0.isEnabled = false }
        moveAnim.perform()
            {
            [weak self] in
            guard let `self` = self else { return }
            self.allGR.forEach { $0.isEnabled = true }
            self.statusBar.setNewSquareIn(value: self.game.currentPlayer.turnsUntilNewSquare)
            self.statusBar.setCurrentTurn(value: self.game.currentPlayer.color)
            if destroyedSquarePositions.isNotEmpty {
                self.statusBar.setLives(players: self.game.players)
            }
            
            let closure: (Position) -> Position
            switch direction! {
            case .down:
                closure = {$0.below()}
            case .up:
                closure = {$0.above()}
            case .left:
                closure = {$0.left()}
            case .right:
                closure = {$0.right()}
            }
            for position in destroyedSquarePositions.map(closure) {
                self.boardView.viewWithTag(position.hashValue)!.removeFromSuperview()
            }
        }
    }
    
    func repositionViews(size: CGSize) {
        view.subviews.forEach { $0.removeFromSuperview() }
        let separator = 8.f
        let statusBarWeight = 13.f / 84.f
        if size.height > size.width {
            let statusBarHeight = (size.height - 7 * separator) * statusBarWeight
            let statusBarWidth = size.width  - 2 * separator
            statusBar = StatusBar(frame: CGRect(x: separator, y: separator * 3, width: statusBarWidth, height: statusBarHeight))
            view.addSubview(statusBar)
            self.statusBar.setNewSquareIn(value: self.game.currentPlayer.turnsUntilNewSquare)
            self.statusBar.setCurrentTurn(value: self.game.currentPlayer.color)
            self.statusBar.setLives(players: self.game.players)
            
            let heightLeft = size.height - (separator * 7 + statusBarHeight)
            let widthLeft = size.width - separator * 2
            let boardLength = min(heightLeft, widthLeft)
            let centerY = 6 * separator + statusBarHeight + heightLeft / 2
            let centerX = size.width / 2
            boardView = GameBoardView(frame: CGRect(origin: .zero, size: CGSize(width: boardLength, height: boardLength)))
            boardView.game = self.game
            boardView.center = CGPoint(x: centerX, y: centerY)
            boardView.backgroundColor = .clear
            view.addSubview(boardView)
        } else {
            let statusBarWidth = (size.width - 7 * separator) * statusBarWeight
            let statusBarHeight = size.height - 2 * separator
            statusBar = StatusBar(frame: CGRect(x: separator * 3, y: separator, width: statusBarWidth, height: statusBarHeight))
            (statusBar.subviews.first! as! UIStackView).axis = .vertical
            
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        repositionViews(size: size)
    }
}

