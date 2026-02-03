import AVFoundation
import SpriteKit
import SwiftUI

enum ForceBomb {
    case never, always, random
}

enum SequenceType: CaseIterable {
    case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
}

final class GameScene: SKScene {

    private let roundDurationSeconds = 60
    private let bambooImageName = "bamboo_slice"

    private var jumbledLetters: [Character] = []
    private var letterNodes: [SKSpriteNode] = []
    private var selectedIndices: [Int] = []

    private var possibleWords: Set<String> = []
    private var foundWords: Set<String> = []

    private var roundTimer: Timer?
    private var timeRemaining: Int = 0
    private var roundActive: Bool = false

    private var timerLabel: SKLabelNode?
    private var currentWordLabel: SKLabelNode?

    private let roundWords: [String] = ["ORANGE", "PLANET", "STREAM", "CAMERA", "POCKET"]
    private var roundIndex: Int = 0
    private var perRoundFound: [[String]] = []

    private let demoDictionary: Set<String> = [
        "ORANGE", "ANGER", "ARGON", "ORGAN", "GROAN", "RANGE", "RANG", "RAGE", "OGRE", "ERGO", "AERO", "AEON", "GORE", "GEAR", "GONE", "EARN", "NEAR", "ORE", "ROE", "OAR", "AGO", "NAG", "NOR", "NOG", "EON", "EGO", "RAN", "RAG", "AGE", "EAR", "ERA", "ARE", "ONE",
        "PLANET", "PLANE", "PANEL", "LATE", "LEAN", "NEAT", "PEN", "NET", "TEN",
        "STREAM", "TEAMS", "TAMES", "STARE", "SEAM", "SAME", "TEAM", "MATE", "MEAT", "RATE",
        "CAMERA", "CREAM", "AMER", "ACRE", "CARE", "RACE", "MARE", "AREA",
        "POCKET", "POKE", "POET", "COKE", "TOKE", "POCKETS"
    ]

    private var gameScore: SKLabelNode!
    private var score = 0 {
        didSet { gameScore.text = "Score: \(score)" }
    }

    private var activeSliceBG: SKShapeNode!
    private var activeSliceFG: SKShapeNode!
    private var activeSlicePoints = [CGPoint]()

    private var activeEnemies = [SKSpriteNode]()
    private var isSwooshSoundActive = false
    private var bombSoundEffect: AVAudioPlayer?

    private var popupTime = 0.9
    private var sequence: [SequenceType]!
    private var sequencePosition = 0
    private var chainDelay = 3.0
    private var nextSequenceQueued = true

    private var gameEnded = false
    private var gameOverOverlay: SKNode?

    private var gameStarted = false
    private var startOverlay: SKNode?

    private var safeInsets: UIEdgeInsets = .zero
    private func effectiveRightPadding() -> CGFloat { max(24, safeInsets.right + 24) }
    private func effectiveTopPadding() -> CGFloat { max(32, safeInsets.top + 32) }

    override func didMove(to view: SKView) {
        if #available(iOS 11.0, *) {
            safeInsets = view.safeAreaInsets
        } else {
            safeInsets = .zero
        }

        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.blendMode = .replace
        background.zPosition = -1
        background.name = "sliceBackground"
        addChild(background)

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.speed = 0.85
        backgroundColor = .clear

        createScore()
        createSlices()
        createCurrentWordLabel()
        createTimerLabel()

        perRoundFound = Array(repeating: [], count: roundWords.count)

        gameStarted = false
        roundActive = false
        timeRemaining = 0
        updateTimerLabel()
        currentWordLabel?.text = ""

        showStartOverlay()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        if let bg = childNode(withName: "//sliceBackground") as? SKSpriteNode {
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)

            if let tex = bg.texture {
                let xScale = size.width / tex.size().width
                let yScale = size.height / tex.size().height
                let scale = max(xScale, yScale)
                bg.xScale = scale
                bg.yScale = scale
            }
        }

        let topPad = effectiveTopPadding()
        let rightPad = effectiveRightPadding()

        currentWordLabel?.position = CGPoint(x: size.width / 2, y: size.height - topPad)

        if let timerLabel = timerLabel {
            timerLabel.position = CGPoint(x: size.width - rightPad, y: size.height - topPad)
            if let shadow = timerLabel.userData?["shadow"] as? SKLabelNode {
                shadow.position = CGPoint(x: timerLabel.position.x + 1.5, y: timerLabel.position.y - 1.5)
            }
        }
    }

    private func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: 0"
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        gameScore.position = CGPoint(x: 8, y: 8)
        gameScore.zPosition = 100
        addChild(gameScore)
    }

    private func createSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        activeSliceBG.alpha = 0
        addChild(activeSliceBG)

        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        activeSliceFG.strokeColor = .white
        activeSliceFG.lineWidth = 5
        activeSliceFG.alpha = 0
        addChild(activeSliceFG)
    }

    private func createCurrentWordLabel() {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = ""
        label.fontSize = 40
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height - effectiveTopPadding())
        label.zPosition = 100
        addChild(label)
        currentWordLabel = label
    }

    private func createTimerLabel() {
        let topPad = effectiveTopPadding()
        let rightPad = effectiveRightPadding()

        let shadow = SKLabelNode(fontNamed: "Chalkduster")
        shadow.text = ""
        shadow.fontSize = 36
        shadow.fontColor = UIColor(white: 0, alpha: 0.5)
        shadow.horizontalAlignmentMode = .right
        shadow.verticalAlignmentMode = .center
        shadow.position = CGPoint(x: size.width - rightPad + 1.5, y: size.height - topPad - 1.5)
        shadow.zPosition = 99
        addChild(shadow)

        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = ""
        label.fontSize = 36
        label.fontColor = .white
        label.horizontalAlignmentMode = .right
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: size.width - rightPad, y: size.height - topPad)
        label.zPosition = 100
        addChild(label)
        timerLabel = label

        let dict = NSMutableDictionary()
        dict["shadow"] = shadow
        label.userData = dict
    }

    private func showStartOverlay() {
        startOverlay?.removeFromParent()

        let overlay = SKNode()
        overlay.zPosition = 999
        addChild(overlay)
        startOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.70), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        let title = SKLabelNode(fontNamed: "Chalkduster")
        title.text = "Word Ronin"
        title.fontSize = 64
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.70)
        overlay.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "Chalkduster")
        subtitle.text = "Swipe letters to make words"
        subtitle.fontSize = 22
        subtitle.fontColor = UIColor(white: 1, alpha: 0.85)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.63)
        overlay.addChild(subtitle)

        let start = SKLabelNode(fontNamed: "Chalkduster")
        start.text = "Start Game"
        start.fontSize = 38
        start.fontColor = .white
        start.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        start.name = "btn_start_game"
        overlay.addChild(start)

        let hint = SKLabelNode(fontNamed: "Chalkduster")
        hint.text = "Tap Start to begin"
        hint.fontSize = 18
        hint.fontColor = UIColor(white: 1, alpha: 0.75)
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.37)
        overlay.addChild(hint)
    }

    private func beginGame() {
        startOverlay?.removeFromParent()
        startOverlay = nil

        gameStarted = true
        gameEnded = false

        score = 0
        roundIndex = 0

        foundWords.removeAll()
        possibleWords.removeAll()
        selectedIndices.removeAll()
        jumbledLetters.removeAll()

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

        startNewRound()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        if !gameStarted {
            if tappedNodes.contains(where: { $0.name == "btn_start_game" || $0.parent?.name == "btn_start_game" }) {
                beginGame()
            }
            return
        }

        if gameEnded {
            if tappedNodes.contains(where: { $0.name == "btn_play_again" || $0.parent?.name == "btn_play_again" }) {
                restartGame()
            }
            return
        }

        guard roundActive else {
            clearSelectionUIAndState()
            return
        }

        clearSelectionUIAndState()
        activeSlicePoints.removeAll(keepingCapacity: true)

        for node in tappedNodes {
            if let nodeName = node.name,
               nodeName.hasPrefix("letter_"),
               let indexStr = nodeName.split(separator: "_").last,
               let index = Int(indexStr) {

                selectedIndices.append(index)
                markLetterSelected(at: index)
                updateCurrentWordLabel()
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameEnded || !roundActive { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        activeSlicePoints.append(location)
        redrawActiveSlice()
        activeSliceBG.alpha = 1
        activeSliceFG.alpha = 1

        for node in nodes(at: location) {
            if let nodeName = node.name,
               nodeName.hasPrefix("letter_"),
               let idxStr = nodeName.split(separator: "_").last,
               let idx = Int(idxStr) {

                if !selectedIndices.contains(idx) {
                    selectedIndices.append(idx)
                    markLetterSelected(at: idx)
                    updateCurrentWordLabel()
                }
                break
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSlicePoints.removeAll(keepingCapacity: true)
        activeSliceBG.path = nil
        activeSliceFG.path = nil

        guard roundActive else { return }
        guard !selectedIndices.isEmpty else { return }

        let candidate = buildSelectedWord()
        let usedIndices = selectedIndices
        clearSelectionUIAndState()

        validate(candidate: candidate, usedIndices: usedIndices)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func clearSelectionUIAndState() {
        for idx in selectedIndices { unmarkLetter(at: idx) }
        selectedIndices.removeAll()
        updateCurrentWordLabel()
    }

    private func markLetterSelected(at index: Int) {
        guard index >= 0 && index < letterNodes.count else { return }
        let node = letterNodes[index]

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.08)
        let colorize = SKAction.run {
            (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = .yellow
        }
        node.run(scaleUp)
        node.run(colorize)
    }

    private func unmarkLetter(at index: Int) {
        guard index >= 0 && index < letterNodes.count else { return }
        let node = letterNodes[index]

        let scaleDown = SKAction.scale(to: 1.0, duration: 0.08)
        let colorize = SKAction.run {
            (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = .white
        }
        node.run(scaleDown)
        node.run(colorize)
    }

    private func updateCurrentWordLabel() {
        currentWordLabel?.text = buildSelectedWord()
    }

    private func buildSelectedWord() -> String {
        let chars: [Character] = selectedIndices.map { jumbledLetters[$0] }
        return String(chars)
    }

    private func startRoundTimer(seconds: Int) {
        roundTimer?.invalidate()
        timeRemaining = seconds
        updateTimerLabel()

        roundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else { return }
            self.timeRemaining -= 1
            self.updateTimerLabel()
            if self.timeRemaining <= 0 {
                t.invalidate()
                self.roundTimer = nil
                self.roundTimeUp()
            }
        }
        RunLoop.main.add(roundTimer!, forMode: .common)
    }

    private func updateTimerLabel() {
        timerLabel?.text = "⏱️ \(max(0, timeRemaining))"
        if let shadow = timerLabel?.userData?["shadow"] as? SKLabelNode {
            shadow.text = timerLabel?.text
        }
    }

    private func roundTimeUp() {
        roundActive = false

        run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))

        for node in letterNodes { node.run(SKAction.fadeAlpha(to: 0.5, duration: 0.2)) }
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        for node in letterNodes { node.physicsBody?.isDynamic = true }

        endGame(triggeredByBomb: false)
    }

    private func pointsForWord(length: Int) -> Int {
        let perLetter = 50
        let base = perLetter * length

        let bonus: Int
        switch length {
        case 0...3: bonus = 0
        case 4: bonus = 50
        case 5: bonus = 150
        default: bonus = 300
        }

        return base + bonus
    }

    private func validate(candidate: String, usedIndices: [Int]) {
        let upper = candidate.uppercased()

        guard upper.count >= 3 else {
            feedbackIncorrect(indices: usedIndices)
            return
        }

        if possibleWords.isEmpty {
            possibleWords = generatePossibleWords(from: jumbledLetters)
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
        perRoundFound[roundIndex].append(upper)

        let gained = pointsForWord(length: upper.count)
        score += gained

        feedbackCorrect(indices: usedIndices)

        if foundWords.count == possibleWords.count {
            roundComplete()
        }
    }

    private func feedbackCorrect(indices: [Int]) {
        run(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))

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

    private func feedbackIncorrect(indices: [Int], alreadyFound: Bool = false) {
        run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))

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

    private func generatePossibleWords(from letters: [Character]) -> Set<String> {
        let pool = letters.map { String($0).uppercased() }
        var counts: [String: Int] = [:]
        for l in pool { counts[l, default: 0] += 1 }

        func canForm(_ word: String) -> Bool {
            var c = counts
            for ch in word {
                let key = String(ch).uppercased()
                guard let left = c[key], left > 0 else { return false }
                c[key] = left - 1
            }
            return true
        }

        return Set(demoDictionary.map { $0.uppercased() }.filter { canForm($0) })
    }

    private func roundComplete() {
        roundActive = false
        roundTimer?.invalidate()
        roundTimer = nil

        run(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))

        run(SKAction.wait(forDuration: 0.35)) { [weak self] in
            guard let self else { return }
            self.advanceRoundOrEnd()
        }
    }

    private func advanceRoundOrEnd() {
        if roundIndex + 1 < roundWords.count {
            roundIndex += 1
            startNewRound()
        } else {
            endGame(triggeredByBomb: false)
        }
    }

    private func startNewRound() {
        for node in letterNodes { node.removeFromParent() }
        letterNodes.removeAll()

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        foundWords.removeAll()
        possibleWords.removeAll()
        clearSelectionUIAndState()

        let baseWord = roundWords[roundIndex].uppercased()
        jumbledLetters = Array(baseWord)
        jumbledLetters.shuffle()

        possibleWords = generatePossibleWords(from: jumbledLetters)

        let letterSize = CGSize(width: 72, height: 72)

        let leftInset: CGFloat = max(30, safeInsets.left + 24)
        let rightInset: CGFloat = max(30, safeInsets.right + 24)
        let bottomInset: CGFloat = 120
        let topInset: CGFloat = max(220, safeInsets.top + 220)

        let playableRect = CGRect(
            x: leftInset + letterSize.width * 0.6,
            y: bottomInset + letterSize.height * 0.6,
            width: size.width - leftInset - rightInset - letterSize.width * 1.2,
            height: size.height - topInset - bottomInset - letterSize.height * 1.2
        )

        let minCenterDistance: CGFloat = 150
        let targets = randomNonOverlappingPositions(
            count: jumbledLetters.count,
            in: playableRect,
            minDistance: minCenterDistance
        )

        for (index, letter) in jumbledLetters.enumerated() {
            let letterNode = SKSpriteNode(color: .clear, size: CGSize(width: 118, height: 92))
            letterNode.name = "letter_\(index)"
            letterNode.zPosition = 10

            let target = targets[index]
            letterNode.position = CGPoint(x: target.x, y: -90)

            let bamboo = SKSpriteNode(imageNamed: bambooImageName)
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

            letterNode.zRotation = 0
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

        activeSlicePoints.removeAll(keepingCapacity: true)
        activeSliceBG.path = nil
        activeSliceFG.path = nil
        activeSliceBG.alpha = 0
        activeSliceFG.alpha = 0

        roundActive = true
        timeRemaining = roundDurationSeconds
        updateTimerLabel()
        startRoundTimer(seconds: roundDurationSeconds)
    }

    private func randomNonOverlappingPositions(count: Int, in rect: CGRect, minDistance: CGFloat) -> [CGPoint] {
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

    private func endGame(triggeredByBomb: Bool) {
        if gameEnded { return }
        gameEnded = true

        roundActive = false
        roundTimer?.invalidate()
        roundTimer = nil

        physicsWorld.speed = 0

        bombSoundEffect?.stop()
        bombSoundEffect = nil

        showGameOverOverlay()
    }

    private func showGameOverOverlay() {
        gameOverOverlay?.removeFromParent()

        let overlay = SKNode()
        overlay.zPosition = 1000
        addChild(overlay)
        gameOverOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.75), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        let title = SKLabelNode(fontNamed: "Chalkduster")
        title.text = "Game Over"
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

        let missing = Array(possibleWords.subtracting(foundWords)).sorted()
        let found = Array(foundWords).sorted()

        let foundLabel = SKLabelNode(fontNamed: "Chalkduster")
        foundLabel.text = "Found (\(found.count)): \(found.joined(separator: ", "))"
        foundLabel.fontSize = 20
        foundLabel.fontColor = .white
        foundLabel.horizontalAlignmentMode = .center
        foundLabel.verticalAlignmentMode = .top
        foundLabel.numberOfLines = 0
        foundLabel.preferredMaxLayoutWidth = size.width * 0.9
        foundLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        overlay.addChild(foundLabel)

        let missingLabel = SKLabelNode(fontNamed: "Chalkduster")
        missingLabel.text = "Missing (\(missing.count)): \(missing.joined(separator: ", "))"
        missingLabel.fontSize = 20
        missingLabel.fontColor = .white
        missingLabel.horizontalAlignmentMode = .center
        missingLabel.verticalAlignmentMode = .top
        missingLabel.numberOfLines = 0
        missingLabel.preferredMaxLayoutWidth = size.width * 0.9
        missingLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        overlay.addChild(missingLabel)

        let playAgain = SKLabelNode(fontNamed: "Chalkduster")
        playAgain.text = "Play Again"
        playAgain.fontSize = 34
        playAgain.fontColor = .white
        playAgain.position = CGPoint(x: size.width / 2, y: size.height * 0.20)
        playAgain.name = "btn_play_again"
        overlay.addChild(playAgain)

        let subHint = SKLabelNode(fontNamed: "Chalkduster")
        subHint.text = "Tap to restart"
        subHint.fontSize = 18
        subHint.fontColor = UIColor(white: 1, alpha: 0.75)
        subHint.position = CGPoint(x: size.width / 2, y: size.height * 0.16)
        overlay.addChild(subHint)
    }

    private func restartGame() {
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil

        roundTimer?.invalidate()
        roundTimer = nil

        physicsWorld.speed = 0.85
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        gameEnded = false
        gameStarted = false

        score = 0
        roundIndex = 0

        foundWords.removeAll()
        possibleWords.removeAll()
        selectedIndices.removeAll()
        jumbledLetters.removeAll()

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

        showStartOverlay()
    }

    private func redrawActiveSlice() {
        guard activeSlicePoints.count >= 2 else {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }

        while activeSlicePoints.count > 12 {
            activeSlicePoints.remove(at: 0)
        }

        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        for i in 1 ..< activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }

        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
    }

    private func playSwooshSound() {
        isSwooshSoundActive = true
        let randomNumber = Int.random(in: 1...3)
        let soundName = "swoosh\(randomNumber).caf"
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        run(swooshSound) { [unowned self] in
            self.isSwooshSoundActive = false
        }
    }

    private func createEnemy(forceBomb: ForceBomb = .random) {
        var enemy: SKSpriteNode
        var enemyType = Int.random(in: 0...6)

        if forceBomb == .never { enemyType = 1 }
        else if forceBomb == .always { enemyType = 0 }

        if enemyType == 0 {
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"

            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)

            bombSoundEffect?.stop()
            bombSoundEffect = nil

            if let url = Bundle.main.url(forResource: "sliceBombFuse", withExtension: "caf"),
               let sound = try? AVAudioPlayer(contentsOf: url) {
                bombSoundEffect = sound
                sound.play()
            }

            if let emitter = SKEmitterNode(fileNamed: "sliceFuse") {
                emitter.position = CGPoint(x: 76, y: 64)
                enemy.addChild(emitter)
            }
        } else {
            enemy = SKSpriteNode(imageNamed: "penguin")
            run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }

        let randomPosition = CGPoint(x: Int.random(in: 64...960), y: -128)
        enemy.position = randomPosition

        let randomAngularVelocity = CGFloat.random(in: -6...6) / 2.0
        var randomXVelocity = 0

        if randomPosition.x < 256 { randomXVelocity = Int.random(in: 8...15) }
        else if randomPosition.x < 512 { randomXVelocity = Int.random(in: 3...5) }
        else if randomPosition.x < 768 { randomXVelocity = -Int.random(in: 3...5) }
        else { randomXVelocity = -Int.random(in: 8...15) }

        let randomYVelocity = Int.random(in: 24...32)

        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody?.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        enemy.physicsBody?.angularVelocity = randomAngularVelocity
        enemy.physicsBody?.collisionBitMask = 0

        addChild(enemy)
        activeEnemies.append(enemy)
    }

    override func update(_ currentTime: TimeInterval) { }
}

#Preview("GameScene – iPad Landscape", traits: .landscapeLeft) {
    SpriteView(scene: {
        let scene = GameScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .aspectFill
        return scene
    }())
    .ignoresSafeArea()
}
