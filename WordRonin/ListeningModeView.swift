// ListeningModeView.swift
import SwiftUI
import AVFoundation
import UIKit

struct ListeningModeView: View {
    private let wordBank: [String] = [
        "TRUTH", "DAIRY", "ORDER", "TRIP", "PLANE",
        "ORANGE", "PLANET", "STREAM", "CAMERA", "POCKET"
    ]

    @State private var currentWord: String = ""
    @State private var scrambledLetters: [Character] = []
    @State private var userGuess: String = ""
    @State private var feedbackText: String = ""
    @State private var lastWord: String = ""
    @State private var speech = SpeechCoach()
    @State private var hasSpokenIntroThisSession: Bool = false

    var body: some View {
        ZStack {
            Image("sliceBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Listening Mode")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Press Play letters to hear scrambled letters. Then type the word and press Check.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 40)

                VStack(spacing: 18) {
                    HStack(spacing: 30) {
                        AssetButton(
                            imageName: "playlettersbutton",
                            width: 220,
                            axLabel: "Play letters",
                            axHint: "Speaks the scrambled letters"
                        ) {
                            playScrambledLetters()
                        }

                        AssetButton(
                            imageName: "stopbutton",
                            width: 180,
                            axLabel: "Stop",
                            axHint: "Stops speaking"
                        ) {
                            speech.stop()
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type the word you think it is")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)

                        TextField("Write your guess…", text: $userGuess)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 500)
                            .accessibilityLabel("Your guess")
                            .accessibilityHint("Type the full word")
                    }
                    .padding(.horizontal, 40)

                    HStack(spacing: 30) {
                        AssetButton(
                            imageName: "checkbutton",
                            width: 200,
                            axLabel: "Check answer",
                            axHint: "Checks if your guess is correct"
                        ) {
                            checkAnswer()
                        }

                        AssetButton(
                            imageName: "newwordbutton",
                            width: 240,
                            axLabel: "New word",
                            axHint: "Skips to a new word"
                        ) {
                            newWord()
                        }
                    }

                    if !feedbackText.isEmpty {
                        Text(feedbackText)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 10)
                            .accessibilityLabel(feedbackText)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            hasSpokenIntroThisSession = false
            if currentWord.isEmpty { newWord() }
        }
        .onDisappear {
            speech.stop()
        }
    }

    private func announce(_ text: String) {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }

    private func playScrambledLetters() {
        speech.stop()
        guard !scrambledLetters.isEmpty else { return }

        if !hasSpokenIntroThisSession {
            hasSpokenIntroThisSession = true
            speech.speak("Here are the letters.")
            speech.speak("They are scrambled.")
            speech.speak("Try to make a word.")
        }

        for letter in scrambledLetters {
            speech.speak(String(letter).lowercased())
        }
    }

    private func newWord() {
        feedbackText = ""
        userGuess = ""
        speech.stop()

        var next = wordBank.randomElement() ?? "TRUTH"
        if wordBank.count > 1 {
            while next == lastWord {
                next = wordBank.randomElement() ?? next
            }
        }

        lastWord = next
        currentWord = next
        scrambledLetters = Array(next)

        if scrambledLetters.count > 1 {
            var attempt = scrambledLetters
            var tries = 0
            repeat {
                attempt.shuffle()
                tries += 1
            } while String(attempt) == next && tries < 10
            scrambledLetters = attempt
        }

        announce("New word")
    }

    private func checkAnswer() {
        let cleanedGuess = userGuess
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        let cleanedAnswer = currentWord
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        guard !cleanedGuess.isEmpty else {
            feedbackText = "Type a guess first."
            speech.speak("Type a guess first.")
            announce("Type a guess first.")
            return
        }

        if cleanedGuess == cleanedAnswer {
            feedbackText = "Correct."
            speech.speak("Correct.")
            announce("Correct.")
        } else {
            feedbackText = "Not quite. Try again."
            speech.speak("Not quite. Try again.")
            announce("Not quite. Try again.")
        }
    }
}

private struct AssetButton: View {
    let imageName: String
    let width: CGFloat
    let axLabel: String
    let axHint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(axLabel)
        .accessibilityHint(axHint)
        .accessibilityAddTraits(.isButton)
    }
}

final class SpeechCoach {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: trimmed)
        let preferred = Locale.preferredLanguages.first ?? "en-US"
        utterance.voice = AVSpeechSynthesisVoice(language: preferred)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
