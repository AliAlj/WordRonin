//
//  GameSceneOverlays.swift
//  slicenspell
//
//  Created by Jad Aoun on 2/11/26.
//

import SpriteKit

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

        // Dim background
        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.55), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.zPosition = 0
        overlay.addChild(dim)

        // Back button stays top-left (outside popup)
        addTopLeftBackImageButton(to: overlay, name: GameConfig.ButtonNames.menuBack)

        // Popup container
        let popup = SKNode()
        popup.name = GameConfig.PopupNames.startPopup
        popup.zPosition = 10
        popup.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(popup)

        // Panel background (simple rounded rect)
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

        // Optional soft shadow behind panel
        let shadow = SKShapeNode(path: panelPath.cgPath)
        shadow.fillColor = UIColor(white: 0.0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -10)
        shadow.zPosition = -1
        popup.addChild(shadow)

        // Title inside popup
        let title = SKLabelNode(fontNamed: "NJNaruto-Regular")
        title.text = "Slice Mode"
        title.fontSize = 54
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelH * 0.28)
        title.zPosition = 1
        popup.addChild(title)

        // Buttons inside popup
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

        // Popup animation (subtle)
        popup.setScale(0.92)
        popup.alpha = 0
        popup.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.14),
            SKAction.scale(to: 1.0, duration: 0.14)
        ]))

        setMenuButtonsFaded(false)
    }

    // MARK: - Tutorial
    func showTutorialOverlay() {
        tutorialOverlay?.removeFromParent()
        setMenuButtonsFaded(true)

        let overlay = SKNode()
        overlay.zPosition = 2000
        addChild(overlay)
        tutorialOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.86), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        addTopLeftBackImageButton(to: overlay, name: GameConfig.ButtonNames.tutorialBack)

        let title = SKLabelNode(fontNamed: "Chalkduster")
        title.text = "How to Play"
        title.fontSize = 56
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.80)
        overlay.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "Chalkduster")
        subtitle.text = "Swipe across letters to form a word"
        subtitle.fontSize = 22
        subtitle.fontColor = UIColor(white: 1, alpha: 0.85)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.73)
        overlay.addChild(subtitle)

        let rules = SKLabelNode(fontNamed: "Chalkduster")
        rules.text = "Goal: make as many words as you can. Try to solve the full word (use all letters) for the max bonus."
        rules.fontSize = 20
        rules.fontColor = UIColor(white: 1, alpha: 0.92)
        rules.horizontalAlignmentMode = .center
        rules.verticalAlignmentMode = .top
        rules.numberOfLines = 0
        rules.preferredMaxLayoutWidth = size.width * 0.90
        rules.position = CGPoint(x: size.width / 2, y: size.height * 0.69)
        overlay.addChild(rules)

        let s3 = WordGameLogic.pointsForWord(length: 3)
        let s4 = WordGameLogic.pointsForWord(length: 4)
        let s5 = WordGameLogic.pointsForWord(length: 5)
        let s6 = WordGameLogic.pointsForWord(length: 6)

        let scoring = SKLabelNode(fontNamed: "Chalkduster")
        scoring.text = "Scoring: 50 per letter + bonus. 3 letters = \(s3), 4 = \(s4), 5 = \(s5), 6+ = \(s6)+"
        scoring.fontSize = 20
        scoring.fontColor = UIColor(white: 1, alpha: 0.90)
        scoring.horizontalAlignmentMode = .center
        scoring.verticalAlignmentMode = .top
        scoring.numberOfLines = 0
        scoring.preferredMaxLayoutWidth = size.width * 0.90
        scoring.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        overlay.addChild(scoring)

        let word = Array("ORANGE")
        let spacing: CGFloat = min(150, size.width / 8.0)
        let y = size.height * 0.50
        let startX = size.width * 0.5 - spacing * CGFloat(word.count - 1) * 0.5

        var letterPositions: [CGPoint] = []
        for i in 0..<word.count {
            let x = startX + spacing * CGFloat(i)
            letterPositions.append(CGPoint(x: x, y: y))
        }

        let bambooNodes: [SKNode] = word.enumerated().map { (i, ch) in
            let container = SKNode()
            container.position = letterPositions[i]
            container.zPosition = 1

            let bamboo = SKSpriteNode(imageNamed: GameConfig.Assets.bambooImage)
            bamboo.size = CGSize(width: 120, height: 120)
            bamboo.alpha = 0.95
            container.addChild(bamboo)

            let label = SKLabelNode(fontNamed: "Chalkduster")
            label.text = String(ch)
            label.fontSize = 54
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: -14, y: -4)
            label.name = "demo_letter_label"
            container.addChild(label)

            overlay.addChild(container)
            return container
        }

        let line = SKShapeNode()
        line.zPosition = 2
        line.strokeColor = UIColor(white: 1, alpha: 0.55)
        line.lineWidth = 6
        line.lineCap = .round
        overlay.addChild(line)

        let dot = SKShapeNode(circleOfRadius: 10)
        dot.zPosition = 3
        dot.fillColor = UIColor(white: 1, alpha: 0.9)
        dot.strokeColor = .clear
        overlay.addChild(dot)

        runTutorialAnimation(line: line, dot: dot, letterNodes: bambooNodes, points: letterPositions)
    }

    func hideTutorialOverlay() {
        tutorialOverlay?.removeAllActions()
        tutorialOverlay?.removeFromParent()
        tutorialOverlay = nil
        setMenuButtonsFaded(false)
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

        let title = SKLabelNode(fontNamed: "Chalkduster")
        title.text = "Time's Up"
        title.fontSize = 64
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        overlay.addChild(title)

        let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
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

        let foundLabel = SKLabelNode(fontNamed: "Chalkduster")
        foundLabel.text = "Found (\(found.count)): \(foundText)"
        foundLabel.fontSize = 20
        foundLabel.fontColor = .white
        foundLabel.horizontalAlignmentMode = .center
        foundLabel.verticalAlignmentMode = .top
        foundLabel.numberOfLines = 0
        foundLabel.preferredMaxLayoutWidth = size.width * 0.9
        foundLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        overlay.addChild(foundLabel)

        let missingLabel = SKLabelNode(fontNamed: "Chalkduster")
        missingLabel.text = "Missing (\(missing.count)): \(missingText)"
        missingLabel.fontSize = 20
        missingLabel.fontColor = .white
        missingLabel.horizontalAlignmentMode = .center
        missingLabel.verticalAlignmentMode = .top
        missingLabel.numberOfLines = 0
        missingLabel.preferredMaxLayoutWidth = size.width * 0.9
        missingLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        overlay.addChild(missingLabel)

        let playAgainBtn = makeBambooButton(
            title: "Play Again",
            name: GameConfig.ButtonNames.playAgain,
            position: CGPoint(x: size.width / 2, y: size.height * 0.20),
            size: CGSize(width: min(420, size.width * 0.72), height: 200),
            fontSize: 30
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
