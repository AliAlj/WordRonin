//  GameConfiguration.swift
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
        // Existing Game Assets
        static let bambooImage = "bamboo_slice"
        static let buttonBamboo = "fullbamboo"
        static let inGameBackground = "sliceBackground"
        static let menuBackground = "gameBackground"
        static let backButton = "backbutton"
        static let startGameButton = "startgamebutton"
        static let howToPlayButton = "howtoplaybutton"
        
        // NEW: Settings Assets (Updated with your names)
        static let settingsButton = "Settings Gear"
        static let closeButton = "Exit Button"
        static let soundIcon = "Sound Setting"
        static let musicIcon = "Music Setting"
        static let dojoIcon = "Dojo Setting"
        static let settingsHeader = "Settings Header" // Added this for the header image
    }
    
    struct Audio {
        static let musicSlice = "slicesong.mp3"
        static let hit = "hit_tick.caf"
        static let correct = "correct.caf"
        static let wrong = "wrong.caf"
        static let clock = "clock.caf"
    }
    
    struct ButtonNames {
        // Navigation
        static let menuBack = "btn_menu_back"
        static let tutorialBack = "btn_tutorial_back"
        static let inGameBack = "btn_ingame_back"
        
        // Main Menu
        static let start = "btn_start_game"
        static let howToPlay = "btn_how_to_play"
        static let settings = "btn_settings"
        
        // Settings Menu
        static let closeSettings = "btn_close_settings"
        static let toggleSound = "btn_toggle_sound"
        static let toggleMusic = "btn_toggle_music"
        static let dojoAction = "btn_dojo_action"
        
        // Game Over
        static let playAgain = "btn_play_again"
    }
    
    struct PopupNames {
        static let startPopup = "start_popup"
        static let startPopupPanel = "start_popup_panel"
        static let settingsPopup = "settings_popup"
    }
    
    struct HUD {
        static let bambooSize = CGSize(width: 300, height: 300)
        static let zPosition: CGFloat = 120
        static let textZPosition: CGFloat = 122
    }
}
