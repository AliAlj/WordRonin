//  GameScene+Gameplay.swift
import SpriteKit

extension GameScene {

    // MARK: - Game Start
    func beginGame() {
        syncSettingsFromStore()

        startOverlay?.removeFromParent()
        startOverlay = nil
        hideSettingsOverlay()

        setInGameBackground()
        showInGameBackButton()

        if isMusicEnabled {
            AudioManager.shared.playMusic(fileName: GameConfig.Audio.musicSlice, volume: 0.15)
        } else {
            AudioManager.shared.stopMusic()
        }

        stopClockTick()

        gameStarted = true
        gameEnded = false
        roundActive = false
        score = 0

        foundWords.removeAll()
        possibleWords.removeAll()
        selectedIndices.removeAll()
        baseLetters.removeAll()

        roundTimer?.invalidate()
        roundTimer = nil

        for node in letterNodes { node.removeFromParent() }
        letterNodes.removeAll()

        currentWordLabel?.text = ""
        timeRemaining = GameConfig.roundDurationSeconds
        updateTimerLabel()

        activeSlicePoints.removeAll(keepingCapacity: true)
        activeSliceBG.path = nil
        activeSliceFG.path = nil
        activeSliceBG.alpha = 0
        activeSliceFG.alpha = 0

        startNewGameWord()
    }

    func startNewGameWord() {
        var chosen = WordGameLogic.startWords.randomElement() ?? "ORANGE"
        if WordGameLogic.startWords.count > 1 {
            var tries = 0
            while chosen == String(baseLetters) && tries < 10 {
                chosen = WordGameLogic.startWords.randomElement() ?? chosen
                tries += 1
            }
        }

        baseLetters = Array(chosen.uppercased())
        baseLetters.shuffle()

        possibleWords = WordGameLogic.generatePossibleWords(from: baseLetters, minLength: 3)
        foundWords.removeAll()

        spawnLetters(letters: baseLetters)

        roundActive = true
        startRoundTimer(seconds: GameConfig.roundDurationSeconds)
    }

    func spawnLetters(letters: [Character]) {
        for node in letterNodes { node.removeFromParent() }
        letterNodes.removeAll()

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        let letterSize = CGSize(width: 72, height: 72)
        let leftInset: CGFloat = max(30, safeInsets.left + 24)
        let rightInset: CGFloat = max(30, safeInsets.right + 24)
        let bottomInset: CGFloat = 120
        let topInset: CGFloat = max(260, safeInsets.top + 260)

        let playableRect = CGRect(
            x: leftInset + letterSize.width * 0.6,
            y: bottomInset + letterSize.height * 0.6,
            width: size.width - leftInset - rightInset - letterSize.width * 1.2,
            height: size.height - topInset - bottomInset - letterSize.height * 1.2
        )

        let minCenterDistance: CGFloat = 150
        let targets = randomNonOverlappingPositions(
            count: letters.count,
            in: playableRect,
            minDistance: minCenterDistance
        )

        for (index, letter) in letters.enumerated() {
            let letterNode = SKSpriteNode(color: .clear, size: CGSize(width: 118, height: 92))
            letterNode.name = "letter_\(index)"
            letterNode.zPosition = 10

            let target = targets[index]
            letterNode.position = CGPoint(x: target.x, y: -90)

            let bamboo = SKSpriteNode(imageNamed: GameConfig.Assets.bambooImage)
            bamboo.size = CGSize(width: 120, height: 120)
            bamboo.position = .zero
            bamboo.zPosition = -1
            bamboo.alpha = 0.98
            letterNode.addChild(bamboo)

            let label = SKLabelNode(fontNamed: "Chalkduster")
            label.name = "letterLabel"
            label.text = String(letter)
            label.fontSize = 54
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: -14, y: -4)
            letterNode.addChild(label)

            letterNode.physicsBody = SKPhysicsBody(rectangleOf: letterNode.size)
            letterNode.physicsBody?.collisionBitMask = 0
            letterNode.physicsBody?.linearDamping = 0
            letterNode.physicsBody?.angularDamping = 0
            letterNode.physicsBody?.allowsRotation = false

            addChild(letterNode)
            letterNodes.append(letterNode)

            let duration = Double.random(in: 0.45...0.75)
            let rise = SKAction.move(to: target, duration: duration)
            rise.timingMode = .easeOut

            letterNode.run(rise) { [weak letterNode] in
                letterNode?.physicsBody?.isDynamic = false
            }
        }

        for node in letterNodes { node.alpha = 1.0 }
    }

    func randomNonOverlappingPositions(count: Int, in rect: CGRect, minDistance: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        points.reserveCapacity(count)

        let maxAttempts = 4000
        let minDistSq = minDistance * minDistance

        func randPoint() -> CGPoint {
            let x = CGFloat.random(in: rect.minX...rect.maxX)
            let y = CGFloat.random(in: rect.minY...rect.maxY)
            return CGPoint(x: x, y: y)
        }

        var attempts = 0
        while points.count < count && attempts < maxAttempts {
            attempts += 1
            let p = randPoint()
            var ok = true
            for q in points {
                let dx = p.x - q.x
                let dy = p.y - q.y
                if dx * dx + dy * dy < minDistSq {
                    ok = false
                    break
                }
            }
            if ok { points.append(p) }
        }

        if points.count < count {
            let cols = max(1, Int(sqrt(Double(count)).rounded(.up)))
            let rows = max(1, Int(ceil(Double(count) / Double(cols))))
            let cellW = rect.width / CGFloat(cols)
            let cellH = rect.height / CGFloat(rows)

            points.removeAll(keepingCapacity: true)

            var idx = 0
            for r in 0..<rows {
                for c in 0..<cols {
                    if idx >= count { break }
                    idx += 1

                    let cx = rect.minX + cellW * (CGFloat(c) + 0.5)
                    let cy = rect.minY + cellH * (CGFloat(r) + 0.5)

                    let jitterX = CGFloat.random(in: -cellW * 0.18...cellW * 0.18)
                    let jitterY = CGFloat.random(in: -cellH * 0.18...cellH * 0.18)

                    points.append(CGPoint(x: cx + jitterX, y: cy + jitterY))
                }
            }
        }

        points.shuffle()
        return points
    }

    // MARK: - Timer
    func startRoundTimer(seconds: Int) {
        syncSettingsFromStore()

        roundTimer?.invalidate()
        timeRemaining = seconds
        updateTimerLabel()
        stopClockTick()

        roundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else { return }

            self.timeRemaining -= 1
            self.updateTimerLabel()

            if self.timeRemaining == 10 {
                self.startClockTick()
            }

            if self.timeRemaining <= 0 {
                t.invalidate()
                self.roundTimer = nil
                self.stopClockTick()
                self.roundTimeUp()
            }
        }

        if let roundTimer {
            RunLoop.main.add(roundTimer, forMode: .common)
        }
    }

    func updateTimerLabel() {
        timerLabel?.text = "Time: \(max(0, timeRemaining))"
        if let shadow = timerLabel?.userData?["shadow"] as? SKLabelNode {
            shadow.text = timerLabel?.text
        }
    }

    func startClockTick() {
        syncSettingsFromStore()
        guard isSoundEnabled else { return }
        guard !isClockTicking else { return }

        isClockTicking = true
        let tick = SKAction.playSoundFileNamed(GameConfig.Audio.clock, waitForCompletion: true)
        let loop = SKAction.repeatForever(SKAction.sequence([tick]))
        run(loop, withKey: "clockTick")
    }

    func stopClockTick() {
        removeAction(forKey: "clockTick")
        isClockTicking = false
    }

    func roundTimeUp() {
        roundActive = false
        stopClockTick()

        playSFX(GameConfig.Audio.wrong, waitForCompletion: false)

        for node in letterNodes { node.run(SKAction.fadeAlpha(to: 0.5, duration: 0.2)) }
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        for node in letterNodes { node.physicsBody?.isDynamic = true }

        endGame()
    }

    // MARK: - Validation
    func validate(candidate: String, usedIndices: [Int]) {
        let upper = candidate.uppercased()

        guard upper.count >= 3 else {
            feedbackIncorrect(indices: usedIndices)
            return
        }

        guard possibleWords.contains(upper) else {
            feedbackIncorrect(indices: usedIndices)
            return
        }

        guard !foundWords.contains(upper) else {
            feedbackIncorrect(indices: usedIndices, alreadyFound: true)
            return
        }

        foundWords.insert(upper)
        let gained = WordGameLogic.pointsForWord(length: upper.count)
        score += gained
        feedbackCorrect(indices: usedIndices)
    }

    func feedbackCorrect(indices: [Int]) {
        playSFX(GameConfig.Audio.correct, waitForCompletion: false)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.35, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.12)
        ])

        for idx in indices {
            guard idx >= 0 && idx < letterNodes.count else { continue }
            let node = letterNodes[idx]
            node.run(pulse)
            (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = .green
        }

        run(SKAction.wait(forDuration: 0.15)) { [weak self] in
            guard let self else { return }
            for idx in indices { self.unmarkLetter(at: idx) }
        }
    }

    func feedbackIncorrect(indices: [Int], alreadyFound: Bool = false) {
        playSFX(GameConfig.Audio.wrong, waitForCompletion: false)

        let shake = SKAction.sequence([
            .moveBy(x: -6, y: 0, duration: 0.05),
            .moveBy(x: 12, y: 0, duration: 0.05),
            .moveBy(x: -6, y: 0, duration: 0.05)
        ])

        for idx in indices {
            guard idx >= 0 && idx < letterNodes.count else { continue }
            let node = letterNodes[idx]
            node.run(shake)
            (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = alreadyFound ? .orange : .red
        }

        run(SKAction.wait(forDuration: 0.2)) { [weak self] in
            guard let self else { return }
            for idx in indices { self.unmarkLetter(at: idx) }
        }
    }
}
