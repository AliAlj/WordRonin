// ListeningModeOverlay.swift
import SwiftUI

struct ListeningStartOverlay: View {
    let onStart: () -> Void
    let onHowToPlay: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Listening Mode")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Guess the full word from the letters you hear.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                VStack(spacing: 10) {
                    Button { onStart() } label: {
                        Image("startgamebutton")
                            .resizable().scaledToFit().frame(width: 260)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start listening mode")
                    Button { onHowToPlay() } label: {
                        Image("howtoplaybutton")
                            .resizable().scaledToFit().frame(width: 220)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("How to play")
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.50))
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1))
            )
            // Pushed down slightly so back button at top has breathing room
            .padding(.top, 60)
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct ListeningHowToPlayOverlay: View {
    let onClose: () -> Void
    var body: some View {
        GeometryReader { geo in
            let cardW = min(geo.size.width * 0.86, 900)
            let cardH = min(geo.size.height * 0.70, 700)
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.78).ignoresSafeArea()
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.black.opacity(0.92))
                        .frame(width: cardW, height: cardH)
                        .overlay(RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.18), lineWidth: 2))
                    VStack(spacing: 12) {
                        Text("How to Play")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 20)
                        Text("Listen to the letters, then guess the full word.")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        Text("Press Play Letters to hear the scrambled letters.\nType your guess, then press Check.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        HStack(spacing: 14) {
                            Image("playlettersbutton").resizable().scaledToFit().frame(width: 180).accessibilityHidden(true)
                            Image("checkbutton").resizable().scaledToFit().frame(width: 140).accessibilityHidden(true)
                        }
                        .padding(.top, 10)
                        Spacer(minLength: 0)
                    }
                    .frame(width: cardW * 0.92, height: cardH * 0.92)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Button { onClose() } label: {
                    Image("backbutton").resizable().scaledToFit().frame(width: 130)
                }
                .buttonStyle(.plain)
                .padding(.leading, max(20, geo.safeAreaInsets.leading + 20))
                .padding(.top, max(20, geo.safeAreaInsets.top + 20))
                .accessibilityLabel("Back")
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
