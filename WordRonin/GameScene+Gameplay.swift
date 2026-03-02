// GameScene+Gameplay.swift
import SpriteKit
import UIKit

extension GameScene {

    // MARK: - Haptics

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isSoundEnabled else { return }   // reuse sound flag as "haptics on"
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }

    private func notificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(type)
    }

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
        gameEnded   = false
        roundActive = false
        score       = 0
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
        activeSliceBG.path  = nil
        activeSliceFG.path  = nil
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
        baseLetters   = Array(chosen.uppercased())
        baseLetters.shuffle()
        possibleWords = WordGameLogic.generatePossibleWords(from: baseLetters, minLength: 3)
        foundWords.removeAll()
        spawnLetters(letters: baseLetters)
        roundActive = true
        startRoundTimer(seconds: GameConfig.roundDurationSeconds)
    }

    // MARK: - Letter Spawn & Layout

    func spawnLetters(letters: [Character]) {
        for node in letterNodes { node.removeFromParent() }
        letterNodes.removeAll()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        let isPad      = Adaptive.isPad
        let tileSize   = GameConfig.Tiles.preferred
        let bambooSize = GameConfig.Tiles.bamboo
        let minGap     = GameConfig.Tiles.minGap

        let hudH      = GameConfig.HUD.bambooSize.height
        let wordBarH: CGFloat = isPad ? 60 : 48
        let topClear  = safeInsets.top + hudH + wordBarH + 16
        let bottomClear: CGFloat = safeInsets.bottom + (isPad ? 30 : 20)
        // Use very small side padding so letters can reach left and right edges
        let sidePad: CGFloat = isPad ? 20 : 8

        // Use full vertical space — no artificial zone restriction
        let scatterRect = CGRect(
            x: safeInsets.left  + sidePad,
            y: bottomClear,
            width:  max(1, size.width - safeInsets.left - safeInsets.right - sidePad * 2),
            height: max(1, size.height - topClear - bottomClear)
        )

        // ── Random non-overlapping positions ────────────────────────────────
        let minDist  = max(tileSize.width, tileSize.height) + minGap
        // Inset the scatter rect so tiles don't bleed past the edges
        let inset    = tileSize.width * 0.55
        let padded   = scatterRect.insetBy(dx: inset, dy: inset)
        var positions = randomNonOverlappingPositions(
            count: letters.count, in: padded, minDistance: minDist
        )
        // Fall back to grid if scatter couldn't place all tiles
        if positions.count < letters.count {
            let grid = makeGridLayout(count: letters.count, in: scatterRect,
                                      preferredTileSize: tileSize, minGap: minGap)
            positions = grid.positions
        }

        for (index, letter) in letters.enumerated() {
            let letterNode = SKSpriteNode(color: .clear, size: tileSize)
            letterNode.name      = "letter_\(index)"
            letterNode.zPosition = 10

            let target = positions[index]
            letterNode.position = CGPoint(x: target.x, y: scatterRect.minY - 40)

            // Square bamboo background
            let bamboo = SKSpriteNode(imageNamed: GameConfig.Assets.bambooImage)
            bamboo.size      = bambooSize
            bamboo.zPosition = -1
            bamboo.alpha     = 0.98
            letterNode.addChild(bamboo)

            // Letter label — centred, original offset style
            let label = SKLabelNode(fontNamed: "SF Pro Rounded")
            label.name      = "letterLabel"
            label.text      = String(letter)
            label.fontSize  = GameConfig.Tiles.labelFont
            label.fontColor = .white
            label.verticalAlignmentMode   = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: -tileSize.width * 0.09, y: -tileSize.height * 0.04)
            letterNode.addChild(label)

            // Physics
            letterNode.physicsBody = SKPhysicsBody(rectangleOf: letterNode.size)
            letterNode.physicsBody?.collisionBitMask = 0
            letterNode.physicsBody?.linearDamping    = 0
            letterNode.physicsBody?.angularDamping   = 0
            letterNode.physicsBody?.allowsRotation   = false

            addChild(letterNode)
            letterNodes.append(letterNode)

            // Staggered rise
            let delay    = Double(index) * 0.055
            let duration = Double.random(in: 0.38...0.60)
            let rise     = SKAction.move(to: target, duration: duration)
            rise.timingMode = .easeOut
            letterNode.run(.sequence([.wait(forDuration: delay), rise])) { [weak letterNode] in
                letterNode?.physicsBody?.isDynamic = false
            }
        }
    }

    // MARK: - Layout Internals

    struct LetterLayout {
        let tileSize:  CGSize
        let positions: [CGPoint]
    }

    func makeRandomThenGridLayout(count: Int,
                                  in rect: CGRect,
                                  preferredTileSize: CGSize,
                                  minGap: CGFloat) -> LetterLayout {
        let minDist  = max(preferredTileSize.width, preferredTileSize.height) + minGap
        let padded   = rect.insetBy(dx: preferredTileSize.width * 0.60,
                                    dy: preferredTileSize.height * 0.60)
        let targets  = randomNonOverlappingPositions(count: count, in: padded, minDistance: minDist)
        if targets.count == count, arePositionsNonOverlapping(targets, minDistance: minDist) {
            return LetterLayout(tileSize: preferredTileSize, positions: targets)
        }
        return makeGridLayout(count: count, in: rect,
                              preferredTileSize: preferredTileSize, minGap: minGap)
    }

    func makeGridLayout(count: Int,
                        in rect: CGRect,
                        preferredTileSize: CGSize,
                        minGap: CGFloat) -> LetterLayout {
        let safeRect = rect.insetBy(dx: 8, dy: 8)
        guard count > 0 else { return LetterLayout(tileSize: preferredTileSize, positions: []) }

        let aspect   = max(0.45, min(2.6, safeRect.width / max(1, safeRect.height)))
        var cols     = Int(round(sqrt(Double(count) * Double(aspect))))
        cols         = max(1, min(count, cols))
        var rows     = Int(ceil(Double(count) / Double(cols)))
        if count >= 4, rows == 1 {
            cols = max(2, Int(ceil(Double(count) / 2.0)))
            rows = Int(ceil(Double(count) / Double(cols)))
        }

        let totalGapW = CGFloat(max(0, cols - 1)) * minGap
        let totalGapH = CGFloat(max(0, rows - 1)) * minGap
        let tileW     = max(44, min(preferredTileSize.width,  (safeRect.width  - totalGapW) / CGFloat(cols)))
        let tileH     = max(44, min(preferredTileSize.height, (safeRect.height - totalGapH) / CGFloat(rows)))
        let tileSize  = CGSize(width: tileW, height: tileH)

        let gridW  = CGFloat(cols) * tileW + CGFloat(max(0, cols - 1)) * minGap
        let gridH  = CGFloat(rows) * tileH + CGFloat(max(0, rows - 1)) * minGap
        let startX = safeRect.midX - gridW / 2 + tileW / 2
        let startY = safeRect.midY - gridH / 2 + tileH / 2

        let jxMax = minGap * 0.12
        let jyMax = minGap * 0.12

        var positions: [CGPoint] = []
        positions.reserveCapacity(count)
        var idx = 0
        for r in 0..<rows {
            for c in 0..<cols {
                if idx >= count { break }
                let bx = startX + CGFloat(c) * (tileW + minGap)
                let by = startY + CGFloat(r) * (tileH + minGap)
                let jx = CGFloat.random(in: -jxMax...jxMax)
                let jy = CGFloat.random(in: -jyMax...jyMax)
                positions.append(CGPoint(x: bx + jx, y: by + jy))
                idx += 1
            }
        }
        positions.shuffle()
        return LetterLayout(tileSize: tileSize, positions: positions)
    }

    func arePositionsNonOverlapping(_ pts: [CGPoint], minDistance: CGFloat) -> Bool {
        let minSq = minDistance * minDistance
        for i in 0..<pts.count {
            for j in (i + 1)..<pts.count {
                let dx = pts[i].x - pts[j].x
                let dy = pts[i].y - pts[j].y
                if dx * dx + dy * dy < minSq { return false }
            }
        }
        return true
    }

    func randomNonOverlappingPositions(count: Int,
                                       in rect: CGRect,
                                       minDistance: CGFloat) -> [CGPoint] {
        var points:    [CGPoint] = []
        points.reserveCapacity(count)
        let minDistSq = minDistance * minDistance
        let maxAttempts = 4000
        var attempts    = 0

        while points.count < count && attempts < maxAttempts {
            attempts += 1
            let p = CGPoint(x: CGFloat.random(in: rect.minX...rect.maxX),
                            y: CGFloat.random(in: rect.minY...rect.maxY))
            var ok = true
            for q in points {
                let dx = p.x - q.x; let dy = p.y - q.y
                if dx * dx + dy * dy < minDistSq { ok = false; break }
            }
            if ok { points.append(p) }
        }
        if points.count < count { return points }
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
            if self.timeRemaining == 10 { self.startClockTick() }
            if self.timeRemaining <= 0 {
                t.invalidate()
                self.roundTimer = nil
                self.stopClockTick()
                self.roundTimeUp()
            }
        }
        if let roundTimer { RunLoop.main.add(roundTimer, forMode: .common) }
    }

    func updateTimerLabel() {
        let val = max(0, timeRemaining)
        timerLabel?.text = "Time: \(val)"
        if let shadow = timerLabel?.userData?["shadow"] as? SKLabelNode {
            shadow.text = timerLabel?.text
        }
        // Colour warning at ≤10s
        timerLabel?.fontColor = val <= 10 ? .red : .white
    }

    func startClockTick() {
        syncSettingsFromStore()
        guard isSoundEnabled, !isClockTicking else { return }
        isClockTicking = true
        let tick = SKAction.playSoundFileNamed(GameConfig.Audio.clock, waitForCompletion: true)
        run(SKAction.repeatForever(SKAction.sequence([tick])), withKey: "clockTick")
    }

    func stopClockTick() {
        removeAction(forKey: "clockTick")
        isClockTicking = false
    }

    func roundTimeUp() {
        roundActive = false
        stopClockTick()
        notificationFeedback(.warning)
        playSFX(GameConfig.Audio.wrong, waitForCompletion: false)
        for node in letterNodes {
            node.run(SKAction.fadeAlpha(to: 0.4, duration: 0.25))
        }
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        for node in letterNodes { node.physicsBody?.isDynamic = true }
        endGame()
    }

    // MARK: - Validation

    func validate(candidate: String, usedIndices: [Int]) {
        let upper = candidate.uppercased()
        guard upper.count >= 3 else {
            feedbackIncorrect(indices: usedIndices); return
        }
        guard possibleWords.contains(upper) else {
            feedbackIncorrect(indices: usedIndices); return
        }
        guard !foundWords.contains(upper) else {
            feedbackIncorrect(indices: usedIndices, alreadyFound: true); return
        }
        foundWords.insert(upper)
        let gained = WordGameLogic.pointsForWord(length: upper.count)
        score += gained
        feedbackCorrect(indices: usedIndices, wordLength: upper.count)
    }

    func feedbackCorrect(indices: [Int], wordLength: Int = 3) {
        playSFX(GameConfig.Audio.correct, waitForCompletion: false)
        let style: UIImpactFeedbackGenerator.FeedbackStyle = wordLength >= 5 ? .heavy : .medium
        impact(style)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.35, duration: 0.08),
            SKAction.scale(to: 1.0,  duration: 0.12)
        ])
        for idx in indices {
            guard idx >= 0 && idx < letterNodes.count else { continue }
            let node = letterNodes[idx]
            node.run(pulse)
            (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = .green
        }
        run(SKAction.wait(forDuration: 0.18)) { [weak self] in
            guard let self else { return }
            for idx in indices { self.unmarkLetter(at: idx) }
        }
    }

    func feedbackIncorrect(indices: [Int], alreadyFound: Bool = false) {
        playSFX(GameConfig.Audio.wrong, waitForCompletion: false)
        impact(.light)

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
        run(SKAction.wait(forDuration: 0.22)) { [weak self] in
            guard let self else { return }
            for idx in indices { self.unmarkLetter(at: idx) }
        }
    }
}
