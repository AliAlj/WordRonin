// GameScene+Accessibility.swift
import UIKit
import SpriteKit

extension GameScene {

    func refreshAccessibility(in skView: SKView) {
        guard UIAccessibility.isVoiceOverRunning else {
            skView.accessibilityElements = nil
            return
        }

        skView.isAccessibilityElement = false

        var elements: [UIAccessibilityElement] = []

        func addButton(for nodeName: String, label: String, hint: String) {
            guard let node = childNode(withName: "//\(nodeName)") else { return }
            let rect = accessibilityFrame(for: node, in: skView)
            guard !rect.isNull, rect.width > 1, rect.height > 1 else { return }

            let el = UIAccessibilityElement(accessibilityContainer: skView)
            el.accessibilityTraits = [.button]
            el.accessibilityLabel = label
            el.accessibilityHint = hint
            el.accessibilityFrameInContainerSpace = rect
            elements.append(el)
        }

        func addStaticText(frameNode: SKNode?, text: String, labelPrefix: String? = nil) {
            guard let frameNode else { return }
            let rect = accessibilityFrame(for: frameNode, in: skView)
            guard !rect.isNull, rect.width > 1, rect.height > 1 else { return }

            let el = UIAccessibilityElement(accessibilityContainer: skView)
            el.accessibilityTraits = [.staticText]
            if let labelPrefix, !labelPrefix.isEmpty {
                el.accessibilityLabel = "\(labelPrefix) \(text)"
            } else {
                el.accessibilityLabel = text
            }
            el.accessibilityFrameInContainerSpace = rect
            elements.append(el)
        }

        func addToggleButton(nodeName: String, label: String, isOn: Bool) {
            guard let node = childNode(withName: "//\(nodeName)") else { return }
            let rect = accessibilityFrame(for: node, in: skView)
            guard !rect.isNull, rect.width > 1, rect.height > 1 else { return }

            let el = UIAccessibilityElement(accessibilityContainer: skView)
            el.accessibilityTraits = [.button]
            el.accessibilityLabel = label
            el.accessibilityValue = isOn ? "On" : "Off"
            el.accessibilityHint = "Double tap to toggle"
            el.accessibilityFrameInContainerSpace = rect
            elements.append(el)
        }

        // Back buttons (menu, tutorial, in game)
        addButton(
            for: GameConfig.ButtonNames.menuBack,
            label: "Back",
            hint: "Returns to mode selection"
        )
        addButton(
            for: GameConfig.ButtonNames.tutorialBack,
            label: "Back",
            hint: "Closes how to play"
        )
        addButton(
            for: GameConfig.ButtonNames.inGameBack,
            label: "Back",
            hint: "Restarts the game"
        )

        // Main menu buttons (only present when start overlay exists)
        addButton(
            for: GameConfig.ButtonNames.start,
            label: "Start game",
            hint: "Starts slice mode"
        )
        addButton(
            for: GameConfig.ButtonNames.howToPlay,
            label: "How to play",
            hint: "Shows instructions"
        )

        // Settings overlay buttons
        addButton(
            for: GameConfig.ButtonNames.closeSettings,
            label: "Close settings",
            hint: "Closes settings"
        )
        addToggleButton(
            nodeName: GameConfig.ButtonNames.toggleSound,
            label: "Sound effects",
            isOn: isSoundEnabled
        )
        addToggleButton(
            nodeName: GameConfig.ButtonNames.toggleMusic,
            label: "Music",
            isOn: isMusicEnabled
        )
        addButton(
            for: GameConfig.ButtonNames.dojoAction,
            label: "Dojo",
            hint: "Runs dojo action"
        )

        // Game over
        addButton(
            for: GameConfig.ButtonNames.playAgain,
            label: "Play again",
            hint: "Starts a new round"
        )

        // HUD + current word
        addStaticText(frameNode: scoreHud, text: gameScore.text ?? "Score", labelPrefix: nil)
        addStaticText(frameNode: timerHud, text: timerLabel?.text ?? "Time", labelPrefix: nil)

        if let cw = currentWordLabel?.text, !cw.isEmpty {
            addStaticText(frameNode: currentWordLabel, text: cw, labelPrefix: "Current word")
        }

        skView.accessibilityElements = elements
    }

    private func accessibilityFrame(for node: SKNode, in skView: SKView) -> CGRect {
        let frameInScene = node.calculateAccumulatedFrame()
        if frameInScene.isNull { return .null }

        let p1 = CGPoint(x: frameInScene.minX, y: frameInScene.minY)
        let p2 = CGPoint(x: frameInScene.maxX, y: frameInScene.maxY)

        let v1 = skView.convert(p1, from: self)
        let v2 = skView.convert(p2, from: self)

        let minX = min(v1.x, v2.x)
        let minY = min(v1.y, v2.y)
        let maxX = max(v1.x, v2.x)
        let maxY = max(v1.y, v2.y)

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
