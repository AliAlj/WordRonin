//  GameSceneOverlays.swift
import SpriteKit
import SwiftUI

extension GameScene {

    // MARK: - Start Menu
    func setMenuButtonsFaded(_ faded: Bool) {
        guard let container = startMenuButtonsContainer else { return }
        let target: CGFloat = faded ? 0.18 : 1.0
        container.run(SKAction.fadeAlpha(to: target, duration: 0.12))
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

        let popup = SKNode()
        popup.name = GameConfig.PopupNames.startPopup
        popup.zPosition = 10
        popup.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(popup)

        let panelW = min(size.width * 0.78, 720)
        let panelH = min(size.height * 0.55, 520)

        let panelPath = UIBezierPath(
            roundedRect: CGRect(x: -panelW/2, y: -panelH/2, width: panelW, height: panelH),
            cornerRadius: 28
        )

        let panel = SKShapeNode(path: panelPath.cgPath)
        panel.name = GameConfig.PopupNames.startPopupPanel
        panel.fillColor = UIColor(white: 0.05, alpha: 0.75)
        panel.strokeColor = UIColor(white: 1.0, alpha: 0.12)
        panel.lineWidth = 2
        panel.zPosition = 0
        popup.addChild(panel)

        let title = SKLabelNode(fontNamed: "NJNaruto-Regular")
        title.text = "Slice Mode"
        title.fontSize = 54
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelH * 0.28)
        title.zPosition = 1
        popup.addChild(title)

        startMenuButtonsContainer?.removeFromParent()
        let buttons = SKNode()
        buttons.zPosition = 2
        popup.addChild(buttons)
        startMenuButtonsContainer = buttons

        let startBtn = makeImageButton(
            imageName: GameConfig.Assets.startGameButton,
            name: GameConfig.ButtonNames.start,
            position: CGPoint(x: 0, y: 20),
            maxWidth: min(460, panelW * 0.78)
        )
        buttons.addChild(startBtn)

        let howBtn = makeImageButton(
            imageName: GameConfig.Assets.howToPlayButton,
            name: GameConfig.ButtonNames.howToPlay,
            position: CGPoint(x: 0, y: -panelH * 0.22),
            maxWidth: min(360, panelW * 0.70)
        )
        buttons.addChild(howBtn)

        popup.setScale(0.92)
        popup.alpha = 0
        popup.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.14),
            SKAction.scale(to: 1.0, duration: 0.14)
        ]))

        setMenuButtonsFaded(false)
    }

    // MARK: - Settings Overlay
    func showSettingsOverlay() {
        settingsOverlay?.removeFromParent()

        let overlay = SKNode()
        overlay.zPosition = 2500
        addChild(overlay)
        settingsOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.8), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        let popup = SKNode()
        popup.name = GameConfig.PopupNames.settingsPopup
        popup.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(popup)

        let panelW: CGFloat = 600
        let panelH: CGFloat = 400
        let bgPath = UIBezierPath(
            roundedRect: CGRect(x: -panelW/2, y: -panelH/2, width: panelW, height: panelH),
            cornerRadius: 24
        )

        let panel = SKShapeNode(path: bgPath.cgPath)
        panel.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.78, alpha: 1.0)
        panel.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.9, alpha: 1.0)
        panel.lineWidth = 4
        popup.addChild(panel)

        let header = SKSpriteNode(imageNamed: GameConfig.Assets.settingsHeader)
        header.position = CGPoint(x: 0, y: panelH/2 + 30)
        let maxHeaderW: CGFloat = 300
        if header.size.width > maxHeaderW {
            let scale = maxHeaderW / header.size.width
            header.setScale(scale)
        }
        popup.addChild(header)

        let closeBtn = makeImageButton(
            imageName: GameConfig.Assets.closeButton,
            name: GameConfig.ButtonNames.closeSettings,
            position: CGPoint(x: panelW/2 + 20, y: panelH/2 + 20),
            maxWidth: 70
        )
        popup.addChild(closeBtn)

        let uniformButtonWidth: CGFloat = 180
        let topRowY: CGFloat = 70
        let bottomRowY: CGFloat = -80
        let spacing: CGFloat = 160

        let soundBtn = makeImageButton(
            imageName: GameConfig.Assets.soundIcon,
            name: GameConfig.ButtonNames.toggleSound,
            position: CGPoint(x: -spacing, y: topRowY),
            maxWidth: uniformButtonWidth
        )
        popup.addChild(soundBtn)

        let musicBtn = makeImageButton(
            imageName: GameConfig.Assets.musicIcon,
            name: GameConfig.ButtonNames.toggleMusic,
            position: CGPoint(x: spacing, y: topRowY),
            maxWidth: uniformButtonWidth
        )
        popup.addChild(musicBtn)

        let dojoBtn = makeImageButton(
            imageName: GameConfig.Assets.dojoIcon,
            name: GameConfig.ButtonNames.dojoAction,
            position: CGPoint(x: 0, y: bottomRowY),
            maxWidth: uniformButtonWidth
        )
        popup.addChild(dojoBtn)
    }

    func hideSettingsOverlay() {
        settingsOverlay?.removeFromParent()
        settingsOverlay = nil
    }

    // MARK: - Tutorial
    func showTutorialOverlay() {
        tutorialOverlay?.removeFromParent()

        // Kill the start overlay completely so nothing leaks through
        startOverlay?.removeFromParent()
        startOverlay = nil

        let overlay = SKNode()
        overlay.zPosition = 2000
        addChild(overlay)
        tutorialOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.78), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.zPosition = 0
        overlay.addChild(dim)

        addTopLeftBackImageButton(to: overlay, name: GameConfig.ButtonNames.tutorialBack)

        let card = SKNode()
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.zPosition = 10
        overlay.addChild(card)

        let cardW = min(size.width * 0.86, 980)
        let cardH = min(size.height * 0.74, 760)

        let cardRect = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 34)

        let shadow = SKShapeNode(path: cardPath.cgPath)
        shadow.fillColor = UIColor(white: 0, alpha: 0.55)
        shadow.strokeColor = .clear
        shadow.lineWidth = 0
        shadow.position = CGPoint(x: 0, y: -10)
        shadow.zPosition = 0
        card.addChild(shadow)

        let panel = SKShapeNode(path: cardPath.cgPath)
        panel.fillColor = UIColor(white: 0.08, alpha: 0.92)
        panel.strokeColor = UIColor(white: 1.0, alpha: 0.18)
        panel.lineWidth = 2
        panel.zPosition = 1
        card.addChild(panel)

        let innerRect = cardRect.insetBy(dx: 10, dy: 10)
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: 28)
        let inner = SKShapeNode(path: innerPath.cgPath)
        inner.fillColor = .clear
        inner.strokeColor = UIColor(white: 1.0, alpha: 0.08)
        inner.lineWidth = 2
        inner.zPosition = 2
        card.addChild(inner)

        let title = SKLabelNode(fontNamed: "SF Pro Rounded")
        title.text = "How to Play"
        title.fontSize = 56
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: cardH * 0.34)
        title.zPosition = 5
        card.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "SF Pro Rounded")
        subtitle.text = "Swipe across the letters to form a word"
        subtitle.fontSize = 22
        subtitle.fontColor = UIColor(white: 1, alpha: 0.85)
        subtitle.position = CGPoint(x: 0, y: cardH * 0.24)
        subtitle.zPosition = 5
        card.addChild(subtitle)

        let rules = SKLabelNode(fontNamed: "SF Pro Rounded")
        rules.text = "Make as many words as possible. Use all letters for the full word bonus."
        rules.fontSize = 20
        rules.fontColor = UIColor(white: 1, alpha: 0.92)
        rules.horizontalAlignmentMode = .center
        rules.verticalAlignmentMode = .top
        rules.numberOfLines = 0
        rules.preferredMaxLayoutWidth = cardW * 0.86
        rules.position = CGPoint(x: 0, y: cardH * 0.18)
        rules.zPosition = 5
        card.addChild(rules)

        let s3 = WordGameLogic.pointsForWord(length: 3)
        let s4 = WordGameLogic.pointsForWord(length: 4)
        let s5 = WordGameLogic.pointsForWord(length: 5)
        let s6 = WordGameLogic.pointsForWord(length: 6)

        let scoring = SKLabelNode(fontNamed: "SF Pro Rounded")
        scoring.text = "Scoring: 50 points per letter plus bonus.\n3 letters: \(s3)  •  4 letters: \(s4)  •  5 letters: \(s5)  •  6+ letters: \(s6)+"
        scoring.fontSize = 20
        scoring.fontColor = UIColor(white: 1, alpha: 0.90)
        scoring.horizontalAlignmentMode = .center
        scoring.verticalAlignmentMode = .top
        scoring.numberOfLines = 0
        scoring.preferredMaxLayoutWidth = cardW * 0.86
        scoring.position = CGPoint(x: 0, y: cardH * 0.06)
        scoring.zPosition = 5
        card.addChild(scoring)

        let word = Array("WORD")
        let spacing: CGFloat = min(150, cardW / 6.2)
        let demoY: CGFloat = -cardH * 0.18
        let startX = -spacing * CGFloat(word.count - 1) * 0.5

        var letterPositions: [CGPoint] = []
        for i in 0..<word.count {
            letterPositions.append(CGPoint(x: startX + spacing * CGFloat(i), y: demoY))
        }

        let bambooNodes: [SKNode] = word.enumerated().map { (i, ch) in
            let container = SKNode()
            container.position = letterPositions[i]
            container.zPosition = 6

            let bamboo = SKSpriteNode(imageNamed: GameConfig.Assets.bambooImage)
            bamboo.size = CGSize(width: 120, height: 120)
            bamboo.alpha = 0.98
            container.addChild(bamboo)

            let label = SKLabelNode(fontNamed: "SF Pro Rounded")
            label.text = String(ch)
            label.fontSize = 54
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: -14, y: -4)
            label.name = "demo_letter_label"
            container.addChild(label)

            card.addChild(container)
            return container
        }

        let line = SKShapeNode()
        line.zPosition = 7
        line.strokeColor = UIColor(white: 1, alpha: 0.55)
        line.lineWidth = 6
        line.lineCap = .round
        card.addChild(line)

        let dot = SKShapeNode(circleOfRadius: 10)
        dot.zPosition = 8
        dot.fillColor = UIColor(white: 1, alpha: 0.9)
        dot.strokeColor = .clear
        card.addChild(dot)

        runTutorialAnimation(line: line, dot: dot, letterNodes: bambooNodes, points: letterPositions)
    }

    func hideTutorialOverlay() {
        tutorialOverlay?.removeAllActions()
        tutorialOverlay?.removeFromParent()
        tutorialOverlay = nil

        // Rebuild the menu because we deleted startOverlay when opening tutorial
        showStartOverlay()
    }

    func runTutorialAnimation(line: SKShapeNode, dot: SKShapeNode, letterNodes: [SKNode], points: [CGPoint]) {
        line.removeAllActions()
        dot.removeAllActions()
        for n in letterNodes { n.removeAllActions() }

        func setAllLetters(color: UIColor) {
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

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.12)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.12)

        let reset = SKAction.run {
            line.path = nil
            dot.position = points.first ?? .zero
            dot.alpha = 0
            line.alpha = 0
            setAllLetters(color: .white)
        }

        let show = SKAction.run {
            dot.alpha = 1
            line.alpha = 1
        }

        let drawDuration: TimeInterval = 1.35
        let steps = max(2, min(36, points.count * 8))
        let stepTime = drawDuration / TimeInterval(steps)

        var allPoints: [CGPoint] = []
        if let first = points.first {
            allPoints.append(first)
            for p in points.dropFirst() { allPoints.append(p) }
        }

        let draw = SKAction.repeat(SKAction.sequence([
            SKAction.run {
                if allPoints.isEmpty { return }

                let t = (dot.userData?["t"] as? Int) ?? 0
                let nextT = t + 1
                dot.userData = dot.userData ?? NSMutableDictionary()
                dot.userData?["t"] = nextT

                let total = steps
                let progress = min(1.0, Double(nextT) / Double(total))

                let segmentCount = max(1, allPoints.count - 1)
                let scaled = progress * Double(segmentCount)
                let seg = min(segmentCount - 1, Int(scaled))
                let local = scaled - Double(seg)

                let a = allPoints[seg]
                let b = allPoints[seg + 1]
                let x = a.x + CGFloat(local) * (b.x - a.x)
                let y = a.y + CGFloat(local) * (b.y - a.y)
                let current = CGPoint(x: x, y: y)
                dot.position = current

                var pathPoints: [CGPoint] = []
                let pathSteps = max(2, Int(progress * Double(steps)))
                for i in 0..<pathSteps {
                    let pr = Double(i) / Double(max(1, pathSteps - 1))
                    let scaled2 = pr * Double(segmentCount)
                    let seg2 = min(segmentCount - 1, Int(scaled2))
                    let local2 = scaled2 - Double(seg2)

                    let a2 = allPoints[seg2]
                    let b2 = allPoints[seg2 + 1]
                    let x2 = a2.x + CGFloat(local2) * (b2.x - a2.x)
                    let y2 = a2.y + CGFloat(local2) * (b2.y - a2.y)
                    pathPoints.append(CGPoint(x: x2, y: y2))
                }

                if pathPoints.count >= 2 {
                    let bez = UIBezierPath()
                    bez.move(to: pathPoints[0])
                    for p in pathPoints.dropFirst() { bez.addLine(to: p) }
                    line.path = bez.cgPath
                }

                let letterIndex = min(allPoints.count - 1, Int(round(progress * Double(allPoints.count - 1))))
                setAllLetters(color: .white)
                if letterIndex >= 0 {
                    for i in 0...letterIndex { highlightLetter(at: i) }
                }
            },
            SKAction.wait(forDuration: stepTime)
        ]), count: steps)

        let clearT = SKAction.run {
            dot.userData = dot.userData ?? NSMutableDictionary()
            dot.userData?["t"] = 0
        }

        let cycle = SKAction.sequence([
            reset,
            fadeIn,
            show,
            clearT,
            draw,
            SKAction.wait(forDuration: 0.25),
            fadeOut,
            SKAction.wait(forDuration: 0.20)
        ])

        dot.run(SKAction.repeatForever(cycle))
        line.run(SKAction.repeatForever(cycle))
    }

    // MARK: - Game Over
    func endGame() {
        if gameEnded { return }
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

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.75), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        let title = SKLabelNode(fontNamed: "SF Pro Rounded")
        title.text = "Time's Up"
        title.fontSize = 64
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        overlay.addChild(title)

        let scoreLabel = SKLabelNode(fontNamed: "SF Pro Rounded")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 44
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        overlay.addChild(scoreLabel)

        let missingRaw = Array(possibleWords.subtracting(foundWords))
        let foundRaw = Array(foundWords)

        let missing = sortWordsHighToLow(missingRaw)
        let found = sortWordsHighToLow(foundRaw)

        let foundText = found.joined(separator: ", ")
        let missingText = missing.joined(separator: ", ")

        let foundLabel = SKLabelNode(fontNamed: "SF Pro Rounded")
        foundLabel.text = "Found (\(found.count)): \(foundText)"
        foundLabel.fontSize = 30
        foundLabel.fontColor = .white
        foundLabel.horizontalAlignmentMode = .center
        foundLabel.verticalAlignmentMode = .top
        foundLabel.numberOfLines = 0
        foundLabel.preferredMaxLayoutWidth = size.width * 0.9
        foundLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        overlay.addChild(foundLabel)

        let missingLabel = SKLabelNode(fontNamed: "SF Pro Rounded")
        missingLabel.text = "Missing (\(missing.count)): \(missingText)"
        missingLabel.fontSize = 30
        missingLabel.fontColor = .white
        missingLabel.horizontalAlignmentMode = .center
        missingLabel.verticalAlignmentMode = .top
        missingLabel.numberOfLines = 0
        missingLabel.preferredMaxLayoutWidth = size.width * 0.9
        missingLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        overlay.addChild(missingLabel)

        let playAgainBtn = makeImageButton(
            imageName: "playagainbutton",
            name: GameConfig.ButtonNames.playAgain,
            position: CGPoint(x: size.width / 2, y: size.height * 0.20),
            maxWidth: min(460, size.width * 0.72)
        )
        overlay.addChild(playAgainBtn)
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

        physicsWorld.speed = 0.85
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        AudioManager.shared.stopMusic()

        stopClockTick()

        gameEnded = false
        gameStarted = false
        roundActive = false

        score = 0
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
        activeSliceBG.path = nil
        activeSliceFG.path = nil
        activeSliceBG.alpha = 0
        activeSliceFG.alpha = 0

        hideInGameBackButton()
        showStartOverlay()
    }
}

#if canImport(SwiftUI)
#Preview("Tutorial – Landscape", traits: .landscapeLeft) {
    RootModeView()
}
#endif
