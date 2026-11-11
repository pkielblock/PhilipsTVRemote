# Philips TV Remote

**English** · [Português](README.pt-BR.md)

A native SwiftUI iPhone remote for older Philips NetTV sets (chassis TPM16.5L, e.g.
**32PHG5201/78**). It talks to the TV over your local network through the JointSpace v1 API.
No ads, no account, no cloud, no tracking.

The UI uses Kiel UI, the design system shared by my apps: always dark, solid surfaces with a thin
outline (no blur or glass), an 8-point grid, and capsule keys with a springy press. Blue only marks
an active state (muted, the selected option); green means connected. Every press taps a light haptic.
It's available in English (default) and Portuguese; you can switch in Settings.

## Features

- Turn on / screen off, using the TV's eco "screen off" mode (see [Power](#power))
- D-pad + OK, Back, Home, Info, Options, Multiview
- Volume rocker + mute, channel rocker
- Colour keys, playback transport, number pad, subtitles
- Adjust, Search, Format, Guide, List, Smart TV, TV/Exit
- Finds the TV on your Wi-Fi by itself, no IP to type
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

For a development-signed IPA, the embedded provisioning profile must include your
iPhone and must not have expired. To install without signing it again, unzip the IPA
and drag `Payload/PhilipsTVRemote.app` into Xcode's Devices and Simulators window for
your connected iPhone. Keep the installed bundle identifier and signing team when
updating to preserve app data. Free accounts support up to three installed apps.

Sideloadly error `7252` (certificate not found on the team) concerns its Apple signing
request; changing the IPA's bundle identifier does not fix that request. An already
signed build can instead be installed directly through Xcode.

## Find your TV's IP address

Only needed when the app can't find the TV by itself. Pick whichever is easiest:

- **On the TV:** press Home, go to **Setup > Network settings > View network settings**
  (menu names vary a little by model and firmware). The IP address is listed there.
- **On your router:** open its admin page and look at the DHCP client list / connected
  devices for an entry like "Philips" or the TV's model name.
- **From a computer on the same network:** check that the API answers:

  ```sh
  curl http://<tv-ip>:1925/1/system
  ```

  A JSON response means you have the right IP and the API is on.

The IP is assigned by your router (DHCP) and can change. The app finds the TV again on its own;
an IP typed by hand has to be updated, so reserve a fixed IP for the TV in your router.

## Configure the app

1. Turn the TV on and open the app. It searches your Wi-Fi for the TV (every address in the
   phone's subnet, on port 1925) and connects when it finds one.
2. If it finds several TVs, or none, the Settings screen opens: pick your TV under
   **TVs on your Wi-Fi**, tap **Search again**, or type the IP under **Enter the IP yourself**.
3. Optionally switch the language under **Language**, then tap **Done**.

If the saved TV stops answering (for example after it got a new IP), the app searches again on
the next launch and switches to the TV when it finds exactly one.

The IP and language are stored on the phone only.

The first time the app reaches the TV, iOS asks for local network access; allow it. That prompt
follows the phone's language (English or Portuguese), not the in-app switch: iOS shows system
prompts in the device language.

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

- **"No response" or no TV found:** check that the TV is on, that the phone is on the same
  Wi-Fi as the TV, and that Local Network access is allowed for the app, then tap
  **Search again** in Settings. Right after you allow Local Network access the first search can
  come back empty; search again.
- **Works, then stops:** the TV probably got a new IP from the router. Reopen the app or tap
  **Search again**.
- **A key does nothing:** `Guide`, `List` and `Multiview` have no documented v1 key name and
  may be ignored by some sets.

## Protocol notes

The app uses JointSpace v1 over plain HTTP on port 1925, with no authentication on this
generation.

| Call | Purpose |
| --- | --- |
| `POST /1/input/key` with `{"key":"VolumeUp"}` | Send a remote key (full list in `TVKey.swift`) |
| `GET/POST /1/audio/volume` | Read or set volume and mute |
| `GET /1/sources` | List inputs |
| `POST /1/sources/current` with `{"id":"hdmi1"}` | Switch input |
| `GET /1/system` | Model and software info |

`/1/applications`, `/1/menuitems` and the v6 API return **Forbidden** on the TPM16.5L.

## Project layout

| File | What it does |
| --- | --- |
| `PhilipsTVRemoteApp.swift` | App entry point |
| `ContentView.swift` | Remote layout, settings screen |
| `KielUI.swift` | Kiel UI tokens and components (copied from the Kiel UI design system) |
| `SourceView.swift` | Input picker |
| `TVClient.swift` | JointSpace v1 HTTP client, TV search on the Wi-Fi, power logic |
| `TVKey.swift` | Key names the TV accepts |
| `Language.swift` | In-app English/Portuguese strings |
| `InfoPlist.xcstrings` | Local network prompt in English and Portuguese |

## Privacy

The app collects no data. It only talks to devices on your local network: the search asks each address in your
Wi-Fi's subnet for the TV's API, then the app talks to the TV it found or the IP you enter.
Nothing is sent anywhere else.

## License

[MIT](LICENSE)

## Disclaimer

Not affiliated with or endorsed by Philips or TP Vision. "Philips" is a trademark of its
owner.
