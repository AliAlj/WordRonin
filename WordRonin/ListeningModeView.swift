// ListeningModeView.swift
import SwiftUI
import AVFoundation
import UIKit

struct ListeningModeView: View {
    private let wordBank: [String] = [
        "TRUTH", "DAIRY", "ORDER", "TRIP", "PLANE",
        "ORANGE", "PLANET", "STREAM", "CAMERA", "POCKET",
        "ARCH", "BARN", "CAKE", "DASH", "FADE", "GIFT", "HIKE",
        "KITE", "LAMP", "MOTH", "NEST", "PINE", "ROPE", "SAIL", "TIDE",
        "FLAME", "BRAVE", "CHESS", "DRIVE", "FROST", "GIANT",
        "IVORY", "KNIFE", "LEMON", "MARCH", "NOVEL", "RIVER",
        "TIGER", "VAPOR", "WITCH",
        "BRIDGE", "CASTLE", "DANCER", "FLOWER", "GARDEN", "HUNTER",
        "MARKET", "NATURE", "OYSTER", "PIRATE", "ROCKET", "SILVER",
        "TEMPLE", "FOREST", "ANCHOR", "BANTER", "CARPET", "DONKEY"
    ]
    @State private var currentWord: String = ""
    @State private var scrambledLetters: [Character] = []
    @State private var userGuess: String = ""
    @State private var feedbackText: String = ""
    @State private var lastWord: String = ""
    @State private var speech = SpeechCoach()
    @State private var hasSpokenIntroThisSession: Bool = false

    var body: some View {
        // Full screen tap area — content is a compact centred card
        GeometryReader { geo in
            ZStack {
                // Compact card — max 520pt wide, fits iPhone and iPad
                VStack(spacing: 14) {

                    // Title
                    VStack(spacing: 3) {
                        Text("Listening Mode")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Press Play Letters, then type and press Check.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }

                    Divider().background(Color.white.opacity(0.2))

                    // Play / Stop
                    HStack(spacing: 12) {
                        AssetButton(imageName: "playlettersbutton", width: buttonW(geo),
                                    axLabel: "Play letters", axHint: "Speaks the scrambled letters") {
                            playScrambledLetters()
                        }
                        AssetButton(imageName: "stopbutton", width: buttonW(geo) * 0.78,
                                    axLabel: "Stop", axHint: "Stops speaking") {
                            speech.stop()
                        }
                    }

                    // Input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your guess")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                        TextField("Write your guess…", text: $userGuess)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 16, design: .rounded))
                    }

                    // Check / New Word
                    HStack(spacing: 12) {
                        AssetButton(imageName: "checkbutton", width: buttonW(geo) * 0.85,
                                    axLabel: "Check answer", axHint: "Checks your guess") {
                            checkAnswer()
                        }
                        AssetButton(imageName: "newwordbutton", width: buttonW(geo),
                                    axLabel: "New word", axHint: "Skips to a new word") {
                            newWord()
                        }
                    }

                    // Feedback
                    if !feedbackText.isEmpty {
                        Text(feedbackText)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(18)
                .frame(maxWidth: min(geo.size.width - 32, 520))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.78))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                // Position: vertically centred, horizontally centred
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .onAppear {
            hasSpokenIntroThisSession = false
            if currentWord.isEmpty { newWord() }
        }
        .onDisappear { speech.stop() }
    }

    private func buttonW(_ geo: GeometryProxy) -> CGFloat {
        min((min(geo.size.width, 520) - 60) / 2, 200)
    }

    private func announce(_ text: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: text)
    }

    private func playScrambledLetters() {
        speech.stop()
        guard !scrambledLetters.isEmpty else { return }
        if !hasSpokenIntroThisSession {
            hasSpokenIntroThisSession = true
            speech.speak("Here are the letters. They are scrambled. Try to make a word.")
        }
        for letter in scrambledLetters { speech.speak(String(letter).lowercased()) }
    }

    private func newWord() {
        feedbackText = ""
        userGuess = ""
        speech.stop()
        var next = wordBank.randomElement() ?? "TRUTH"
        if wordBank.count > 1 { while next == lastWord { next = wordBank.randomElement() ?? next } }
        lastWord = next
        currentWord = next
        scrambledLetters = Array(next)
        if scrambledLetters.count > 1 {
            var attempt = scrambledLetters; var tries = 0
            repeat { attempt.shuffle(); tries += 1 } while String(attempt) == next && tries < 10
            scrambledLetters = attempt
        }
        announce("New word")
    }

    private func checkAnswer() {
        let guess  = userGuess.trimmingCharacters(in: .whitespaces).lowercased()
        let answer = currentWord.lowercased()
        guard !guess.isEmpty else {
            feedbackText = "Type a guess first."
            speech.speak("Type a guess first.")
            return
        }
        if guess == answer {
            feedbackText = "✓ Correct!"
            speech.speak("Correct.")
            announce("Correct.")
        } else {
            feedbackText = "✗ Not quite. Try again."
            speech.speak("Not quite. Try again.")
            announce("Not quite. Try again.")
        }
    }
}

private struct AssetButton: View {
    let imageName: String; let width: CGFloat
    let axLabel: String;   let axHint: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(imageName).resizable().scaledToFit().frame(width: width).shadow(radius: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(axLabel).accessibilityHint(axHint).accessibilityAddTraits(.isButton)
    }
}

final class SpeechCoach {
    private let synthesizer = AVSpeechSynthesizer()
    func speak(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let u = AVSpeechUtterance(string: t)
        u.voice = AVSpeechSynthesisVoice(language: Locale.preferredLanguages.first ?? "en-US")
        u.rate  = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(u)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}
