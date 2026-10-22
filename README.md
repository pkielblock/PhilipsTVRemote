# Philips TV Remote

**English** · [Português](README.pt-BR.md)

A native SwiftUI iPhone remote for older Philips NetTV sets (chassis TPM16.5L, e.g.
**32PHG5201/78**). It talks to the TV over your local network through the JointSpace v1 API.
No ads, no account, no cloud, no tracking.

The UI uses Liquid Glass on iOS 26 and later, with a regular material look on iOS 17–18.
It's available in English (default) and Portuguese; you can switch in Settings.

## Features

- Turn on / screen off, using the TV's eco "screen off" mode (see [Power](#power))
- D-pad + OK, Back, Home, Info, Options, Multiview
- Volume rocker + mute, channel rocker
- Colour keys, playback transport, number pad, subtitles
- Adjust, Search, Format, Guide, List, Smart TV, TV/Exit
- Source picker that lists the TV's inputs (HDMI, TV, …)
- Live connection and volume status
- Haptic feedback on every key
- English / Portuguese UI

## Requirements

- An iPhone on iOS 17 or later
- A Mac with Xcode (to build and install the app)
- Phone and TV on the same Wi-Fi/LAN
- A Philips TV that serves JointSpace v1 on port 1925 (most Philips NetTV sets from about 2011–2016)

## Build and install

1. Clone the repo and run `open PhilipsTVRemote.xcodeproj`.
2. Select the **PhilipsTVRemote** target, open *Signing & Capabilities* and pick your own
   team (a free personal Apple ID team works). If Xcode complains about the bundle ID,
   change it to something unique, e.g. `com.yourname.PhilipsTVRemote`.
3. Plug in your iPhone, select it as the run destination and press Run.
4. On first launch iOS asks for **Local Network** access. Allow it, otherwise the app
   can't reach the TV. (You can change this later in iOS Settings > Privacy & Security >
   Local Network.)

With a free Apple ID the app expires after 7 days; run it from Xcode again to renew it.

## Find your TV's IP address

Pick whichever is easiest:

- **On the TV:** press Home, go to **Setup > Network settings > View network settings**
  (menu names vary a little by model and firmware). The IP address is listed there.
- **On your router:** open its admin page and look at the DHCP client list / connected
  devices for an entry like "Philips" or the TV's model name.
- **From a computer on the same network:** check that the API answers:

  ```sh
  curl http://<tv-ip>:1925/1/system
  ```

  A JSON response means you have the right IP and the API is on.

The IP is assigned by your router (DHCP) and can change. Reserve a fixed IP for the TV in
your router's DHCP settings so you don't have to update the app.

## Configure the app

1. Open the app. On first launch the Settings screen opens by itself (or tap the gear icon).
2. Type the TV's IP address, e.g. `192.168.1.50`.
3. Tap **Test connection**. "Connected" means it's working.
4. Optionally switch the language under **Language**.
5. Tap **OK**.

The IP and language are stored on the phone only.

## Power

On this TV generation, real standby turns the Wi-Fi off, so nothing on the network can turn
the TV back on, and Wake-on-LAN doesn't work in practice. The app uses the TV's eco
**screen off** mode instead:

- **Screen off** opens the Adjust menu and selects *Eco settings > Screen off* by sending
  `Adjust, Right, OK, Down, OK`. The panel goes dark but the TV stays on the network.
- **Turn on** sends a Cursor Up key. Any key wakes the panel from screen off.

If your TV's Adjust menu is laid out differently, change the key sequence in
`TVClient.screenOff()`.

## Troubleshooting

- **"No response":** check the IP, that the phone is on the same Wi-Fi as the TV, and that
  Local Network access is allowed for the app.
- **Works, then stops:** the TV probably got a new IP from the router. Update it in
  Settings, or reserve a fixed IP.
- **A key does nothing:** `Guide`, `List` and `Multiview` have no documented v1 key name and
  may be ignored by some sets.

## Protocol notes

The app uses JointSpace v1 over plain HTTP on port 1925, with no authentication on this
generation.

| Call | Purpose |
| --- | --- |
| `POST /1/input/key` with `{"key":"VolumeUp"}` | Send a remote key (full list in `RemoteKey.swift`) |
| `GET/POST /1/audio/volume` | Read or set volume and mute |
| `GET /1/sources` | List inputs |
| `POST /1/sources/current` with `{"id":"hdmi1"}` | Switch input |
| `GET /1/system` | Model and software info |

`/1/applications`, `/1/menuitems` and the v6 API return **Forbidden** on the TPM16.5L.

## Project layout

| File | What it does |
| --- | --- |
| `PhilipsTVRemoteApp.swift` | App entry point |
| `ContentView.swift` | Remote layout, settings screen, glass styling |
| `SourceView.swift` | Input picker |
| `TVClient.swift` | JointSpace v1 HTTP client, power logic |
| `RemoteKey.swift` | Key names the TV accepts |
| `Language.swift` | In-app English/Portuguese strings |

## Privacy

The app collects no data. It only talks to the TV IP you enter, on your local network.
Nothing is sent anywhere else.

## License

[MIT](LICENSE)

## Disclaimer

Not affiliated with or endorsed by Philips or TP Vision. "Philips" is a trademark of its
owner.
