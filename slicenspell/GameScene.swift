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

    // MARK: - Word Game State
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

    // Round progression
    private let roundWords: [String] = ["ORANGE", "PLANET", "STREAM", "CAMERA", "POCKET"]
    private var roundIndex: Int = 0
    private var perRoundFound: [[String]] = []

    // Small demo dictionary (replace with a real word list for production)
    private let demoDictionary: Set<String> = [
        "ORANGE", "RANGE", "GORE", "GEAR", "GONE", "EARN", "NEAR", "ONE", "RAN", "AGE", "EAR", "ARE",
        "PLANET", "PLANE", "PANEL", "LATE", "LEAN", "NEAT", "PEN", "NET", "TEN",
        "STREAM", "TEAMS", "TAMES", "STARE", "SEAM", "SAME", "TEAM", "MATE", "MEAT", "RATE",
        "CAMERA", "CREAM", "AMER", "ACRE", "CARE", "RACE", "MARE", "AREA",
        "POCKET", "POKE", "POET", "COKE", "TOKE", "POCKETS" // (note: POCKETS won't form from POCKET)
    ]

    // MARK: - UI Score/Lives (from original Slice)
    private var gameScore: SKLabelNode!
    private var score = 0 {
        didSet { gameScore.text = "Score: \(score)" }
    }

    private var livesImages = [SKSpriteNode]()
    private var lives = 3

    // MARK: - Swipe Trail (from original Slice)
    private var activeSliceBG: SKShapeNode!
    private var activeSliceFG: SKShapeNode!
    private var activeSlicePoints = [CGPoint]()

    // MARK: - (Mostly unused) Original Enemies
    private var activeEnemies = [SKSpriteNode]()
    private var isSwooshSoundActive = false
    private var bombSoundEffect: AVAudioPlayer?

    private var popupTime = 0.9
    private var sequence: [SequenceType]!
    private var sequencePosition = 0
    private var chainDelay = 3.0
    private var nextSequenceQueued = true

    // MARK: - Game End
    private var gameEnded = false
    private var gameOverOverlay: SKNode?

    // MARK: - Safe Area
    private var safeInsets: UIEdgeInsets = .zero
    private func effectiveRightPadding() -> CGFloat { max(24, safeInsets.right + 24) }
    private func effectiveTopPadding() -> CGFloat { max(32, safeInsets.top + 32) }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        // Capture safe area insets early (before positioning labels)
        if #available(iOS 11.0, *) {
            safeInsets = view.safeAreaInsets
        } else {
            safeInsets = .zero
        }

        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.speed = 0.85
        backgroundColor = .clear

        createScore()
        createLives()
        createSlices()
        createCurrentWordLabel()
        createTimerLabel()

        // (Original Slice) sequence creation retained but unused
        sequence = [.oneNoBomb, .oneNoBomb, .twoWithOneBomb, .twoWithOneBomb, .three, .one, .chain]
        for _ in 0 ... 1000 {
            let nextSequence = SequenceType.allCases.randomElement()!
            sequence.append(nextSequence)
        }

        // Prepare per-round tracking
        perRoundFound = Array(repeating: [], count: roundWords.count)

        // Start game
        startNewRound()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        // Reposition background if present
        if let bg = childNode(withName: "//sliceBackground") as? SKSpriteNode {
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
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

    // MARK: - UI Creation
    private func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: 0"
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        gameScore.position = CGPoint(x: 8, y: 8)
        gameScore.zPosition = 100
        addChild(gameScore)
    }

    private func createLives() {
        for i in 0 ..< 3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            spriteNode.zPosition = 100
            addChild(spriteNode)
            livesImages.append(spriteNode)
        }
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

    // MARK: - Touch Handling (Corrected)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard !gameEnded else { return }

        guard roundActive else {
            clearSelectionUIAndState()
            return
        }

        // Start fresh for each gesture
        clearSelectionUIAndState()
        activeSlicePoints.removeAll(keepingCapacity: true)

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        for node in nodes(at: location) {
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

        // Draw swipe path
        activeSlicePoints.append(location)
        redrawActiveSlice()
        activeSliceBG.alpha = 1
        activeSliceFG.alpha = 1

        // Select letters under the finger (no repeats)
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

        let candidate = buildSelectedWord()
        let usedIndices = selectedIndices // snapshot for feedback animations
        clearSelectionUIAndState()         // clear immediately (prevents stale selection bugs)

        validate(candidate: candidate, usedIndices: usedIndices)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Selection/UI Helpers
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
            (node.children.first as? SKLabelNode)?.fontColor = .yellow
        }
        node.run(scaleUp)
        node.run(colorize)
    }

    private func unmarkLetter(at index: Int) {
        guard index >= 0 && index < letterNodes.count else { return }
        let node = letterNodes[index]

        let scaleDown = SKAction.scale(to: 1.0, duration: 0.08)
        let colorize = SKAction.run {
            (node.children.first as? SKLabelNode)?.fontColor = .white
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

    // MARK: - Timer
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

        // Dim letters and let them fall
        for node in letterNodes { node.run(SKAction.fadeAlpha(to: 0.5, duration: 0.2)) }
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        for node in letterNodes { node.physicsBody?.isDynamic = true }

        // End game after time expires (or you can choose to advance rounds here)
        endGame(triggeredByBomb: false)
    }

    // MARK: - Word Validation (Corrected)
    private func validate(candidate: String, usedIndices: [Int]) {
        let upper = candidate.uppercased()

        // Require at least 3 letters
        guard upper.count >= 3 else {
            feedbackIncorrect(indices: usedIndices)
            return
        }

        // Ensure possibleWords is ready
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

        // Correct word
        foundWords.insert(upper)
        perRoundFound[roundIndex].append(upper)

        let gained = max(1, upper.count - 2)
        score += gained

        feedbackCorrect(indices: usedIndices)

        // If round complete, move on immediately
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
            (node.children.first as? SKLabelNode)?.fontColor = .green
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
            (node.children.first as? SKLabelNode)?.fontColor = alreadyFound ? .orange : .red
        }

        run(SKAction.wait(forDuration: 0.2)) { [weak self] in
            guard let self else { return }
            for idx in indices { self.unmarkLetter(at: idx) }
        }
    }

    private func generatePossibleWords(from letters: [Character]) -> Set<String> {
        // accept any dictionary word that can be formed from the multiset of letters
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

    // MARK: - Round Management
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
        // next round
        if roundIndex + 1 < roundWords.count {
            roundIndex += 1
            startNewRound()
        } else {
            // finished all rounds
            endGame(triggeredByBomb: false)
        }
    }

    private func startNewRound() {
        // Remove existing letter nodes
        for node in letterNodes { node.removeFromParent() }
        letterNodes.removeAll()

        // Reset physics for letter toss
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        foundWords.removeAll()
        possibleWords.removeAll()
        clearSelectionUIAndState()

        // Pick round base word
        let baseWord = roundWords[roundIndex].uppercased()

        // Scramble letters
        jumbledLetters = Array(baseWord)
        jumbledLetters.shuffle()

        // Build possible words for this round
        possibleWords = generatePossibleWords(from: jumbledLetters)

        // Layout letters
        let leftInset: CGFloat = max(40, safeInsets.left + 24)
        let rightInset: CGFloat = max(40, safeInsets.right + 24)
        let availableWidth = size.width - leftInset - rightInset

        let count = jumbledLetters.count
        let spacing = availableWidth / CGFloat(max(1, count))

        for (index, letter) in jumbledLetters.enumerated() {
            let letterNode = SKSpriteNode(color: .clear, size: CGSize(width: 64, height: 64))
            letterNode.name = "letter_\(index)"
            letterNode.zPosition = 10

            let startX = leftInset + spacing * (CGFloat(index) + 0.5)
            letterNode.position = CGPoint(x: startX, y: -64)

            let label = SKLabelNode(fontNamed: "Chalkduster")
            label.text = String(letter)
            label.fontSize = 44
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = .zero
            letterNode.addChild(label)

            letterNode.physicsBody = SKPhysicsBody(rectangleOf: letterNode.size)
            letterNode.physicsBody?.collisionBitMask = 0
            letterNode.physicsBody?.linearDamping = 0
            letterNode.physicsBody?.angularDamping = 0
            letterNode.physicsBody?.allowsRotation = false

            addChild(letterNode)
            letterNodes.append(letterNode)

            let safeTopY: CGFloat = size.height - safeInsets.top - 140
            let baseY: CGFloat = min(safeTopY, max(300, 0.6 * size.height))
            let targetY: CGFloat = baseY + CGFloat(Int.random(in: -20...20))

            let rise = SKAction.moveTo(y: targetY, duration: 0.6)
            rise.timingMode = .easeOut

            letterNode.run(rise) { [weak letterNode] in
                letterNode?.physicsBody?.isDynamic = false
            }
        }

        // UI reset
        for node in letterNodes { node.alpha = 1.0 }

        activeSlicePoints.removeAll(keepingCapacity: true)
        activeSliceBG.path = nil
        activeSliceFG.path = nil
        activeSliceBG.alpha = 0
        activeSliceFG.alpha = 0

        // Start round
        roundActive = true
        timeRemaining = 30
        updateTimerLabel()
        startRoundTimer(seconds: 30)
    }

    // MARK: - Game Over
    private func endGame(triggeredByBomb: Bool) {
        if gameEnded { return }
        gameEnded = true

        roundActive = false
        roundTimer?.invalidate()
        roundTimer = nil

        physicsWorld.speed = 0
        isUserInteractionEnabled = false

        bombSoundEffect?.stop()
        bombSoundEffect = nil

        if triggeredByBomb {
            livesImages[0].texture = SKTexture(imageNamed: "sliceLifeGone")
            livesImages[1].texture = SKTexture(imageNamed: "sliceLifeGone")
            livesImages[2].texture = SKTexture(imageNamed: "sliceLifeGone")
        }

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

        // Summarize last round info (or current round if time expired mid-round)
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

        let hint = SKLabelNode(fontNamed: "Chalkduster")
        hint.text = "Restart the app to play again"
        hint.fontSize = 22
        hint.fontColor = UIColor(white: 1, alpha: 0.8)
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        overlay.addChild(hint)
    }

    // MARK: - Swipe Trail Drawing
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

    // MARK: - (Unused) Original Slice Sound/Enemy Methods kept for compatibility
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

    override func update(_ currentTime: TimeInterval) {
        // (Intentionally unused for word mode)
    }
}

// MARK: - SwiftUI Preview
#Preview("GameScene Preview") {
    SpriteView(scene: {
        let scene = GameScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        return scene
    }())
    .ignoresSafeArea()
}
