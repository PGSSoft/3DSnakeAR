//
//  GameController.swift
//  3DSnake
//
//  Created by Michal Kowalski on 19.07.2017.
//  Copyright © 2017 PGS Software. All rights reserved.
//

import SceneKit

protocol GameControllerDelegate: class {
    func gameOver(sender: GameController)
}

final class GameController {
    private let sceneSize = 15
    private var timer: Timer!

    // MARK: - Properties Nodes
    public var worldSceneNode: SCNNode?
    private var pointsNode: SCNNode?
    private var pointsText: SCNText?

    // MARK: - Properties model
    var snake: Snake = Snake()

    private var points: Int = 0
    private var mushroomNode: Mushroom
    private var mushroomPos: int2 = int2(0, 0)
    private var gameOver: Bool = false

    weak var delegate: GameControllerDelegate?

    init() {
        if let worldScene = SCNScene(named: "worldScene.scn") {
            worldSceneNode = worldScene.rootNode.childNode(withName: "worldScene", recursively: true)
            worldSceneNode?.removeFromParentNode()
            worldSceneNode?.addChildNode(snake)
            pointsNode = worldSceneNode?.childNode(withName: "pointsText", recursively: true)
            pointsNode?.pivot = SCNMatrix4MakeTranslation(5, 0, 0)
            pointsText = pointsNode?.geometry as? SCNText
        }
        mushroomNode = Mushroom()
    }

    // MARK: - Game Lifecycle
    func reset() {
        gameOver = false
        points = 0
        snake.reset()
        worldSceneNode?.addChildNode(mushroomNode)
        placeMushroom()
    }

    func startGame() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateSnake), userInfo: nil, repeats: true)
        let rotateAction = SCNAction.rotate(by: CGFloat.pi * 2, around: SCNVector3(0, 1, 0), duration: 10.0)
        pointsNode?.runAction(SCNAction.repeatForever(rotateAction))
    }

    // MARK: - Actions
    @objc func updateSnake(timer: Timer) {
        if snake.canMove(sceneSize: sceneSize) {
            snake.move()
            if snake.ateItself || !snake.canMove(sceneSize: sceneSize) {
                gameOver = true
                snake.runCrashAnimation()
                delegate?.gameOver(sender: self)
                timer.invalidate()
            }
            if snake.headPos == mushroomPos {
                snake.grow()
                placeMushroom()
            }
        } else {
            snake.runCrashAnimation()
            delegate?.gameOver(sender: self)
        }
        updatePoints(points: "\(snake.body.count - 4)")
    }

    func turnRight() {
        snake.turnRight()
    }

    func turnLeft() {
        snake.turnLeft()
    }

    func addToNode(rootNode: SCNNode) {
        guard let worldScene = worldSceneNode else {
            return
        }
        worldScene.removeFromParentNode()
        rootNode.addChildNode(worldScene)
        worldScene.scale = SCNVector3(0.1, 0.1, 0.1)
    }

    // MARK: - Helpers
    private func updatePoints(points: String) {
        guard let pointsNode = pointsNode else {
            return
        }
        pointsText?.string = points
        let width = pointsNode.boundingBox.max.x - pointsNode.boundingBox.min.x
        pointsNode.pivot = SCNMatrix4MakeTranslation(width / 2, 0, 0)
        pointsNode.position.x = -width / 2
    }

    private func placeMushroom() {
        repeat {
            let x = Int32(arc4random() % UInt32((sceneSize - 1))) - 7
            let y = Int32(arc4random() % UInt32((sceneSize - 1))) - 7
            mushroomPos = int2(x, y)
        } while snake.body.contains(mushroomPos)

        mushroomNode.position = SCNVector3(Float(mushroomPos.x), 0, Float(mushroomPos.y))
        mushroomNode.runAppearAnimation()
    }
}
