// GameSceneOverlays.swift
import SpriteKit
import SwiftUI

extension GameScene {

    // MARK: - Start Menu

    func setMenuButtonsFaded(_ faded: Bool) {
        guard let container = startMenuButtonsContainer else { return }
        container.run(SKAction.fadeAlpha(to: faded ? 0.18 : 1.0, duration: 0.12))
    }

    func showStartOverlay() {
        setMenuBackground()
        startOverlay?.removeFromParent()
        hideInGameBackButton()
        AudioManager.shared.stopMusic()
        stopClockTick()

        let overlay = SKNode()
        overlay.zPosition = 999
        addChild(overlay)
        startOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.55), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.zPosition = 0
        overlay.addChild(dim)

        addTopLeftBackImageButton(to: overlay, name: GameConfig.ButtonNames.menuBack)

        let isPad = Adaptive.isPad

        // Panel — tighter on iPhone so nothing clips
        let panelW = isPad ? min(size.width * 0.80, 720) : min(size.width * 0.82, 420)
        let panelH = isPad ? min(size.height * 0.58, 520) : min(size.height * 0.48, 280)

        let popup = SKNode()
        popup.name      = GameConfig.PopupNames.startPopup
        popup.zPosition = 10
        popup.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(popup)

        let panelPath = UIBezierPath(
            roundedRect: CGRect(x: -panelW / 2, y: -panelH / 2, width: panelW, height: panelH),
            cornerRadius: 24
        )
        let panel = SKShapeNode(path: panelPath.cgPath)
        panel.name        = GameConfig.PopupNames.startPopupPanel
        panel.fillColor   = UIColor(white: 0.05, alpha: 0.78)
        panel.strokeColor = UIColor(white: 1.0,  alpha: 0.12)
        panel.lineWidth   = 2
        popup.addChild(panel)

        // Title — inside the panel with room above buttons
        let titleFS: CGFloat = isPad ? 54 : 34
        let title = SKLabelNode(fontNamed: "SF Pro Rounded")
        title.text      = "Slice Mode"
        title.fontSize  = titleFS
        title.fontColor = .white
        // Position title near top of panel with safe margin
        title.position  = CGPoint(x: 0, y: panelH * 0.30)
        title.zPosition = 1
        popup.addChild(title)

        // Buttons container
        let buttons = SKNode()
        buttons.zPosition = 2
        popup.addChild(buttons)
        startMenuButtonsContainer = buttons

        // Button sizes — smaller on iPhone, fit inside the panel
        let startMaxW = isPad ? min(400, panelW * 0.78) : min(panelW * 0.72, 280)
        let howMaxW   = isPad ? min(380, panelW * 0.70) : min(panelW * 0.62, 240)

        // Space buttons evenly inside the panel below the title
        let startY:     CGFloat = isPad ?  20  :  panelH * 0.06
        let secondaryY: CGFloat = isPad ? -(panelH * 0.22) : -(panelH * 0.30)

        let startBtn = makeImageButton(imageName: GameConfig.Assets.startGameButton,
                                       name: GameConfig.ButtonNames.start,
                                       position: CGPoint(x: 0, y: startY),
                                       maxWidth: startMaxW)
        buttons.addChild(startBtn)

        let howBtn = makeImageButton(imageName: GameConfig.Assets.howToPlayButton,
                                     name: GameConfig.ButtonNames.howToPlay,
                                     position: CGPoint(x: 0, y: secondaryY),
                                     maxWidth: howMaxW)
        buttons.addChild(howBtn)

        popup.setScale(0.92)
        popup.alpha = 0
        popup.run(SKAction.group([.fadeIn(withDuration: 0.14), .scale(to: 1.0, duration: 0.14)]))
        setMenuButtonsFaded(false)
    }

    // MARK: - Settings Overlay

    func showSettingsOverlay() {
        settingsOverlay?.removeFromParent()
        let overlay = SKNode()
        overlay.zPosition = 2500
        addChild(overlay)
        settingsOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.82), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        let popup = SKNode()
        popup.name     = GameConfig.PopupNames.settingsPopup
        popup.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(popup)

        // Adaptive panel size — narrower on iPhone
        let isPad  = Adaptive.isPad
        let panelW: CGFloat = isPad ? 600 : min(size.width * 0.88, 360)
        let panelH: CGFloat = isPad ? 400 : 300

        let bgPath = UIBezierPath(
            roundedRect: CGRect(x: -panelW / 2, y: -panelH / 2, width: panelW, height: panelH),
            cornerRadius: 24
        )
        let panel = SKShapeNode(path: bgPath.cgPath)
        panel.fillColor   = UIColor(red: 0.95, green: 0.92, blue: 0.78, alpha: 1.0)
        panel.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.9, alpha: 1.0)
        panel.lineWidth   = 4
        popup.addChild(panel)

        // Header image
        let header = SKSpriteNode(imageNamed: GameConfig.Assets.settingsHeader)
        header.position = CGPoint(x: 0, y: panelH / 2 + (isPad ? 30 : 22))
        let maxHeaderW: CGFloat = isPad ? 300 : 220
        if header.size.width > maxHeaderW {
            header.setScale(maxHeaderW / header.size.width)
        }
        popup.addChild(header)

        // Close button — top-right of panel
        let closeBtn = makeImageButton(imageName: GameConfig.Assets.closeButton,
                                       name: GameConfig.ButtonNames.closeSettings,
                                       position: CGPoint(x: panelW / 2 + 18, y: panelH / 2 + 18),
                                       maxWidth: isPad ? 70 : 54)
        popup.addChild(closeBtn)

        // Icon buttons — scale down on iPhone
        let btnW: CGFloat = isPad ? 180 : 120
        let spacing: CGFloat = isPad ? 160 : 108
        let topRowY: CGFloat = isPad ?  70 : 56
        let botRowY: CGFloat = isPad ? -80 : -68

        let soundBtn = makeImageButton(imageName: GameConfig.Assets.soundIcon,
                                       name: GameConfig.ButtonNames.toggleSound,
                                       position: CGPoint(x: -spacing, y: topRowY),
                                       maxWidth: btnW)
        popup.addChild(soundBtn)

        let musicBtn = makeImageButton(imageName: GameConfig.Assets.musicIcon,
                                       name: GameConfig.ButtonNames.toggleMusic,
                                       position: CGPoint(x:  spacing, y: topRowY),
                                       maxWidth: btnW)
        popup.addChild(musicBtn)

        let dojoBtn = makeImageButton(imageName: GameConfig.Assets.dojoIcon,
                                      name: GameConfig.ButtonNames.dojoAction,
                                      position: CGPoint(x: 0, y: botRowY),
                                      maxWidth: btnW)
        popup.addChild(dojoBtn)

        // Animate in
        popup.setScale(0.88)
        popup.alpha = 0
        popup.run(SKAction.group([.fadeIn(withDuration: 0.14), .scale(to: 1.0, duration: 0.14)]))
    }

    func hideSettingsOverlay() {
        settingsOverlay?.removeFromParent()
        settingsOverlay = nil
    }

    // MARK: - Tutorial

    func showTutorialOverlay() {
        tutorialOverlay?.removeFromParent()
        startOverlay?.removeFromParent()
        startOverlay = nil

        let overlay = SKNode()
        overlay.zPosition = 2000
        addChild(overlay)
        tutorialOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.78), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        addTopLeftBackImageButton(to: overlay, name: GameConfig.ButtonNames.tutorialBack)

        let card  = SKNode()
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.zPosition = 10
        overlay.addChild(card)

        let cardW = min(size.width * 0.86, 980)
        let cardH = min(size.height * 0.74, 760)
        let cardRect = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)

        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 34)
        let shadow   = SKShapeNode(path: cardPath.cgPath)
        shadow.fillColor   = UIColor(white: 0, alpha: 0.55)
        shadow.strokeColor = .clear
        shadow.position    = CGPoint(x: 0, y: -10)
        card.addChild(shadow)

        let panel = SKShapeNode(path: cardPath.cgPath)
        panel.fillColor   = UIColor(white: 0.08, alpha: 0.92)
        panel.strokeColor = UIColor(white: 1.0, alpha: 0.18)
        panel.lineWidth   = 2
        panel.zPosition   = 1
        card.addChild(panel)

        // Title
        let isPad = Adaptive.isPad
        let titleFS: CGFloat = isPad ? 56 : 40
        let bodyFS:  CGFloat = isPad ? 22 : 17

        let title = SKLabelNode(fontNamed: "SF Pro Rounded")
        title.text      = "How to Play"
        title.fontSize  = titleFS
        title.fontColor = .white
        title.position  = CGPoint(x: 0, y: cardH * 0.34)
        title.zPosition = 5
        card.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "SF Pro Rounded")
        subtitle.text      = "Swipe across the letters to form a word"
        subtitle.fontSize  = bodyFS
        subtitle.fontColor = UIColor(white: 1, alpha: 0.85)
        subtitle.position  = CGPoint(x: 0, y: cardH * 0.24)
        subtitle.zPosition = 5
        card.addChild(subtitle)

        let rules = SKLabelNode(fontNamed: "SF Pro Rounded")
        rules.text                  = "Make as many words as possible. Use all letters for the full word bonus."
        rules.fontSize              = bodyFS
        rules.fontColor             = UIColor(white: 1, alpha: 0.92)
        rules.horizontalAlignmentMode = .center
        rules.verticalAlignmentMode   = .top
        rules.numberOfLines           = 0
        rules.preferredMaxLayoutWidth = cardW * 0.86
        rules.position  = CGPoint(x: 0, y: cardH * 0.17)
        rules.zPosition = 5
        card.addChild(rules)

        let s3 = WordGameLogic.pointsForWord(length: 3)
        let s4 = WordGameLogic.pointsForWord(length: 4)
        let s5 = WordGameLogic.pointsForWord(length: 5)
        let s6 = WordGameLogic.pointsForWord(length: 6)
        let scoring = SKLabelNode(fontNamed: "SF Pro Rounded")
        scoring.text = "Scoring: 50 pts/letter + bonus\n3 letters: \(s3)  •  4: \(s4)  •  5: \(s5)  •  6+: \(s6)+"
        scoring.fontSize              = bodyFS
        scoring.fontColor             = UIColor(white: 1, alpha: 0.90)
        scoring.horizontalAlignmentMode = .center
        scoring.verticalAlignmentMode   = .top
        scoring.numberOfLines           = 0
        scoring.preferredMaxLayoutWidth = cardW * 0.86
        scoring.position  = CGPoint(x: 0, y: cardH * 0.06)
        scoring.zPosition = 5
        card.addChild(scoring)

        // Demo animation
        let word    = Array("WORD")
        let spacing = isPad ? min(150, cardW / 6.2) : min(110, cardW / 6.6)
        let demoY:  CGFloat = -cardH * (isPad ? 0.18 : 0.20)
        let startX  = -spacing * CGFloat(word.count - 1) * 0.5

        var letterPositions: [CGPoint] = word.indices.map {
            CGPoint(x: startX + spacing * CGFloat($0), y: demoY)
        }

        let bambooSide: CGFloat = isPad ? 120 : 80
        let bambooNodes: [SKNode] = word.enumerated().map { (i, ch) in
            let container = SKNode()
            container.position = letterPositions[i]
            container.zPosition = 6

            let bamboo = SKSpriteNode(imageNamed: GameConfig.Assets.bambooImage)
            bamboo.size = CGSize(width: bambooSide, height: bambooSide)
            bamboo.alpha = 0.98
            container.addChild(bamboo)

            let label = SKLabelNode(fontNamed: "SF Pro Rounded")
            label.text = String(ch)
            label.fontSize = isPad ? 54 : 38
            label.fontColor = .white
            label.verticalAlignmentMode   = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: -14, y: -4)
            label.name = "demo_letter_label"
            container.addChild(label)

            card.addChild(container)
            return container
        }

        let line = SKShapeNode()
        line.zPosition   = 7
        line.strokeColor = UIColor(white: 1, alpha: 0.55)
        line.lineWidth   = 6
        line.lineCap     = .round
        card.addChild(line)

        let dot = SKShapeNode(circleOfRadius: 10)
        dot.zPosition  = 8
        dot.fillColor  = UIColor(white: 1, alpha: 0.9)
        dot.strokeColor = .clear
        card.addChild(dot)

        runTutorialAnimation(line: line, dot: dot, letterNodes: bambooNodes, points: letterPositions)
    }

    func hideTutorialOverlay() {
        tutorialOverlay?.removeAllActions()
        tutorialOverlay?.removeFromParent()
        tutorialOverlay = nil
        showStartOverlay()
    }

    func runTutorialAnimation(line: SKShapeNode,
                              dot: SKShapeNode,
                              letterNodes: [SKNode],
                              points: [CGPoint]) {
        line.removeAllActions()
        dot.removeAllActions()
        for n in letterNodes { n.removeAllActions() }

        func setAllColors(_ color: UIColor) {
            for n in letterNodes {
                for child in n.children {
                    if let label = child as? SKLabelNode, label.name == "demo_letter_label" {
                        label.fontColor = color
                    }
                }
            }
        }

        func highlightLetter(at index: Int) {
            guard index >= 0 && index < letterNodes.count else { return }
            let node = letterNodes[index]
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.10, duration: 0.08),
                SKAction.scale(to: 1.00, duration: 0.10)
            ])
            node.run(pulse)
            for child in node.children {
                if let label = child as? SKLabelNode, label.name == "demo_letter_label" {
                    label.fontColor = .yellow
                }
            }
        }

        var allPoints: [CGPoint] = []
        if let first = points.first { allPoints.append(first) }
        for p in points.dropFirst() { allPoints.append(p) }

        let drawDuration: TimeInterval = 1.35
        let steps    = max(2, min(36, points.count * 8))
        let stepTime = drawDuration / TimeInterval(steps)

        let reset = SKAction.run {
            line.path    = nil
            dot.position = points.first ?? .zero
            dot.alpha    = 0
            line.alpha   = 0
            setAllColors(.white)
        }
        let show    = SKAction.run { dot.alpha = 1; line.alpha = 1 }
        let clearT  = SKAction.run { dot.userData = dot.userData ?? NSMutableDictionary(); dot.userData?["t"] = 0 }

        let draw = SKAction.repeat(SKAction.sequence([
            SKAction.run {
                let t        = (dot.userData?["t"] as? Int) ?? 0
                let nextT    = t + 1
                dot.userData = dot.userData ?? NSMutableDictionary()
                dot.userData?["t"] = nextT

                let progress     = min(1.0, Double(nextT) / Double(steps))
                let segmentCount = max(1, allPoints.count - 1)
                let scaled       = progress * Double(segmentCount)
                let seg          = min(segmentCount - 1, Int(scaled))
                let local        = scaled - Double(seg)
                let a = allPoints[seg], b = allPoints[seg + 1]
                let current = CGPoint(x: a.x + CGFloat(local) * (b.x - a.x),
                                      y: a.y + CGFloat(local) * (b.y - a.y))
                dot.position = current

                let pathSteps = max(2, Int(progress * Double(steps)))
                var pathPoints: [CGPoint] = []
                for i in 0..<pathSteps {
                    let pr     = Double(i) / Double(max(1, pathSteps - 1))
                    let sc2    = pr * Double(segmentCount)
                    let seg2   = min(segmentCount - 1, Int(sc2))
                    let local2 = sc2 - Double(seg2)
                    let a2 = allPoints[seg2], b2 = allPoints[seg2 + 1]
                    pathPoints.append(CGPoint(x: a2.x + CGFloat(local2) * (b2.x - a2.x),
                                             y: a2.y + CGFloat(local2) * (b2.y - a2.y)))
                }
                if pathPoints.count >= 2 {
                    let bez = UIBezierPath()
                    bez.move(to: pathPoints[0])
                    pathPoints.dropFirst().forEach { bez.addLine(to: $0) }
                    line.path = bez.cgPath
                }
                let lIdx = min(allPoints.count - 1, Int(round(progress * Double(allPoints.count - 1))))
                setAllColors(.white)
                if lIdx >= 0 { (0...lIdx).forEach { highlightLetter(at: $0) } }
            },
            SKAction.wait(forDuration: stepTime)
        ]), count: steps)

        let cycle = SKAction.sequence([
            reset,
            SKAction.fadeAlpha(to: 1.0, duration: 0.12),
            show, clearT, draw,
            SKAction.wait(forDuration: 0.25),
            SKAction.fadeAlpha(to: 0.0, duration: 0.12),
            SKAction.wait(forDuration: 0.20)
        ])
        dot.run(SKAction.repeatForever(cycle))
        line.run(SKAction.repeatForever(cycle))
    }

    // MARK: - Game Over

    func endGame() {
        guard !gameEnded else { return }
        gameEnded = true
        roundActive = false
        roundTimer?.invalidate()
        roundTimer = nil
        stopClockTick()
        physicsWorld.speed = 0
        showGameOverOverlay()
    }

    func showGameOverOverlay() {
        gameOverOverlay?.removeFromParent()
        let overlay = SKNode()
        overlay.zPosition = 1000
        addChild(overlay)
        gameOverOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.78), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        let isPad  = Adaptive.isPad
        let cardW  = min(size.width * 0.92, isPad ? 900 : 400)
        let cardH  = min(size.height * 0.88, isPad ? 680 : size.height * 0.85)
        let cx     = size.width  / 2
        let cy     = size.height / 2

        // Card background
        let cardPath = UIBezierPath(
            roundedRect: CGRect(x: cx - cardW / 2, y: cy - cardH / 2, width: cardW, height: cardH),
            cornerRadius: 28
        )
        let cardBG = SKShapeNode(path: cardPath.cgPath)
        cardBG.fillColor   = UIColor(white: 0.08, alpha: 0.95)
        cardBG.strokeColor = UIColor(white: 1, alpha: 0.15)
        cardBG.lineWidth   = 2
        cardBG.zPosition   = 1
        overlay.addChild(cardBG)

        // "Time's Up" title
        let topY = cy + cardH * 0.42
        let titleFS: CGFloat  = isPad ? 60 : 42
        let labelFS: CGFloat  = isPad ? 38 : 28
        let bodyFS:  CGFloat  = isPad ? 26 : 18

        let title = SKLabelNode(fontNamed: "SF Pro Rounded")
        title.text      = "Time's Up!"
        title.fontSize  = titleFS
        title.fontColor = .white
        title.position  = CGPoint(x: cx, y: topY - titleFS)
        title.zPosition = 5
        overlay.addChild(title)

        let scoreLabel = SKLabelNode(fontNamed: "SF Pro Rounded")
        scoreLabel.text      = "Score: \(score)"
        scoreLabel.fontSize  = labelFS
        scoreLabel.fontColor = .white
        scoreLabel.position  = CGPoint(x: cx, y: topY - titleFS - labelFS - 12)
        scoreLabel.zPosition = 5
        overlay.addChild(scoreLabel)

        // Words section — clip to card width
        let missingRaw = Array(possibleWords.subtracting(foundWords))
        let foundRaw   = Array(foundWords)
        let missing    = sortWordsHighToLow(missingRaw)
        let found      = sortWordsHighToLow(foundRaw)

        let foundText   = found.isEmpty   ? "None" : found.joined(separator: ", ")
        let missingText = missing.isEmpty ? "None" : missing.joined(separator: ", ")

        let wordLabelW = cardW * 0.90
        let wordY      = topY - titleFS - labelFS - labelFS - 40

        let foundLabel = multilineLabel(
            text:      "Found (\(found.count)): \(foundText)",
            fontSize:  bodyFS,
            color:     UIColor(red: 0.55, green: 1.0, blue: 0.55, alpha: 1.0),
            maxWidth:  wordLabelW,
            position:  CGPoint(x: cx, y: wordY),
            zPosition: 5
        )
        overlay.addChild(foundLabel)

        // Measure found label height for spacing
        let foundH = foundLabel.calculateAccumulatedFrame().height
        let missingY = wordY - foundH - (isPad ? 20 : 14)

        let missingLabel = multilineLabel(
            text:      "Missed (\(missing.count)): \(missingText)",
            fontSize:  bodyFS,
            color:     UIColor(red: 1.0, green: 0.65, blue: 0.55, alpha: 1.0),
            maxWidth:  wordLabelW,
            position:  CGPoint(x: cx, y: missingY),
            zPosition: 5
        )
        overlay.addChild(missingLabel)

        // Play Again button — pinned near bottom of card
        let btnW: CGFloat = isPad ? min(460, cardW * 0.65) : min(320, cardW * 0.82)
        let btnY  = cy - cardH * 0.42 + (isPad ? 52 : 44)

        let playAgainBtn = makeImageButton(
            imageName: "playagainbutton",
            name: GameConfig.ButtonNames.playAgain,
            position: CGPoint(x: cx, y: btnY),
            maxWidth: btnW
        )
        playAgainBtn.zPosition = 6
        overlay.addChild(playAgainBtn)

        // Animate card
        overlay.setScale(0.92)
        overlay.alpha = 0
        overlay.run(SKAction.group([.fadeIn(withDuration: 0.18), .scale(to: 1.0, duration: 0.18)]))
    }

    // Helper: creates a multi-line label (top-aligned)
    private func multilineLabel(text: String,
                                fontSize: CGFloat,
                                color: UIColor,
                                maxWidth: CGFloat,
                                position: CGPoint,
                                zPosition: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "SF Pro Rounded")
        label.text                    = text
        label.fontSize                = fontSize
        label.fontColor               = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode   = .top
        label.numberOfLines           = 0
        label.preferredMaxLayoutWidth = maxWidth
        label.position                = position
        label.zPosition               = zPosition
        return label
    }

    func sortWordsHighToLow(_ words: [String]) -> [String] {
        words.sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0 < $1
        }
    }

    func restartGame() {
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil

        roundTimer?.invalidate()
        roundTimer = nil
        physicsWorld.speed   = 0.85
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        AudioManager.shared.stopMusic()
        stopClockTick()

        gameEnded   = false
        gameStarted = false
        roundActive = false
        score       = 0
        foundWords.removeAll()
        possibleWords.removeAll()
        selectedIndices.removeAll()
        baseLetters.removeAll()

        for node in letterNodes { node.removeFromParent() }
        letterNodes.removeAll()

        currentWordLabel?.text = ""
        timeRemaining = 0
        updateTimerLabel()

        activeSlicePoints.removeAll(keepingCapacity: true)
        activeSliceBG.path  = nil
        activeSliceFG.path  = nil
        activeSliceBG.alpha = 0
        activeSliceFG.alpha = 0

        hideInGameBackButton()
        showStartOverlay()
    }
}

#if canImport(SwiftUI)
import SwiftUI
#Preview("Tutorial – Landscape", traits: .landscapeLeft) {
    RootModeView()
}
#endif
