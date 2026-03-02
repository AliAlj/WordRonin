// GameScene+UI.swift
import SpriteKit
import UIKit

extension GameScene {

    // MARK: - Layout Helpers

    func effectiveTopPadding() -> CGFloat {
        max(32, safeInsets.top + 32)
    }

    func effectiveRightPadding() -> CGFloat {
        max(16, safeInsets.right + 16)
    }

    func effectiveLeftPadding() -> CGFloat {
        max(16, safeInsets.left + 16)
    }

    // MARK: - Background

    func ensureBackground(named imageName: String) {
        if let bg = childNode(withName: "//\(backgroundNodeName)") as? SKSpriteNode {
            bg.texture = SKTexture(imageNamed: imageName)
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
            bg.xScale = max(xScale, yScale)
            bg.yScale = max(xScale, yScale)
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

        // Pill-shaped background — fully controllable size, no image stretching
        let pill = hudPill(size: GameConfig.HUD.bambooSize)
        container.addChild(pill)

        let label = SKLabelNode(fontNamed: "SF Pro Rounded")
        label.text = "Score: 0"
        label.fontSize = GameConfig.HUD.fontSize
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

        // Pill-shaped background
        let pill = hudPill(size: GameConfig.HUD.bambooSize)
        container.addChild(pill)

        let label = SKLabelNode(fontNamed: "SF Pro Rounded")
        label.text = ""
        label.fontSize = GameConfig.HUD.fontSize
        label.fontColor = UIColor(red: 0.95, green: 1.0, blue: 0.85, alpha: 1)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = GameConfig.HUD.textZPosition + 1
        container.addChild(label)
        timerLabel = label
        label.userData = NSMutableDictionary()

        positionHUD()
    }

    /// Creates a rounded-rectangle pill — black background with white border.
    private func hudPill(size: CGSize) -> SKShapeNode {
        let radius = size.height * 0.44
        let rect   = CGRect(x: -size.width / 2, y: -size.height / 2,
                            width: size.width, height: size.height)
        let path   = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        let shape  = SKShapeNode(path: path.cgPath)
        shape.fillColor   = UIColor(white: 0, alpha: 0.78)
        shape.strokeColor = UIColor(white: 1, alpha: 0.30)
        shape.lineWidth   = 2
        shape.zPosition   = GameConfig.HUD.zPosition
        return shape
    }

    /// Score centred in the right-of-back-button region, Timer top-right.
    func positionHUD() {
        let bambooH = GameConfig.HUD.bambooSize.height
        let bambooW = GameConfig.HUD.bambooSize.width
        let y = size.height - safeInsets.top - bambooH * 0.5 - 6

        if let scoreHud {
            // Centre between left-third and right edge (avoids back button)
            let leftClear = safeInsets.left
            let availW    = size.width - leftClear - safeInsets.right
            scoreHud.position = CGPoint(x: leftClear + availW / 2, y: y)
        }
        if let timerHud {
            let x = size.width - safeInsets.right - bambooW * 0.5 - 8
            timerHud.position = CGPoint(x: x, y: y)
        }
    }

    // MARK: - Current Word Label (hidden; accessibility + debug)

    func createCurrentWordLabel() {
        let label = SKLabelNode(fontNamed: "SF Pro Rounded")
        label.text = ""
        label.fontSize = 32
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2,
                                 y: size.height - effectiveTopPadding() - 60)
        label.zPosition = 100
        label.alpha = 0.0   // visually hidden; bamboo bar is the visual representation
        addChild(label)
        currentWordLabel = label
    }

    func positionTopLabels() {
        currentWordLabel?.position = CGPoint(x: size.width / 2,
                                             y: size.height - effectiveTopPadding() - 60)
    }

    // MARK: - Word Build Bar

    func createWordBuildBar() {
        wordBuildBar?.removeFromParent()
        let bar = SKNode()
        bar.name = "wordBuildBar"
        bar.zPosition = 140
        addChild(bar)
        wordBuildBar = bar
        lastBuiltCount = 0
        positionWordBuildBar()
    }

    func positionWordBuildBar() {
        guard let bar = wordBuildBar else { return }
        // Sits just below the HUD row, near the top
        let hudH = GameConfig.HUD.bambooSize.height
        let y    = size.height - safeInsets.top - hudH - (Adaptive.isPad ? 60 : 48)
        bar.position = CGPoint(x: size.width / 2, y: y)
    }

    func updateWordBuildBar(animated: Bool) {
        guard let bar = wordBuildBar else { return }
        let word    = buildSelectedWord()
        let letters = Array(word)
        bar.removeAllChildren()
        lastBuiltCount = letters.count
        guard !letters.isEmpty else { return }

        let segSide  = min(GameConfig.WordBar.segmentSide, size.width / CGFloat(max(letters.count, 1)) * 0.85)
        let overlap  = segSide * GameConfig.WordBar.overlapFraction
        let totalW   = CGFloat(letters.count) * segSide - CGFloat(max(0, letters.count - 1)) * overlap
        let startX   = -totalW / 2 + segSide / 2

        for (i, ch) in letters.enumerated() {
            let segment = SKNode()

            let bamboo = SKSpriteNode(imageNamed: GameConfig.Assets.bambooImage)
            bamboo.size = CGSize(width: segSide, height: segSide)
            bamboo.alpha = 0.65
            segment.addChild(bamboo)

            let label = SKLabelNode(fontNamed: "SF Pro Rounded")
            label.text = String(ch)
            label.fontSize = segSide * 0.48
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: -segSide * 0.10, y: -segSide * 0.04)
            label.zPosition = 1
            segment.addChild(label)

            segment.position = CGPoint(x: startX + CGFloat(i) * (segSide - overlap), y: 0)

            if animated && i == letters.count - 1 {
                segment.setScale(0.2)
                segment.alpha = 0.0
                let pop    = SKAction.group([.fadeIn(withDuration: 0.06), .scale(to: 1.08, duration: 0.08)])
                pop.timingMode = .easeOut
                let settle = SKAction.scale(to: 1.0, duration: 0.06)
                settle.timingMode = .easeInEaseOut
                segment.run(SKAction.sequence([pop, settle]))
            }
            bar.addChild(segment)
        }
    }

    // MARK: - Button Factories

    func makeBambooButton(title: String,
                          name: String,
                          position: CGPoint,
                          size: CGSize = CGSize(width: 360, height: 92),
                          fontSize: CGFloat = 28) -> SKNode {
        let container = SKNode()
        container.name = name
        container.position = position
        container.zPosition = 1001

        let bg = SKSpriteNode(imageNamed: GameConfig.Assets.buttonBamboo)
        bg.size = size
        bg.zPosition = 0
        bg.name = name
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "SF Pro Rounded")
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

    func makeImageButton(imageName: String,
                         name: String,
                         position: CGPoint,
                         maxWidth: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = name
        container.position = position
        container.zPosition = 1001

        let sprite = SKSpriteNode(imageNamed: imageName)
        sprite.name = name
        sprite.zPosition = 0
        let texSize = sprite.texture?.size() ?? CGSize(width: 1, height: 1)
        sprite.setScale(maxWidth / max(1, texSize.width))
        container.addChild(sprite)
        return container
    }

    func addTopLeftBackImageButton(to parent: SKNode, name: String) {
        let maxW = backButtonWidth()
        let btn = makeImageButton(imageName: GameConfig.Assets.backButton,
                                  name: name,
                                  position: .zero,
                                  maxWidth: maxW)
        let sprite = btn.children.compactMap { $0 as? SKSpriteNode }.first
        let w = sprite?.size.width  ?? maxW
        let h = sprite?.size.height ?? (maxW * 0.5)
        btn.position = topLeftButtonPosition(w: w, h: h)
        parent.addChild(btn)
    }

    func showInGameBackButton() {
        inGameBackButton?.removeFromParent()
        let maxW = backButtonWidth()
        let btn = makeImageButton(imageName: GameConfig.Assets.backButton,
                                  name: GameConfig.ButtonNames.inGameBack,
                                  position: .zero,
                                  maxWidth: maxW)
        let sprite = btn.children.compactMap { $0 as? SKSpriteNode }.first
        let w = sprite?.size.width  ?? maxW
        let h = sprite?.size.height ?? (maxW * 0.5)
        btn.position = topLeftButtonPosition(w: w, h: h)
        btn.zPosition = 1500
        addChild(btn)
        inGameBackButton = btn
    }

    func hideInGameBackButton() {
        inGameBackButton?.removeFromParent()
        inGameBackButton = nil
    }

    // MARK: - Private layout helpers

    private func backButtonWidth() -> CGFloat {
        Adaptive.value(pad: min(220, size.width * 0.12),
                       phone: min(140, size.width * 0.18))
    }

    private func topLeftButtonPosition(w: CGFloat, h: CGFloat) -> CGPoint {
        let left = max(18, safeInsets.left + 18)
        let top  = max(18, safeInsets.top  + 18)
        return CGPoint(x: left + w * 0.5, y: size.height - top - h * 0.5)
    }
}
