// ListeningModeOverlay.swift
import SwiftUI

struct ListeningStartOverlay: View {
    let onStart: () -> Void
    let onHowToPlay: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Listening Mode")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Guess the full word from the letters you hear.")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 14) {
                    Button { onStart() } label: {
                        Image("startgamebutton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 360)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start listening mode")
                    .accessibilityHint("Begins the listening mode round")
                    .accessibilityAddTraits(.isButton)

                    Button { onHowToPlay() } label: {
                        Image("howtoplaybutton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("How to play")
                    .accessibilityHint("Shows instructions")
                    .accessibilityAddTraits(.isButton)
                }
                .padding(.top, 6)
            }
            .padding(24)
            .frame(maxWidth: 650)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.18), lineWidth: 2)
                    )
            )
            .accessibilityElement(children: .contain)
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct ListeningHowToPlayOverlay: View {
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("How to Play")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Press Play letters to hear the scrambled letters.")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                Text("Your goal is to guess the entire word.")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
            }
            .padding(22)
            .frame(maxWidth: 720)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.50))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.18), lineWidth: 2)
                    )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("How to play. Press Play letters to hear the scrambled letters. Your goal is to guess the entire word.")

            Button {
                onClose()
            } label: {
                Image("backbutton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
            }
            .buttonStyle(.plain)
            .padding(.leading, 24)
            .padding(.top, 24)
            .accessibilityLabel("Back")
            .accessibilityHint("Closes how to play")
            .accessibilityAddTraits(.isButton)
        }
        .accessibilityAddTraits(.isModal)
    }
}
