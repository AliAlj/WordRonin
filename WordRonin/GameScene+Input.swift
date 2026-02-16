//  GameScene+Input.swift
import SpriteKit

extension GameScene {

    // MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        syncSettingsFromStore()
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // 1. Tutorial Overlay
        if tutorialOverlay != nil {
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.tutorialBack) {
                hideTutorialOverlay()
            }
            return
        }

        // 2. Settings Overlay
        if settingsOverlay != nil {
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.closeSettings) {
                hideSettingsOverlay()
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.toggleSound) {
                AppSettingsStore.soundEnabled.toggle()
                syncSettingsFromStore()
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.toggleMusic) {
                AppSettingsStore.musicEnabled.toggle()
                syncSettingsFromStore()

                if gameStarted && !gameEnded {
                    if isMusicEnabled {
                        AudioManager.shared.playMusic(fileName: GameConfig.Audio.musicSlice, volume: 0.15)
                    } else {
                        AudioManager.shared.stopMusic()
                    }
                } else {
                    AudioManager.shared.stopMusic()
                }
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.dojoAction) {
                hideSettingsOverlay()
                return
            }
            return
        }

        // 3. Main Menu
        if !gameStarted {
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.menuBack) {
                AudioManager.shared.stopMusic()
                NotificationCenter.default.post(name: .exitSliceMode, object: nil)
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.howToPlay) {
                showTutorialOverlay()
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.start) {
                beginGame()
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.settings) {
                showSettingsOverlay()
                return
            }
            return
        }

        // 4. In-Game
        if tapped(tappedNodes, matches: GameConfig.ButtonNames.inGameBack) {
            restartGame()
            return
        }

        if gameEnded {
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.playAgain) {
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

                playSFX(GameConfig.Audio.hit, waitForCompletion: false)
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameEnded || !roundActive { return }
        syncSettingsFromStore()
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

                    playSFX(GameConfig.Audio.hit, waitForCompletion: false)
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

    func tapped(_ tappedNodes: [SKNode], matches name: String) -> Bool {
        tappedNodes.contains(where: { $0.name == name || $0.parent?.name == name })
    }

    // MARK: - Selection UI
    func clearSelectionUIAndState() {
        for idx in selectedIndices { unmarkLetter(at: idx) }
        selectedIndices.removeAll()
        updateCurrentWordLabel()
    }

    func markLetterSelected(at index: Int) {
        guard index >= 0 && index < letterNodes.count else { return }
        let node = letterNodes[index]

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.08)
        let colorize = SKAction.run {
            (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = .yellow
        }

        node.run(scaleUp)
        node.run(colorize)
    }

    func unmarkLetter(at index: Int) {
        guard index >= 0 && index < letterNodes.count else { return }
        let node = letterNodes[index]

        let scaleDown = SKAction.scale(to: 1.0, duration: 0.08)
        let colorize = SKAction.run {
            (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = .white
        }

        node.run(scaleDown)
        node.run(colorize)
    }

    func updateCurrentWordLabel() {
        let built = buildSelectedWord()
        currentWordLabel?.text = built

        let shouldAnimate = built.count > lastBuiltCount
        updateWordBuildBar(animated: shouldAnimate)
    }

    func buildSelectedWord() -> String {
        let chars: [Character] = selectedIndices.compactMap { idx in
            guard idx >= 0 && idx < baseLetters.count else { return nil }
            return baseLetters[idx]
        }
        return String(chars)
    }

    // MARK: - Slice Drawing
    func createSlices() {
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

    func redrawActiveSlice() {
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
}

