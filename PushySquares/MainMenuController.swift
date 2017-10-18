import UIKit
import SwiftyButton

class MainMenuController: UIViewController {
    @IBOutlet var logo: UIImageView!
    
    var viewsToBeRepositioned: [UIView] = []
    
    func repositionViews() {
        viewsToBeRepositioned.forEach { $0.removeFromSuperview() }
        viewsToBeRepositioned = []
        
        let startButtonY = 36 + logo.frame.maxY
        let startButtonWidth: CGFloat
        if traitCollection.horizontalSizeClass == .regular {
            startButtonWidth = view.width / 2
        } else {
            startButtonWidth = view.width * 0.8
        }
        let startButtonX = (view.width - startButtonWidth) / 2
        
        let startButton = PressableButton(frame:
            CGRect.zero
            .with(width: startButtonWidth)
            .with(x: startButtonX)
            .with(y: startButtonY)
            .with(height: view.height / 10))
        let fontSize = fontSizeThatFits(size: startButton.frame.size, text: "START", font: UIFont(name: "Chalkboard SE", size: 0)!) * 0.7
        startButton.setAttributedTitle(
            NSAttributedString(string: "START", attributes: [
                NSFontAttributeName: UIFont(name: "Chalkboard SE", size: fontSize)!,
                NSForegroundColorAttributeName: UIColor.white
                ])
            , for: .normal)
        startButton.colors = PressableButton.ColorSet(button: UIColor.green.desaturated().darker(), shadow: UIColor.green.desaturated().darker().darker())
        startButton.shadowHeight = startButton.height * 0.1
        
        let helpButton = PressableButton(frame:
            startButton.frame
                .with(y: startButton.frame.maxY + startButton.height * 0.2))
        helpButton.setAttributedTitle(
            NSAttributedString(string: "HELP", attributes: [
                NSFontAttributeName: UIFont(name: "Chalkboard SE", size: fontSize)!,
                NSForegroundColorAttributeName: UIColor.white
                ])
            , for: .normal)
        helpButton.colors = PressableButton.ColorSet(button: UIColor.blue.desaturated(), shadow: UIColor.blue.desaturated().darker())
        helpButton.shadowHeight = helpButton.height * 0.1
        
        let hostButton = PressableButton(frame: helpButton.frame.with(y: helpButton.frame.maxY + helpButton.height * 0.2))
        hostButton.setAttributedTitle(
            NSAttributedString(string: "HOST", attributes: [
                NSFontAttributeName: UIFont(name: "Chalkboard SE", size: fontSize)!,
                NSForegroundColorAttributeName: UIColor.white
                ])
            , for: .normal)
        hostButton.colors = PressableButton.ColorSet(button: UIColor.red.desaturated(), shadow: UIColor.red.desaturated().darker())
        hostButton.shadowHeight = helpButton.height * 0.1
        
        let joinButton = PressableButton(frame: hostButton.frame.with(y: hostButton.frame.maxY + hostButton.height * 0.2))
        joinButton.setAttributedTitle(
            NSAttributedString(string: "JOIN", attributes: [
                NSFontAttributeName: UIFont(name: "Chalkboard SE", size: fontSize)!,
                NSForegroundColorAttributeName: UIColor.white
                ])
            , for: .normal)
        joinButton.colors = PressableButton.ColorSet(button: UIColor.yellow.darker().desaturated(), shadow: UIColor.yellow.darker().desaturated().darker())
        joinButton.shadowHeight = hostButton.height * 0.1
        
        viewsToBeRepositioned.append(startButton)
        viewsToBeRepositioned.append(helpButton)
        view.addSubview(startButton)
        view.addSubview(helpButton)
        
        startButton.addTarget(self, action: #selector(startPressed), for: .touchUpInside)
        helpButton.addTarget(self, action: #selector(helpPressed), for: .touchUpInside)
    }
    
    func startPressed() {
        performSegue(withIdentifier: "showPlayerCountSelector", sender: self)
    }
    
    func helpPressed() {
        performSegue(withIdentifier: "showHelp", sender: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        repositionViews()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.repositionViews()
        }
    }
    
    @IBAction func unwindFromGame(segue: UIStoryboardSegue) {
        
    }
}
