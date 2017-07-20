//
//  Mushroom.swift
//  3DSnake
//
//  Created by Michal Kowalski on 20.07.2017.
//  Copyright © 2017 PGS Software. All rights reserved.
//

import SceneKit

final class Mushroom: SCNNode {

    var mushroomNode: SCNNode?

    // MARK: - Lifecycle
    override init() {
        super.init()
        if let scene = SCNScene(named: "mushroom.scn"), let mushroomNode = scene.rootNode.childNode(withName: "mushroom", recursively: true) {
            addChildNode(mushroomNode)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    //MARK - Animations
    func runAppearAnimation() {
        mushroomNode?.position.y = -1
        removeAllActions()
        removeAllParticleSystems()
        scale = SCNVector3(0.1, 0.1, 0.1)
        addParticleSystem(SCNParticleSystem(named: "mushroom-appear", inDirectory: nil)!)
        let scaleAction = SCNAction.scale(to: 1.0, duration: 1.0)
        let removeParticle = SCNAction.run { _ in
            self.removeAllParticleSystems()
        }
        let sequence = SCNAction.sequence([scaleAction, removeParticle])
        runAction(sequence)
    }
}
