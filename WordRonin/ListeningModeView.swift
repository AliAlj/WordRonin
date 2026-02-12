// ListeningModeView.swift
import SwiftUI
import AVFoundation

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

    /// Only speak the onboarding prompt the first time the user hits Play after entering the screen.
    @State private var hasSpokenIntroThisSession: Bool = false

    var body: some View {
        VStack(spacing: 16) {

            VStack(spacing: 8) {
                Text("Listening Mode")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Press Play letters to hear scrambled letters. Then type the word and press Check.")
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 12)

            VStack(spacing: 12) {

                HStack(spacing: 12) {
                    Button {
                        playScrambledLetters()
                    } label: {
                        Label("Play letters", systemImage: "play.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(minWidth: 160)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .foregroundStyle(.white)

                    Button {
                        speech.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type the word you think it is")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Write your guess…", text: $userGuess)
                        //.textInputAutocapitalization(.characters)
                        //.autocorrectionDisabled(true)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 12) {
                    Button {
                        checkAnswer()
                    } label: {
                        Label("Check", systemImage: "checkmark.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(minWidth: 140)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .foregroundStyle(.white)

                    Button {
                        newWord()
                    } label: {
                        Label("New word", systemImage: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(minWidth: 160)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .foregroundStyle(.black)
                }

                if !feedbackText.isEmpty {
                    Text(feedbackText)
                        .font(.system(size: 18, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.bottom, 20)
        .onAppear {
            // Reset this flag each time the user enters the screen.
            hasSpokenIntroThisSession = false

            if currentWord.isEmpty { newWord() }
        }
        .onDisappear {
            speech.stop()
        }
    }

    private func playScrambledLetters() {
        speech.stop()
        guard !scrambledLetters.isEmpty else { return }

        // Only speak the intro once per screen entry. If the user taps Play again (replay),
        // we just repeat the letters.
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
            return
        }

        if cleanedGuess == cleanedAnswer {
            feedbackText = "Correct."
            speech.speak("Correct.")
        } else {
            feedbackText = "Not quite. Try again."
            speech.speak("Not quite. Try again.")
        }
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
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.12

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

