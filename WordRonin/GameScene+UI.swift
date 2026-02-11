//
//  GameScene+UI.swift
//  slicenspell
//
//  Created by Jad Aoun on 2/11/26.
//

import SpriteKit

extension GameScene {
    
    // MARK: - Layout Tuning
    func effectiveRightPadding() -> CGFloat { max(24, safeInsets.right + 120) }
    func effectiveTopPadding() -> CGFloat { max(32, safeInsets.top + 32) }

    // MARK: - Background
    func ensureBackground(named imageName: String) {
        if let bg = childNode(withName: "//\(backgroundNodeName)") as? SKSpriteNode {
            bg.texture = SKTexture(imageNamed: imageName)
            bg.name = backgroundNodeName
            bg.zPosition = -1
            bg.blendMode = .replace
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            resizeBackground()
            return
        }

        let background = SKSpriteNode(imageNamed: imageName)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.blendMode = .replace
        background.zPosition = -1
        background.name = backgroundNodeName
        addChild(background)
        resizeBackground()
    }

    func resizeBackground() {
        guard let bg = childNode(withName: "//\(backgroundNodeName)") as? SKSpriteNode else { return }
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        if let tex = bg.texture {
            let xScale = size.width / tex.size().width
            let yScale = size.height / tex.size().height
            let scale = max(xScale, yScale)
            bg.xScale = scale
            bg.yScale = scale
        }
    }

    func setMenuBackground() { ensureBackground(named: GameConfig.Assets.menuBackground) }
    func setInGameBackground() { ensureBackground(named: GameConfig.Assets.inGameBackground) }

    // MARK: - HUD
    func createScoreHUD() {
        scoreHud?.removeFromParent()
        let container = SKNode()
        container.zPosition = GameConfig.HUD.zPosition
        addChild(container)
        scoreHud = container

        let bg = SKSpriteNode(imageNamed: GameConfig.Assets.buttonBamboo)
        bg.name = "scoreHudBg"
        bg.size = GameConfig.HUD.bambooSize
        bg.zPosition = GameConfig.HUD.zPosition
        bg.alpha = 0.95
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Score: 0"
        label.fontSize = 30
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = GameConfig.HUD.textZPosition
        container.addChild(label)

        gameScore = label
        positionHUD()
    }

    func createTimerHUD() {
        timerHud?.removeFromParent()
        let container = SKNode()
        container.zPosition = GameConfig.HUD.zPosition
        addChild(container)
        timerHud = container

        let bg = SKSpriteNode(imageNamed: GameConfig.Assets.buttonBamboo)
        bg.name = "timerHudBg"
        bg.size = GameConfig.HUD.bambooSize
        bg.zPosition = GameConfig.HUD.zPosition
        bg.alpha = 0.95
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = ""
        label.fontSize = 30
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = GameConfig.HUD.textZPosition + 1
        container.addChild(label)

        timerLabel = label

        let dict = NSMutableDictionary()
        label.userData = dict

        positionHUD()
    }

    func positionHUD() {
        let topPad = effectiveTopPadding()
        let rightPad = effectiveRightPadding()

        if let scoreHud {
            scoreHud.position = CGPoint(x: size.width * 0.5, y: size.height - topPad)
        }

        if let timerHud {
            timerHud.position = CGPoint(
                x: size.width - rightPad - GameConfig.HUD.bambooSize.width * 0.10,
                y: size.height - topPad
            )
        }
    }
    
    func createCurrentWordLabel() {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = ""
        label.fontSize = 40
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height - effectiveTopPadding() - 80)
        label.zPosition = 100
        addChild(label)
        currentWordLabel = label
    }

    func positionTopLabels() {
        currentWordLabel?.position = CGPoint(x: size.width / 2, y: size.height - effectiveTopPadding() - 80)
    }

    // MARK: - Button Helpers
    func makeBambooButton(title: String, name: String, position: CGPoint, size: CGSize = CGSize(width: 360, height: 92), fontSize: CGFloat = 30) -> SKNode {
        let container = SKNode()
        container.name = name
        container.position = position
        container.zPosition = 1001

        let bg = SKSpriteNode(imageNamed: GameConfig.Assets.buttonBamboo)
        bg.size = size
        bg.zPosition = 0
        bg.name = name
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = title
        label.fontSize = fontSize
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -2)
        label.zPosition = 1
        label.name = name
        container.addChild(label)

        return container
    }

    func makeImageButton(imageName: String, name: String, position: CGPoint, maxWidth: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = name
        container.position = position
        container.zPosition = 1001

        let sprite = SKSpriteNode(imageNamed: imageName)
        sprite.name = name
        sprite.zPosition = 0
        let texSize = sprite.texture?.size() ?? CGSize(width: 1, height: 1)
        let scale = maxWidth / max(1, texSize.width)
        sprite.setScale(scale)
        container.addChild(sprite)

        return container
    }

    func addTopLeftBackImageButton(to parent: SKNode, name: String) {
        let maxW = min(220, size.width * 0.12)
        let btn = makeImageButton(
            imageName: GameConfig.Assets.backButton,
            name: name,
            position: .zero,
            maxWidth: maxW
        )
        let sprite = btn.children.compactMap { $0 as? SKSpriteNode }.first
        let w = sprite?.size.width ?? maxW
        let h = sprite?.size.height ?? (maxW * 0.5)
        let left = max(18, safeInsets.left + 18)
        let top = max(18, safeInsets.top + 18)

        btn.position = CGPoint(
            x: left + w * 0.5,
            y: size.height - top - h * 0.5
        )
        parent.addChild(btn)
    }

    func showInGameBackButton() {
        inGameBackButton?.removeFromParent()
        let maxW = min(220, size.width * 0.12)
        let btn = makeImageButton(
            imageName: GameConfig.Assets.backButton,
            name: GameConfig.ButtonNames.inGameBack,
            position: .zero,
            maxWidth: maxW
        )
        let sprite = btn.children.compactMap { $0 as? SKSpriteNode }.first
        let w = sprite?.size.width ?? maxW
        let h = sprite?.size.height ?? (maxW * 0.5)
        let left = max(18, safeInsets.left + 18)
        let top = max(18, safeInsets.top + 18)

        btn.position = CGPoint(
            x: left + w * 0.5,
            y: size.height - top - h * 0.5
        )
        btn.zPosition = 1500
        addChild(btn)
        inGameBackButton = btn
    }

    func hideInGameBackButton() {
        inGameBackButton?.removeFromParent()
        inGameBackButton = nil
    }
}
