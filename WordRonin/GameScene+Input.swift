// GameScene+Input.swift
import SpriteKit
import UIKit

extension GameScene {

    // MARK: - Touches Began

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        syncSettingsFromStore()
        guard let touch = touches.first else { return }
        let location    = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // 1. Tutorial overlay captures all input
        if tutorialOverlay != nil {
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.tutorialBack) {
                hideTutorialOverlay()
            }
            return
        }

        // 2. Settings overlay
        if settingsOverlay != nil {
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.closeSettings) {
                animateTap(tappedNodes, name: GameConfig.ButtonNames.closeSettings)
                hideSettingsOverlay()
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.toggleSound) {
                animateTap(tappedNodes, name: GameConfig.ButtonNames.toggleSound)
                AppSettingsStore.soundEnabled.toggle()
                syncSettingsFromStore()
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.toggleMusic) {
                animateTap(tappedNodes, name: GameConfig.ButtonNames.toggleMusic)
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
                animateTap(tappedNodes, name: GameConfig.ButtonNames.dojoAction)
                hideSettingsOverlay()
                return
            }
            return
        }

        // 3. Main menu
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
                animateTap(tappedNodes, name: GameConfig.ButtonNames.start)
                run(SKAction.wait(forDuration: 0.12)) { [weak self] in self?.beginGame() }
                return
            }
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.settings) {
                showSettingsOverlay()
                return
            }
            return
        }

        // 4. In-game back button
        if tapped(tappedNodes, matches: GameConfig.ButtonNames.inGameBack) {
            restartGame()
            return
        }

        // 5. Game over
        if gameEnded {
            if tapped(tappedNodes, matches: GameConfig.ButtonNames.playAgain) {
                animateTap(tappedNodes, name: GameConfig.ButtonNames.playAgain)
                run(SKAction.wait(forDuration: 0.12)) { [weak self] in self?.restartGame() }
            }
            return
        }

        // 6. Active game — letter selection
        guard roundActive else {
            clearSelectionUIAndState()
            return
        }

        clearSelectionUIAndState()
        activeSlicePoints.removeAll(keepingCapacity: true)

        for node in tappedNodes {
            if let (idx, _) = letterInfo(from: node) {
                selectedIndices.append(idx)
                markLetterSelected(at: idx)
                updateCurrentWordLabel()
                playSFX(GameConfig.Audio.hit, waitForCompletion: false)
                break
            }
        }
    }

    // MARK: - Touches Moved

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameEnded, roundActive else { return }
        syncSettingsFromStore()
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        activeSlicePoints.append(location)
        redrawActiveSlice()
        activeSliceBG.alpha = 1
        activeSliceFG.alpha = 1

        for node in nodes(at: location) {
            if let (idx, _) = letterInfo(from: node), !selectedIndices.contains(idx) {
                selectedIndices.append(idx)
                markLetterSelected(at: idx)
                updateCurrentWordLabel()
                playSFX(GameConfig.Audio.hit, waitForCompletion: false)
                break
            }
        }
    }

    // MARK: - Touches Ended / Cancelled

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSlicePoints.removeAll(keepingCapacity: true)
        activeSliceBG.path = nil
        activeSliceFG.path = nil

        guard roundActive, !selectedIndices.isEmpty else { return }

        let candidate   = buildSelectedWord()
        let usedIndices = selectedIndices
        clearSelectionUIAndState()
        validate(candidate: candidate, usedIndices: usedIndices)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Helpers

    func tapped(_ tappedNodes: [SKNode], matches name: String) -> Bool {
        tappedNodes.contains { $0.name == name || $0.parent?.name == name }
    }

    /// Returns the letter index and letter for a node named "letter_N" or its child.
    private func letterInfo(from node: SKNode) -> (Int, Character)? {
        let target = (node.name?.hasPrefix("letter_") == true) ? node : node.parent
        guard let name = target?.name, name.hasPrefix("letter_"),
              let idxStr = name.split(separator: "_").last,
              let idx = Int(idxStr),
              idx >= 0, idx < baseLetters.count
        else { return nil }
        return (idx, baseLetters[idx])
    }

    /// Brief scale pulse on a button node.
    private func animateTap(_ nodes: [SKNode], name: String) {
        guard let node = nodes.first(where: { $0.name == name || $0.parent?.name == name }) else { return }
        let target = node.parent?.name == name ? node.parent! : node
        let pulse = SKAction.sequence([
            SKAction.scale(to: 0.92, duration: 0.07),
            SKAction.scale(to: 1.00, duration: 0.07)
        ])
        target.run(pulse)
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
        node.run(SKAction.scale(to: 1.18, duration: 0.07))
        (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = .yellow
    }

    func unmarkLetter(at index: Int) {
        guard index >= 0 && index < letterNodes.count else { return }
        let node = letterNodes[index]
        node.run(SKAction.scale(to: 1.0, duration: 0.07))
        (node.childNode(withName: "letterLabel") as? SKLabelNode)?.fontColor = .white
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
        activeSliceBG.zPosition   = 2
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth   = 9
        activeSliceBG.alpha       = 0
        addChild(activeSliceBG)

        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition   = 2
        activeSliceFG.strokeColor = .white
        activeSliceFG.lineWidth   = 5
        activeSliceFG.alpha       = 0
        addChild(activeSliceFG)
    }

    func redrawActiveSlice() {
        guard activeSlicePoints.count >= 2 else {
            activeSliceBG.path = nil; activeSliceFG.path = nil; return
        }
        while activeSlicePoints.count > 12 { activeSlicePoints.remove(at: 0) }
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        activeSlicePoints.dropFirst().forEach { path.addLine(to: $0) }
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
    }
}
