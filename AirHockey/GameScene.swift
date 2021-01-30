//
//  AirHockey
//
//  Created by Jeff George on 5/25/19.
//  Copyright © 2019 Geotech. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    var puck = SKSpriteNode()
    var rink = SKSpriteNode()
    var playerBlue = SKSpriteNode()
    var playerRed = SKSpriteNode()
    var goalBlue = SKSpriteNode()
    var goalRed = SKSpriteNode()
    var midline = SKSpriteNode()
    var scoreIndicator = SKLabelNode()
    var scoreBlue = SKLabelNode()
    var scoreRed = SKLabelNode()
    var touchBlue = UITouch()
    var touchRed = UITouch()
    var audioPlayer: AVAudioPlayer?

    static let playerBlueCategory: UInt32 = 0x01
    static let playerRedCategory: UInt32 =  0x02
    static let stickCategory: UInt32 =      0x04
    static let goalCategory: UInt32 =       0x08
    static let puckCategory: UInt32 =       0x10
    static let rinkCategory: UInt32 =       0x20
    
    var score = [Int]()
    
    override func didMove(to view: SKView) {
        setupRink()
        startGame()
        physicsWorld.contactDelegate = self
    }
  
    override func update(_ currentTime: TimeInterval) {
        if touchBlue.phase == UITouch.Phase.stationary || touchBlue.phase == UITouch.Phase.ended {
            movePlayer(playerBlue, touch: touchBlue)
        }
        
        if touchRed.phase == UITouch.Phase.stationary || touchRed.phase == UITouch.Phase.ended {
            movePlayer(playerRed, touch: touchRed)
        }
        slowThePuckDown(puck)
    }
    

    func setupRink() {        //Setup foundational components.  Should persist across games.
        self.scaleMode = .aspectFit
        
        rink = self.childNode(withName: "rink") as! SKSpriteNode
        rink.color = UIColor(named: "rinkColor")!
        rink.size = CGSize(width: frame.width - 40, height: frame.height - 60)
        rink.position = CGPoint(x: frame.midX, y: frame.midY)

        let rinkBoundary = SKPhysicsBody(edgeLoopFrom:rink.frame)
        rinkBoundary.friction = 0
        rinkBoundary.restitution = 1
        rinkBoundary.categoryBitMask = GameScene.rinkCategory
        rinkBoundary.collisionBitMask = GameScene.puckCategory | GameScene.stickCategory
        rinkBoundary.contactTestBitMask = GameScene.puckCategory
        self.physicsBody = rinkBoundary

        let middleCircle = SKShapeNode(circleOfRadius: 200 )
        middleCircle.position = CGPoint(x: frame.midX, y: frame.midY)  //Middle of Screen255
        middleCircle.strokeColor = SKColor(red: 255/255, green: 0, blue: 0, alpha: 1)
        middleCircle.glowWidth = 1.0
        self.addChild(middleCircle)
        
        scoreIndicator = self.childNode(withName: "ScoreIndicator") as! SKLabelNode
        scoreIndicator.position = CGPoint(x:frame.midX, y: frame.midY)
        scoreIndicator.isHidden = true
        
        scoreBlue = self.childNode(withName: "ScoreBlue") as! SKLabelNode
        scoreBlue.position = CGPoint(x:frame.maxX - 100, y: frame.midY - 100)

        scoreRed = self.childNode(withName: "ScoreRed") as! SKLabelNode
        scoreRed.position = CGPoint(x:frame.maxX - 100, y: frame.midY + 100)

        midline = self.childNode(withName: "midline") as! SKSpriteNode
        midline.size = CGSize(width: frame.size.width, height: 3)
        
        playerBlue = self.childNode(withName: "PlayerBlue") as! SKSpriteNode
        playerBlue.physicsBody?.categoryBitMask = GameScene.stickCategory
                                                    | GameScene.playerBlueCategory
        playerBlue.physicsBody?.collisionBitMask = GameScene.puckCategory
                                                    | GameScene.rinkCategory
                                                    | GameScene.stickCategory
        playerBlue.physicsBody?.contactTestBitMask = GameScene.puckCategory
        
        goalBlue = self.childNode(withName: "GoalBlue") as! SKSpriteNode
        goalBlue.size = CGSize(width: frame.size.width / 4, height: 30)
        goalBlue.position = CGPoint(x:frame.midX, y: frame.maxY - 20)
        goalBlue.physicsBody?.categoryBitMask = GameScene.goalCategory | GameScene.playerBlueCategory
        goalBlue.physicsBody?.collisionBitMask = GameScene.puckCategory
        goalBlue.physicsBody?.contactTestBitMask = GameScene.puckCategory
        
        playerRed = self.childNode(withName: "PlayerRed") as! SKSpriteNode
        playerRed.physicsBody?.categoryBitMask = GameScene.stickCategory | GameScene.playerRedCategory
        playerRed.physicsBody?.collisionBitMask = GameScene.puckCategory
                                                    | GameScene.rinkCategory
                                                    | GameScene.stickCategory
        playerRed.physicsBody?.contactTestBitMask = GameScene.puckCategory
        
        goalRed = self.childNode(withName: "GoalRed") as! SKSpriteNode
        goalRed.size = CGSize(width: frame.size.width / 4, height: 30)
        goalRed.position = CGPoint(x:frame.midX, y: frame.minY + 20)
        goalRed.physicsBody?.categoryBitMask = GameScene.goalCategory
                                            | GameScene.playerRedCategory
        goalRed.physicsBody?.collisionBitMask = GameScene.puckCategory
        goalRed.physicsBody?.contactTestBitMask = GameScene.puckCategory
        
        puck = self.childNode(withName: "Puck") as! SKSpriteNode
        puck.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        puck.physicsBody?.categoryBitMask = GameScene.puckCategory
        puck.physicsBody?.collisionBitMask = GameScene.stickCategory
                                            | GameScene.goalCategory
                                            | GameScene.rinkCategory
        puck.physicsBody?.contactTestBitMask = GameScene.stickCategory
                                            | GameScene.goalCategory
                                            | GameScene.rinkCategory
        
    }

    func startGame() {   // set up new game (on existing rink)
        score = [0,0]
        playerBlue.position = CGPoint(x:frame.midX, y: frame.minY + 100)
        playerRed.position = CGPoint(x:frame.midX, y: frame.maxY - 100)
        puck.position = CGPoint(x:frame.midX, y: frame.midY)
    }

    func movePlayer(_ player: SKSpriteNode, touch: UITouch) {
        let location = touch.location(in: self)
        let moveVector = CGVector(dx: 6 * (location.x - player.position.x) ,
                                  dy: 6 * (location.y - player.position.y))
        if abs(moveVector.dx) < 10 && abs(moveVector.dy) < 10 {
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)    // reduce shakiness
        }
        else {
            player.physicsBody?.velocity = moveVector
        }
    }

    func slowThePuckDown(_ puck: SKSpriteNode) {
        var dx = Int(puck.physicsBody!.velocity.dx)
        var dy = Int(puck.physicsBody!.velocity.dy)

        
        if (dx > 1500) {dx = 1500}
        if (dy > 1500) {dy = 1500}
        //self.scoreIndicator.text = "dx = \(dx) \ndy = \(dy)"
        puck.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch.location(in: self).y < frame.midY {
                touchBlue = touch
            } else if touch.location(in: self).y > frame.midY {
                touchRed = touch
            }
        }
    }
    
    func autoPlayerRedMove() {
        // add option for 1-player mode. 
        playerRed.run(SKAction.move(to: CGPoint(x: puck.position.x, y: frame.maxY - 50), duration: 1.0))
    }
    
    func someoneScored() {
        //self.scoreIndicator.isHidden = false
        self.scoreBlue.text = "\(score[0])"
        self.scoreRed.text = "\(score[1])"
    }
    
    func resetPositions(scoreBy: Int) {
        touchBlue = UITouch()
        touchRed = UITouch()
        //print(touchBlue)
        puck.physicsBody?.collisionBitMask = 0
        if scoreBy == 1 {
            puck.run(SKAction.move(to: CGPoint(x: self.frame.midX, y: self.frame.maxY - 400),
                                   duration: 1.0))
        }
        else if scoreBy == 2 {
            puck.run(SKAction.move(to: CGPoint(x: self.frame.midX, y: self.frame.minY + 400),
                                   duration: 1.0))
        }
        puck.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        playerBlue.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        playerBlue.run(SKAction.move(to: CGPoint(x: self.frame.midX-400, y: self.frame.minY + 400),
                               duration: 1.0))
        playerRed.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        playerRed.run(SKAction.move(to: CGPoint(x: self.frame.midX-400, y: self.frame.maxY - 400),
                                duration: 1.0))
        
        puck.physicsBody?.collisionBitMask = GameScene.stickCategory
            | GameScene.goalCategory
            | GameScene.rinkCategory
    }

    func playSound(soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // For iOS 11
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let aPlayer = audioPlayer else { return }
            aPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if contactMask & GameScene.stickCategory == GameScene.stickCategory {
            playSound(soundName: "Click")
        }
        
        if contactMask & GameScene.rinkCategory == GameScene.rinkCategory {
            playSound(soundName: "Click")
        }

        if contactMask & GameScene.goalCategory == GameScene.goalCategory {
            
            playSound(soundName: "crowd")
            
            if contactMask & GameScene.playerRedCategory == GameScene.playerRedCategory {
                score[1] += 1
                resetPositions(scoreBy: 2)
            }
            else if contactMask & GameScene.playerBlueCategory == GameScene.playerBlueCategory{
                score[0] += 1
                resetPositions(scoreBy: 1)
            }
            someoneScored()
        }
    }
}
