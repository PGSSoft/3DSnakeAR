//
//  Snake.swift
//  3DSnake
//
//  Created by Michal Kowalski on 18.07.2017.
//  Copyright © 2017 PGS Software. All rights reserved.
//

import SceneKit

enum SnakeDirection: Int {
    case up
    case right
    case down
    case left

    var asInt2: int2 {
        switch self {
        case .up:
            return int2(x: 0, y: 1)
        case .right:
            return int2(x: 1, y: 0)
        case .down:
            return int2(x: 0, y: -1)
        case .left:
            return int2(x: -1, y: 0)
        }
    }
}

final class SnakeSegmentNode: SCNNode {
    enum SegmentType: Int {
        case head
        case body
        case tail
    }

    let type: SegmentType

    init(pos: int2, type: SegmentType = .body) {
        self.type = type
        super.init()
        switch type {
        case .body:
            if let scene = SCNScene(named: "snakeBody.scn") {
                if let snakeBody = scene.rootNode.childNode(withName: "snakeBody", recursively: true) {
                    addChildNode(snakeBody)
                }
            }
        case .tail:
            if let scene = SCNScene(named: "snakeTail.scn") {
                if let snakeTail = scene.rootNode.childNode(withName: "snakeTail", recursively: true) {
                    addChildNode(snakeTail)
                }
            }
        case .head:
            if let scene = SCNScene(named: "snakeHead.scn") {
                if let snakeHead = scene.rootNode.childNode(withName: "snakeHead", recursively: true) {
                    addChildNode(snakeHead)
                }
            }
        }
        position = SCNVector3(Float(pos.x), Float(0.5), Float(pos.y))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

final class Snake: SCNNode {
    // MARK: - Properties
    var direction: SnakeDirection = .down

    var headPos: int2 {
        return body.first!
    }

    var body: [int2] = [int2(0, 0), int2(0, 1), int2(0, 2)]
    var lastBodySegment: int2?
    var nodes: [SnakeSegmentNode] = []

    // MARK: - Lifecycle
    override init() {
        super.init()
        reset()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func reset() {
        direction = .down
        body = [int2(0, 0), int2(0, 1), int2(0, 2), int2(0, 3)]

        nodes.forEach {
            $0.removeFromParentNode()
        }

        nodes = []

        for i in body {
            if i == body.first {
                nodes += [SnakeSegmentNode(pos: i, type: .head)]
            } else if i == body.last {
                nodes += [SnakeSegmentNode(pos: i, type: .tail)]
            } else {
                nodes += [SnakeSegmentNode(pos: i)]
            }
        }

        nodes.forEach { (node) in
            addChildNode(node)
        }

        updateNodes()
    }

    // MARK: - Interaction methods
    func turnLeft() {
        let t = (direction.rawValue + 1) % 4
        direction = SnakeDirection(rawValue: t)!
    }

    func turnRight() {
        let t = (direction.rawValue - 1 + 4) % 4
        direction = SnakeDirection(rawValue: t)!
    }

    func move() {
        let p = body.first!
        var newBody = [int2(x: p.x + direction.asInt2.x, y: p.y + direction.asInt2.y)]
        lastBodySegment = body.removeLast()
        newBody.append(contentsOf: body)
        body = newBody
        updateNodes()
    }

    func canMove(sceneSize: Int) -> Bool {
        let maxPos = Int(sceneSize / 2)
        return abs(headPos.x) <= maxPos && abs(headPos.y) <= maxPos
    }

    var ateItself: Bool {
        for (i, pos) in body.enumerated() {
            if pos == body.first! && i > 0 {
                return true
            }
        }
        return false
    }

    func grow() {
        guard let lastBodySegment = lastBodySegment else {
            return
        }
        body += [lastBodySegment]
        let newNode = SnakeSegmentNode(pos: lastBodySegment)
        addChildNode(newNode)
        nodes += [newNode]
        self.lastBodySegment = nil
        updateNodes()
    }

    // MARK: - SceneKit methods
    func updateNodes() {
        nodes = nodes.sorted {
            return $0.type.rawValue < $1.type.rawValue
        }
        for (i, node) in nodes.enumerated() {
            let pos = body[i]
            node.position = SCNVector3(Float(pos.x), Float(0.5), Float(pos.y))
        }
        updateHeadNode()
        updateTailNode()
    }

    fileprivate func updateHeadNode() {
        if let headNode = nodes.first {
            switch direction {
            case .right:
                headNode.eulerAngles.y = Float.pi / 2
            case .left:
                headNode.eulerAngles.y = -Float.pi / 2
            case .up:
                headNode.eulerAngles.y = 0
            case .down:
                headNode.eulerAngles.y = -Float.pi
            }
        }
    }

    fileprivate func updateTailNode() {
        if let tailNode = nodes.last, let tailPos = body.last {
            let beforeTailPos = body[body.count - 2]
            let dV = int2(beforeTailPos.x - tailPos.x, beforeTailPos.y - tailPos.y)
            if dV.x == 1 {
                tailNode.eulerAngles.y = Float.pi / 2
            } else if dV.x == -1 {
                tailNode.eulerAngles.y = -Float.pi / 2
            }

            if dV.y == 1 {
                tailNode.eulerAngles.y = 0
            } else if dV.y == -1 {
                tailNode.eulerAngles.y = Float.pi
            }
        }
    }

    func runCrashAnimation() {
        if let headNode = nodes.first,
            let particle = SCNParticleSystem(named: "crashed-snake", inDirectory: nil) {
                headNode.addParticleSystem(particle)
        }
    }
}
