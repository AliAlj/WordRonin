//
//  StartScreen.swift
//  slicenspell
//
//  Created by Mohannad Jaber on 1/28/26.
//
import AVFoundation
import SpriteKit
import SwiftUI

struct StartScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.ourBlue),
                    Color(.ourBlack)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image(.moon)
                .resizable()
                .frame(width: 262, height: 250)
                .offset(y: -350)

            VStack {
                HStack {
                    Image(.cloud1)
                    Spacer()
                    Image(.cloud2)
                }
                .offset(y: -150)

                Spacer()

                Image(.samurai)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .offset(y: 42)

                //  House with bamboo + START text overlay
                ZStack {
                    Image(.house)

                    Image(.bamboo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 500)
                        .rotationEffect(.degrees(15))
                        .offset(y: 20)

                    // START text on bamboo
                    Text("START")
                        .font(.system(size: 50, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(-10))
                        .offset(y: 10)
                }
            }
        }
    }
}

#Preview {
    StartScreen()
}


