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
    
    var tapGR: UITapGestureRecognizer!
    
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
        tapGR = UITapGestureRecognizer(target: self, action: #selector(showHideActionBar))
        swipeUpGR.direction = .up
        swipeDownGR.direction = .down
        swipeLeftGR.direction = .left
        swipeRightGR.direction = .right
        
        allGR.forEach { self.view.addGestureRecognizer($0) }
        self.view.addGestureRecognizer(tapGR)
        
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
            view.addSubview(statusBar)
            self.statusBar.setNewSquareIn(value: self.game.currentPlayer.turnsUntilNewSquare)
            self.statusBar.setCurrentTurn(value: self.game.currentPlayer.color)
            self.statusBar.setLives(players: self.game.players)
            
            let widthLeft = size.width - (separator * 7 + statusBarWidth)
            let heightLeft = size.height - separator * 2
            let boardLength = min(heightLeft, widthLeft)
            let centerX = 6 * separator + statusBarWidth + widthLeft / 2
            let centerY = size.height / 2
            boardView = GameBoardView(frame: CGRect(origin: .zero, size: CGSize(width: boardLength, height: boardLength)))
            boardView.game = self.game
            boardView.center = CGPoint(x: centerX, y: centerY)
            boardView.backgroundColor = .clear
            view.addSubview(boardView)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        repositionViews(size: size)
    }
    
    func showHideActionBar() {
        func imageToFitButtonFrame(image: UIImage, size: CGSize) -> UIImage {
            let size = image.size
            
            let widthRatio  = pow((size.width * 0.1)  / image.size.width, -1)
            let heightRatio = pow((size.height * 0.1) / image.size.height, -1)
            
            // Figure out what our orientation is, and use that to form the rectangle
            var newSize: CGSize
            if(widthRatio > heightRatio) {
                newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            } else {
                newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
            }
            
            // This is the rect that we've calculated out and this is what is actually used below
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            
            // Actually do the resizing to the rect using the ImageContext stuff
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }
        
        if let quitButton = self.view.viewWithTag(1), let restartButton = self.view.viewWithTag(2) {
            UIView.animate(withDuration: SquareView.animDuration, animations: {
                quitButton.alpha = 0
                restartButton.alpha = 0
            }, completion: {
                if $0 {
                    restartButton.removeFromSuperview()
                    quitButton.removeFromSuperview()
                }
            })
        } else {
            let actionBarButtonLength = min(self.view.width, self.view.height) / 8
            let actionBarYWeight = 0.7.f
            let separatorLength = self.view.width / 3
            let actionBarY = self.view.height * actionBarYWeight
            let actionBarX = self.view.width / 2 - separatorLength / 2 - actionBarButtonLength
            let quitImage = imageToFitButtonFrame(image: #imageLiteral(resourceName: "quit"), size: CGSize(width: actionBarButtonLength, height: actionBarButtonLength))
            let quitButton = NGORoundedButton(buttonCustomImage: quitImage, andShape: .circle)!
            quitButton.frame = CGRect(x: actionBarX, y: actionBarY, width: actionBarButtonLength, height: actionBarButtonLength)
            quitButton.alpha = 0
            quitButton.tag = 1
            quitButton.addTarget(self, action: #selector(quitTapped), for: .touchUpInside)
            let restartImage = imageToFitButtonFrame(image: #imageLiteral(resourceName: "restart"), size: CGSize(width: actionBarButtonLength, height: actionBarButtonLength))
            let restartButton = NGORoundedButton(buttonCustomImage: restartImage, andShape: .circle)!
            restartButton.frame = CGRect(x: actionBarX + actionBarButtonLength + separatorLength, y: actionBarY, width: actionBarButtonLength, height: actionBarButtonLength)
            restartButton.alpha = 0
            restartButton.tag = 2
            restartButton.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)
            self.view.addSubview(restartButton)
            self.view.addSubview(quitButton)
        }
    }
}

