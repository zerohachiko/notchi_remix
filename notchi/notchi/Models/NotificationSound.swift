import Foundation

enum NotificationSound: String, CaseIterable {
    case none
    case pop
    case ping
    case tink
    case glass
    case blow
    case bottle
    case frog
    case funk
    case hero
    case morse
    case purr
    case sosumi
    case submarine
    case basso
    case marioCoin
    case marioComplete
    case marioOneUp
    case marioPowerUp

    var isSystemSound: Bool {
        switch self {
        case .marioCoin, .marioComplete, .marioOneUp, .marioPowerUp:
            return false
        default:
            return true
        }
    }

    var soundName: String? {
        switch self {
        case .none: return nil
        case .pop: return "Pop"
        case .ping: return "Ping"
        case .tink: return "Tink"
        case .glass: return "Glass"
        case .blow: return "Blow"
        case .bottle: return "Bottle"
        case .frog: return "Frog"
        case .funk: return "Funk"
        case .hero: return "Hero"
        case .morse: return "Morse"
        case .purr: return "Purr"
        case .sosumi: return "Sosumi"
        case .submarine: return "Submarine"
        case .basso: return "Basso"
        case .marioCoin: return "mario_coin"
        case .marioComplete: return "mario_complete"
        case .marioOneUp: return "mario_oneup"
        case .marioPowerUp: return "mario_powerup"
        }
    }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .pop: return "Pop"
        case .ping: return "Ping"
        case .tink: return "Tink"
        case .glass: return "Glass"
        case .blow: return "Blow"
        case .bottle: return "Bottle"
        case .frog: return "Frog"
        case .funk: return "Funk"
        case .hero: return "Hero"
        case .morse: return "Morse"
        case .purr: return "Purr"
        case .sosumi: return "Sosumi"
        case .submarine: return "Submarine"
        case .basso: return "Basso"
        case .marioCoin: return "🍄 Mario Coin"
        case .marioComplete: return "🍄 Mario Complete"
        case .marioOneUp: return "🍄 Mario 1-UP"
        case .marioPowerUp: return "🍄 Mario Power Up"
        }
    }
}
