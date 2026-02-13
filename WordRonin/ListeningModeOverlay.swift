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
        GeometryReader { geo in
            let cardW = min(geo.size.width * 0.86, 980)
            let cardH = min(geo.size.height * 0.74, 760)

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.78)
                    .ignoresSafeArea()

                // Center card (SpriteKit style)
                ZStack {
                    // Shadow layer
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color.black.opacity(0.55))
                        .frame(width: cardW, height: cardH)
                        .offset(y: 10)

                    // Main panel
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color.black.opacity(0.92))
                        .frame(width: cardW, height: cardH)
                        .overlay(
                            RoundedRectangle(cornerRadius: 34)
                                .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        )

                    // Inner border
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.08), lineWidth: 2)
                        .frame(width: cardW - 20, height: cardH - 20)

                    VStack(spacing: 14) {
                        Text("How to Play")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 24)

                        Text("Listen to the letters, then guess the full word.")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 22)

                        Text("Press Play Letters to hear the scrambled letters. Type your guess, then press Check.")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.top, 10)

                        HStack(spacing: 18) {
                            Image("playlettersbutton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220)
                                .accessibilityHidden(true)

                            Image("checkbutton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 170)
                                .accessibilityHidden(true)
                        }
                        .padding(.top, 18)

                        Spacer(minLength: 0)
                    }
                    .frame(width: cardW * 0.92, height: cardH * 0.92)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("How to play. Press Play Letters to hear the scrambled letters. Type your guess and press Check. Use New Word to skip.")

                // Top-left back button (same feel as SpriteKit)
                Button {
                    onClose()
                } label: {
                    Image("backbutton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160)
                }
                .buttonStyle(.plain)
                .padding(.leading, max(24, geo.safeAreaInsets.leading + 24))
                .padding(.top, max(24, geo.safeAreaInsets.top + 24))
                .accessibilityLabel("Back")
                .accessibilityHint("Closes how to play")
                .accessibilityAddTraits(.isButton)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

#if canImport(SwiftUI)
#Preview("Listening Mode – Landscape", traits: .landscapeLeft) {
    RootModeView()
}
#endif
