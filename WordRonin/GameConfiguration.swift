//
//  GameConfiguration.swift
//  slicenspell
//
//  Created by Jad Aoun on 2/11/26.
//

import Foundation
import SpriteKit

// MARK: - Enums
extension Notification.Name {
    static let exitSliceMode = Notification.Name("exitSliceMode")
}

enum ForceBomb {
    case never, always, random
}

enum SequenceType: CaseIterable {
    case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
}

// MARK: - Configuration Struct
struct GameConfig {
    static let roundDurationSeconds = 60
    
    struct Assets {
        static let bambooImage = "bamboo_slice"
        static let buttonBamboo = "fullbamboo"
        static let inGameBackground = "sliceBackground"
        static let menuBackground = "gameBackground"
        static let backButton = "backbutton"
        static let startGameButton = "startgamebutton"
        static let howToPlayButton = "howtoplaybutton"
    }
    
    struct Audio {
        static let musicSlice = "slicesong.mp3"
        static let hit = "hit_tick.caf"
        static let correct = "correct.caf"
        static let wrong = "wrong.caf"
        static let clock = "clock.caf"
    }
    
    struct ButtonNames {
        static let menuBack = "btn_menu_back"
        static let tutorialBack = "btn_tutorial_back"
        static let inGameBack = "btn_ingame_back"
        static let start = "btn_start_game"
        static let howToPlay = "btn_how_to_play"
        static let playAgain = "btn_play_again"
    }
    
    struct PopupNames {
        static let startPopup = "start_popup"
        static let startPopupPanel = "start_popup_panel"
    }
    
    struct HUD {
        static let bambooSize = CGSize(width: 300, height: 215)
        static let zPosition: CGFloat = 120
        static let textZPosition: CGFloat = 122
    }
}
