import Foundation

/// JointSpace v1 key names accepted by the TPM16.5L chassis.
/// `guide`, `list` and `multiview` have no documented v1 key; they are
/// best-effort strings and may be no-ops on this set.
enum RemoteKey: String {
    case standby        = "Standby"
    case back           = "Back"
    case home           = "Home"
    case options        = "Options"
    case adjust         = "Adjust"
    case info           = "Info"
    case source         = "Source"
    case watchTV        = "WatchTV"
    case online         = "Online"
    case find           = "Find"
    case viewmode       = "Viewmode"
    case guide          = "Guide"        // best-effort
    case list           = "List"         // best-effort
    case multiview      = "Multiview"    // best-effort

    case cursorUp       = "CursorUp"
    case cursorDown     = "CursorDown"
    case cursorLeft     = "CursorLeft"
    case cursorRight    = "CursorRight"
    case confirm        = "Confirm"

    case volumeUp       = "VolumeUp"
    case volumeDown     = "VolumeDown"
    case mute           = "Mute"

    case channelUp      = "ChannelStepUp"
    case channelDown    = "ChannelStepDown"

    case digit0 = "Digit0", digit1 = "Digit1", digit2 = "Digit2"
    case digit3 = "Digit3", digit4 = "Digit4", digit5 = "Digit5"
    case digit6 = "Digit6", digit7 = "Digit7", digit8 = "Digit8"
    case digit9 = "Digit9"
    case dot    = "Dot"

    case red            = "RedColour"
    case green          = "GreenColour"
    case yellow         = "YellowColour"
    case blue           = "BlueColour"

    case play           = "PlayPause"
    case pause          = "Pause"
    case stop           = "Stop"
    case record         = "Record"
    case rewind         = "Rewind"
    case fastForward    = "FastForward"

    case subtitle       = "Subtitle"
    case teletext       = "Teletext"
    case ambilight      = "AmbilightOnOff"

    static func digit(_ n: Int) -> RemoteKey? {
        RemoteKey(rawValue: "Digit\(n)")
    }
}
