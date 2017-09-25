//
//  ViewController.swift
//  3DSnakeAR
//
//  Created by Michal Kowalski on 18.07.2017.
//  Copyright © 2017 PGS Software. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

final class ViewController: UIViewController, ARSCNViewDelegate {

    enum ViewState {
        case searchPlanes
        case selectPlane
        case startGame
        case playing
    }

    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var hintView: UIView!
    @IBOutlet weak var hintLabel: UILabel!

    var state: ViewState = .searchPlanes {
        didSet {
            updateHintView()
            if state == .playing {
                planes.values.forEach { plane in
                    plane.isHidden = true
                }
            } else {
                planes.values.forEach { plane in
                    plane.isHidden = true
                }
            }
        }
    }

    var gameController: GameController = GameController()

    var planes: [ARAnchor: HorizontalPlane] = [:]
    var selectedPlane: HorizontalPlane?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Create a new scene
        let scene = SCNScene(named: "arscene.scn")!

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: -1, y: 10, z: 1)
        scene.rootNode.addChildNode(lightNode)

        // Set the scene to the view
        sceneView.scene = scene

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft(_:)))
        swipeLeft.direction = .left
        sceneView.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight(_:)))
        swipeRight.direction = .right
        sceneView.addGestureRecognizer(swipeRight)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        gameController.delegate = self
    }

    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])

        if hitResults.count > 0 {
            if let result = hitResults.first, let selectedPlane = result.node as? HorizontalPlane {
                self.selectedPlane = selectedPlane
                state = .startGame
                gameController.addToNode(rootNode: selectedPlane.parent!)
                gameController.updateGameSceneForAnchor(anchor: selectedPlane.anchor)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
        state = .searchPlanes
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard state == .searchPlanes || state == .selectPlane else {
            return
        }

        if let anchor = anchor as? ARPlaneAnchor {
            if state == .searchPlanes {
                state = .selectPlane
            }
            let plane = HorizontalPlane(anchor: anchor)
            planes[anchor] = plane
            node.addChildNode(plane)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let anchor = anchor as? ARPlaneAnchor,
            let plane = planes[anchor] {
                plane.update(for: anchor)
                if selectedPlane?.anchor == anchor {
                    gameController.updateGameSceneForAnchor(anchor: anchor)
                }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            if plane == self.selectedPlane {
                let nextPlane = planes.values.first!
                gameController.addToNode(rootNode: nextPlane)
                gameController.updateGameSceneForAnchor(anchor: nextPlane.anchor)
            }
            plane.removeFromParentNode()
        }
    }

    func updateHintView() {
        DispatchQueue.main.async {
            switch self.state {
            case .searchPlanes:
                self.hintView.isHidden = false
                self.hintLabel.isHidden = false
                self.startGameButton.isHidden = true
                self.hintLabel.text = "Move device to find a plane"
            case .selectPlane:
                self.hintView.isHidden = false
                self.hintLabel.isHidden = false
                self.startGameButton.isHidden = true
                self.hintLabel.text = "Select plane"
            case .startGame:
                self.hintView.isHidden = false
                self.hintLabel.isHidden = true
                self.startGameButton.isHidden = false
                self.hintLabel.text = ""
            case .playing:
                self.startGameButton.isHidden = true
                self.hintView.isHidden = true
            }
        }
    }

    @IBAction func startButtonTouched(_ sender: Any) {
        state = .playing
        gameController.reset()
        gameController.startGame()
    }

    @objc func swipeLeft(_ sender: Any) {
        gameController.turnLeft()
    }

    @objc func swipeRight(_ sender: Any) {
        gameController.turnRight()
    }
}

extension ViewController: GameControllerDelegate {
    func gameOver(sender: GameController) {
        state = .startGame
    }
}

extension GameController {
    func updateGameSceneForAnchor(anchor: ARPlaneAnchor) {
        let worldSize: Float = 20.0
        let minSize = min(anchor.extent.x, anchor.extent.z)
        let scale = minSize / worldSize
        worldSceneNode?.scale = SCNVector3(x: scale, y: scale, z: scale)
        worldSceneNode?.position = SCNVector3(anchor.center)
    }
}
