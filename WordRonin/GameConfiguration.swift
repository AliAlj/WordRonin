// GameConfiguration.swift
import Foundation
import SpriteKit
import UIKit

// MARK: - Notifications
extension Notification.Name {
    static let exitSliceMode = Notification.Name("exitSliceMode")
}

// MARK: - Enums
enum ForceBomb {
    case never, always, random
}

enum SequenceType: CaseIterable {
    case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
}

// MARK: - Adaptive Helpers
struct Adaptive {
    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    /// Returns `pad` value on iPad, `phone` on iPhone.
    static func value<T>(pad: T, phone: T) -> T {
        isPad ? pad : phone
    }
}

// MARK: - GameConfig
struct GameConfig {
    static let roundDurationSeconds = 60

    struct Assets {
        static let bambooImage      = "bamboo_slice"
        static let buttonBamboo     = "fullbamboo"
        static let inGameBackground = "sliceBackground"
        static let menuBackground   = "gameBackground"
        static let backButton       = "backbutton"
        static let startGameButton  = "startgamebutton"
        static let howToPlayButton  = "howtoplaybutton"
        static let settingsButton   = "Settings Gear"
        static let closeButton      = "Exit Button"
        static let soundIcon        = "Sound Setting"
        static let musicIcon        = "Music Setting"
        static let dojoIcon         = "Dojo Setting"
        static let settingsHeader   = "Settings Header"
        static let playAgainButton  = "playagainbutton"
    }

    struct Audio {
        static let musicSlice = "slicesong.mp3"
        static let menuSong   = "menusong.caf"
        static let hit        = "hit_tick.caf"
        static let correct    = "correct.caf"
        static let wrong      = "wrong.caf"
        static let clock      = "clock.caf"
    }

    struct ButtonNames {
        // Navigation
        static let menuBack      = "btn_menu_back"
        static let tutorialBack  = "btn_tutorial_back"
        static let inGameBack    = "btn_ingame_back"
        // Main Menu
        static let start         = "btn_start_game"
        static let howToPlay     = "btn_how_to_play"
        static let settings      = "btn_settings"
        // Settings
        static let closeSettings = "btn_close_settings"
        static let toggleSound   = "btn_toggle_sound"
        static let toggleMusic   = "btn_toggle_music"
        static let dojoAction    = "btn_dojo_action"
        // Game Over
        static let playAgain     = "btn_play_again"
    }

    struct PopupNames {
        static let startPopup       = "start_popup"
        static let startPopupPanel  = "start_popup_panel"
        static let settingsPopup    = "settings_popup"
    }

    // MARK: HUD sizes — adaptive

    struct HUD {
        static var bambooSize: CGSize {
            Adaptive.value(
                pad:   CGSize(width: 200, height: 72),   // ← iPad pill size
                phone: CGSize(width: 160, height: 56)    // ← iPhone pill size
            )
        }
        static var fontSize: CGFloat {
            Adaptive.value(pad: 32, phone: 26)
        }
        static let zPosition: CGFloat     = 120
        static let textZPosition: CGFloat = 122
    }

    // MARK: Letter tile sizes — adaptive (square bamboo logs)
    struct Tiles {
        static var preferred: CGSize {
            Adaptive.value(
                pad:   CGSize(width: 150, height: 150),
                phone: CGSize(width: 90,  height: 90)
            )
        }
        static var bamboo: CGSize {
            Adaptive.value(
                pad:   CGSize(width: 150, height: 150),
                phone: CGSize(width: 90,  height: 90)
            )
        }
        static var minGap: CGFloat {
            Adaptive.value(pad: 24, phone: 16)
        }
        static var labelFont: CGFloat {
            Adaptive.value(pad: 66, phone: 40)
        }
    }

    // MARK: Layout insets — adaptive
    struct Layout {
        static var topInset: CGFloat {
            let safeTop = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.safeAreaInsets.top ?? 0
            return Adaptive.value(
                pad:   max(250, safeTop + 250),
                phone: max(140, safeTop + 140)
            )
        }
        static var bottomInset: CGFloat {
            Adaptive.value(pad: 140, phone: 120)
        }
        static var horizontalInset: CGFloat {
            Adaptive.value(pad: 24, phone: 16)
        }
    }

    // MARK: Word Build Bar
    struct WordBar {
        static var segmentSide: CGFloat {
            Adaptive.value(pad: 110, phone: 64)
        }
        static var overlapFraction: CGFloat {
            Adaptive.value(pad: 0.34, phone: 0.24)
        }
        static var yOffsetFromTop: CGFloat {
            Adaptive.value(pad: 110, phone: 120)
        }
    }
}
