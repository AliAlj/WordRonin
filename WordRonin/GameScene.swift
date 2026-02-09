// GameScene.swift
import AVFoundation
import SpriteKit
import SwiftUI
import UIKit

extension Notification.Name {
    static let exitSliceMode = Notification.Name("exitSliceMode")
}

enum ForceBomb {
    case never, always, random
}

enum SequenceType: CaseIterable {
    case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
}

final class GameScene: SKScene {

    private let roundDurationSeconds = 60

    // Assets
    private let bambooImageName = "bamboo_slice"         // letter tile bamboo
    private let buttonBambooImageName = "fullBamboo"     // button background
    private let inGameBackgroundName = "sliceBackground" // in-game background (slice + listen)
    private let menuBackgroundName = "gameBackground"    // lobby/menu background

    // Button names (separate so menu/tutorial/gameplay don’t conflict)
    private let menuBackButtonName = "btn_menu_back"
    private let tutorialBackButtonName = "btn_tutorial_back"
    private let inGameBackButtonName = "btn_ingame_back"

    // In-game back button node
    private var inGameBackButton: SKNode?

    // One random base word per game start
    private let startWords: [String] = ["ORANGE", "PLANET", "STREAM", "CAMERA", "POCKET", "APRICOT"]

    private var baseLetters: [Character] = []
    private var letterNodes: [SKSpriteNode] = []
    private var selectedIndices: [Int] = []

    private var possibleWords: Set<String> = []
    private var foundWords: Set<String> = []

    private var roundTimer: Timer?
    private var timeRemaining: Int = 0
    private var roundActive: Bool = false

    private var timerLabel: SKLabelNode?
    private var currentWordLabel: SKLabelNode?

    private var gameScore: SKLabelNode!
    private var score = 0 {
        didSet { gameScore.text = "Score: \(score)" }
    }

    private var activeSliceBG: SKShapeNode!
    private var activeSliceFG: SKShapeNode!
    private var activeSlicePoints = [CGPoint]()

    private var gameEnded = false
    private var gameOverOverlay: SKNode?

    private var gameStarted = false
    private var startOverlay: SKNode?

    private var tutorialOverlay: SKNode?

    private var safeInsets: UIEdgeInsets = .zero
    private func effectiveRightPadding() -> CGFloat { max(24, safeInsets.right + 24) }
    private func effectiveTopPadding() -> CGFloat { max(32, safeInsets.top + 32) }

    // Background node name
    private let backgroundNodeName = "scene_background"

    // Keep references to the menu buttons so we can fade them when tutorial is shown
    private var startMenuButtonsContainer: SKNode?

    private let demoDictionary: Set<String> = [
        // ORANGE
        "ORANGE",
        "ANGER","ARGON","ORGAN","GROAN","RANGE",
        "RANG","RAGE","OGRE","ERGO","AERO","AEON","GORE","GEAR","GONE","EARN","NEAR",
        "ORE","ROE","OAR","AGO","NAG","NOR","EON","EGO","RAN","RAG","AGE","EAR","ERA","ARE","ONE",

        // PLANET
        "PLANET",
        "PLANE","PANEL","PETAL","PLATE","LEAPT","PALET","PENAL",
        "PLEA","PEAL","PALE","LEAP","PELT","LENT","LATE","LEAN","NEAT","TAPE","PATE","PEAT",
        "PAN","PEN","NET","TEN","ANT","TAN","NAP","PAL","LAT","LET","ALE","LEA","APE","EAT","TEA","ATE","TAP","PAT","PET",

        // STREAM
        "STREAM","MASTER","TAMERS",
        "SMEAR","STARE","TEARS","RATES","TAMES","TEAMS",
        "SAME","SEAM","TEAM","MATE","MEAT","TAME","EAST","SEAT","RATE","STAR","EARS","TEAR",
        "ARM","RAM","TAR","RAT","ART","MET","SET","SEA","EAT","ATE","TEA",

        // CAMERA
        "CAMERA","CREAM",
        "ACRE","CARE","RACE","MARE","AREA",
        "ARC","CAR","ARM","RAM","ERA","ARE","ACE",

        // POCKET
        "POCKET",
        "POKE","POET","COKE","TOKE","POCK","TOCK","PECK","COPE","COTE",
        "PET","POT","TOP","COP","TOE","ECO",

        // APRICOT
        "APRICOT",
        "TOPIC","PATIO","OPTIC","CAPRI",
        "PAIR","TRAP","PORT","PART","TARP",
        "RIP","TIP","PIT","ART","RAT","TAR","TAP","PAT","COP","CAP","CAR","ARC","RAP","PAR","PRO"
    ]

    override func didMove(to view: SKView) {
        if #available(iOS 11.0, *) {
            safeInsets = view.safeAreaInsets
        } else {
            safeInsets = .zero
        }

        ensureBackground(named: menuBackgroundName)

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.speed = 0.85
        backgroundColor = .clear

        createScore()
        createSlices()
        createCurrentWordLabel()
        createTimerLabel()

        gameStarted = false
        roundActive = false
        gameEnded = false
        timeRemaining = 0
        updateTimerLabel()
        currentWordLabel?.text = ""

        hideInGameBackButton()

        showStartOverlay()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        resizeBackground()

        if let startOverlay = startOverlay {
            startOverlay.removeFromParent()
            self.startOverlay = nil
            showStartOverlay()
        }

        if let tutorialOverlay = tutorialOverlay {
            tutorialOverlay.removeFromParent()
            self.tutorialOverlay = nil
            showTutorialOverlay()
        }

        if let gameOverOverlay = gameOverOverlay {
            gameOverOverlay.removeFromParent()
            self.gameOverOverlay = nil
            showGameOverOverlay()
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

        if gameStarted && !gameEnded {
            showInGameBackButton()
        }
    }

    // MARK: - Background Helpers

    private func ensureBackground(named imageName: String) {
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

    private func resizeBackground() {
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

    private func setMenuBackground() { ensureBackground(named: menuBackgroundName) }
    private func setInGameBackground() { ensureBackground(named: inGameBackgroundName) }

    // MARK: - UI Helpers (FullBamboo buttons)

    private func makeBambooButton(
        title: String,
        name: String,
        position: CGPoint,
        size: CGSize = CGSize(width: 360, height: 92),
        fontSize: CGFloat = 30
    ) -> SKNode {
        let container = SKNode()
        container.name = name
        container.position = position
        container.zPosition = 1001

        let bg = SKSpriteNode(imageNamed: buttonBambooImageName)
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

    private func addTopLeftBackButton(to parent: SKNode, title: String = "Back", name: String) {
        // narrower on purpose (your screenshot showed it too wide)
        let w = min(230, size.width * 0.18)
        let h: CGFloat = 140

        let x = max(18, safeInsets.left + 18) + w * 0.5
        let y = size.height - (max(18, safeInsets.top + 18) + h * 0.5)

        let btn = makeBambooButton(
            title: title,
            name: name,
            position: CGPoint(x: x, y: y),
            size: CGSize(width: w, height: h),
            fontSize: 22
        )

        parent.addChild(btn)
    }

    // In-game back button
    private func showInGameBackButton() {
        inGameBackButton?.removeFromParent()

        // narrower than before
        let w = min(230, size.width * 0.18)
        let h: CGFloat = 140

        let x = max(18, safeInsets.left + 18) + w * 0.5
        let y = size.height - (max(18, safeInsets.top + 18) + h * 0.5)

        let btn = makeBambooButton(
            title: "Back",
            name: inGameBackButtonName,
            position: CGPoint(x: x, y: y),
            size: CGSize(width: w, height: h),
            fontSize: 22
        )

        btn.zPosition = 1500
        addChild(btn)
        inGameBackButton = btn
    }

    private func hideInGameBackButton() {
        inGameBackButton?.removeFromParent()
        inGameBackButton = nil
    }

    private func tapped(_ tappedNodes: [SKNode], matches name: String) -> Bool {
        tappedNodes.contains(where: { $0.name == name || $0.parent?.name == name })
    }

    // MARK: - HUD

    private func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: 0"
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        gameScore.position = CGPoint(x: 16, y: 16)
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

    // MARK: - Overlays

    private func setMenuButtonsFaded(_ faded: Bool) {
        guard let container = startMenuButtonsContainer else { return }
        let target: CGFloat = faded ? 0.18 : 1.0
        container.run(SKAction.fadeAlpha(to: target, duration: 0.12))
    }

    private func showStartOverlay() {
        setMenuBackground()

        startOverlay?.removeFromParent()
        hideInGameBackButton()

        let overlay = SKNode()
        overlay.zPosition = 999
        addChild(overlay)
        startOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.55), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        // Top-left back on the main menu (exits Slice Mode)
        addTopLeftBackButton(to: overlay, title: "Back", name: menuBackButtonName)

        let title = SKLabelNode(fontNamed: "Chalkduster")
        title.text = "Word Ronin"
        title.fontSize = 64
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        overlay.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "Chalkduster")
        subtitle.text = "Swipe letters to make words"
        subtitle.fontSize = 22
        subtitle.fontColor = UIColor(white: 1, alpha: 0.85)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        overlay.addChild(subtitle)

        // Buttons container (so we can fade them while tutorial overlay is up)
        startMenuButtonsContainer?.removeFromParent()
        let buttons = SKNode()
        buttons.zPosition = 1001
        overlay.addChild(buttons)
        startMenuButtonsContainer = buttons

        let startBtn = makeBambooButton(
            title: "Start Game",
            name: "btn_start_game",
            position: CGPoint(x: size.width / 2, y: size.height * 0.44),
            size: CGSize(width: min(420, size.width * 0.52), height: 220),
            fontSize: 32
        )
        buttons.addChild(startBtn)

        let howBtn = makeBambooButton(
            title: "How to Play",
            name: "btn_how_to_play",
            position: CGPoint(x: size.width / 2, y: size.height * 0.28),
            size: CGSize(width: min(320, size.width * 0.72), height: 180),
            fontSize: 28
        )
        buttons.addChild(howBtn)

        setMenuButtonsFaded(false)
    }

    private func showTutorialOverlay() {
        tutorialOverlay?.removeFromParent()

        // Fade the menu buttons underneath
        setMenuButtonsFaded(true)

        let overlay = SKNode()
        overlay.zPosition = 2000
        addChild(overlay)
        tutorialOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.86), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        // ONLY tutorial back button (unique name)
        addTopLeftBackButton(to: overlay, title: "Back", name: tutorialBackButtonName)

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

        // NEW: rules text (your request)
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

        let s3 = pointsForWord(length: 3)
        let s4 = pointsForWord(length: 4)
        let s5 = pointsForWord(length: 5)
        let s6 = pointsForWord(length: 6)

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

            let bamboo = SKSpriteNode(imageNamed: bambooImageName)
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

    private func runTutorialAnimation(line: SKShapeNode, dot: SKShapeNode, letterNodes: [SKNode], points: [CGPoint]) {
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

    private func hideTutorialOverlay() {
        tutorialOverlay?.removeAllActions()
        tutorialOverlay?.removeFromParent()
        tutorialOverlay = nil
        setMenuButtonsFaded(false)
    }

    // MARK: - Game Start

    private func beginGame() {
        startOverlay?.removeFromParent()
        startOverlay = nil
        hideTutorialOverlay()

        setInGameBackground()
        showInGameBackButton()

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
        timeRemaining = roundDurationSeconds
        updateTimerLabel()

        activeSlicePoints.removeAll(keepingCapacity: true)
        activeSliceBG.path = nil
        activeSliceFG.path = nil
        activeSliceBG.alpha = 0
        activeSliceFG.alpha = 0

        startNewGameWord()
    }

    private func startNewGameWord() {
        var chosen = startWords.randomElement() ?? "ORANGE"
        if startWords.count > 1 {
            var tries = 0
            while chosen == String(baseLetters) && tries < 10 {
                chosen = startWords.randomElement() ?? chosen
                tries += 1
            }
        }

        baseLetters = Array(chosen.uppercased())
        baseLetters.shuffle()

        possibleWords = generatePossibleWords(from: baseLetters, minLength: 3)
        foundWords.removeAll()

        spawnLetters(letters: baseLetters)

        roundActive = true
        startRoundTimer(seconds: roundDurationSeconds)
    }

    private func spawnLetters(letters: [Character]) {
        for node in letterNodes { node.removeFromParent() }
        letterNodes.removeAll()

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

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

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Tutorial: ONLY its own back button works
        if tutorialOverlay != nil {
            if tapped(tappedNodes, matches: tutorialBackButtonName) {
                hideTutorialOverlay()
            }
            return
        }

        // Menu
        if !gameStarted {
            if tapped(tappedNodes, matches: menuBackButtonName) {
                NotificationCenter.default.post(name: .exitSliceMode, object: nil)
                return
            }

            if tapped(tappedNodes, matches: "btn_how_to_play") {
                showTutorialOverlay()
                return
            }

            if tapped(tappedNodes, matches: "btn_start_game") {
                beginGame()
                return
            }

            return
        }

        // Gameplay back button
        if tapped(tappedNodes, matches: inGameBackButtonName) {
            restartGame()
            return
        }

        if gameEnded {
            if tapped(tappedNodes, matches: "btn_play_again") {
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

    // MARK: - Word UI

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
        let chars: [Character] = selectedIndices.compactMap { idx in
            guard idx >= 0 && idx < baseLetters.count else { return nil }
            return baseLetters[idx]
        }
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

        if let roundTimer {
            RunLoop.main.add(roundTimer, forMode: .common)
        }
    }

    private func updateTimerLabel() {
        timerLabel?.text = "Time: \(max(0, timeRemaining))"
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

        endGame()
    }

    // MARK: - Scoring / Validation

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

        guard possibleWords.contains(upper) else {
            feedbackIncorrect(indices: usedIndices)
            return
        }

        guard !foundWords.contains(upper) else {
            feedbackIncorrect(indices: usedIndices, alreadyFound: true)
            return
        }

        foundWords.insert(upper)

        let gained = pointsForWord(length: upper.count)
        score += gained

        feedbackCorrect(indices: usedIndices)
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

    private func generatePossibleWords(from letters: [Character], minLength: Int) -> Set<String> {
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

        return Set(
            demoDictionary
                .map { $0.uppercased() }
                .filter { $0.count >= minLength && canForm($0) }
        )
    }

    // MARK: - Game Over

    private func endGame() {
        if gameEnded { return }

        gameEnded = true
        roundActive = false

        roundTimer?.invalidate()
        roundTimer = nil

        physicsWorld.speed = 0

        showGameOverOverlay()
    }

    private func sortWordsHighToLow(_ words: [String]) -> [String] {
        words.sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0 < $1
        }
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
            name: "btn_play_again",
            position: CGPoint(x: size.width / 2, y: size.height * 0.20),
            size: CGSize(width: min(420, size.width * 0.72), height: 200),
            fontSize: 30
        )
        overlay.addChild(playAgainBtn)
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

    // MARK: - Slice Drawing

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

    // MARK: - Positioning

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
