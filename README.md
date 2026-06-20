# Engine Room Ventilation — Flutter Remote

A companion **phone/tablet remote** for the [EngineRoomVent](https://github.com/tikson-elektronic/EngineRoomVent)
panel (the WPF touchscreen app that drives the FEIT FV-series fans via a BasicMicro RoboClaw 2x200A).

The remote finds the panel on the boat LAN — **no IP to type, no cloud** — and mirrors the
touchscreen's controls. The panel is the single source of truth: every remote command moves the
panel's own sliders/toggles, and the remote polls the panel for live state.

It speaks the panel's documented **LAN HTTP/JSON API + UDP discovery** — see
[`docs/API.md`](https://github.com/tikson-elektronic/EngineRoomVent/blob/main/docs/API.md) in the
panel repo. Requires the panel running with `apiEnabled: true` (the default).

## What it does

- **Discovery** — broadcasts `ENGINE_ROOM_VENT_DISCOVER` on UDP 48653 and lists every panel that
  answers; or connect manually by host/IP. (`lib/services/discovery.dart`)
- **Dashboard** — the panel's look (cyan CH1 / amber CH2, spinning propeller gauges, system strip):
  per-channel speed slider, direction (FWD/REV), power, live RPM (estimated)/current/state, supply
  voltage and total draw, link pill, and the latched **E-STOP**.
- **Live polling** — `GET /api/status` ~1 Hz; every write returns fresh status so the UI reconciles
  immediately. Optimistic echo keeps the slider responsive while dragging.
- **Honest state** — shows `LOST`/`FAILSAFE` when the panel↔controller link drops, and `OFFLINE`
  when the remote itself can't reach the panel.

## Architecture

| Path | Role |
|------|------|
| `lib/services/discovery.dart` | UDP broadcast discovery (`dart:io`). |
| `lib/services/vent_client.dart` | HTTP/JSON client for `/api/*` (the `http` package). |
| `lib/services/vent_controller.dart` | `ChangeNotifier`: 1 Hz poll, command dispatch, optimistic setpoints, reachability. |
| `lib/models.dart` | `PanelInfo`, `VentStatus`, `ChannelStatus` — parse the documented JSON. |
| `lib/theme.dart` | Color tokens mirrored from the panel's Section 6 style spec. |
| `lib/widgets/propeller_gauge.dart` | Custom-painted % arc + direction-aware spinning propeller. |
| `lib/widgets/channel_card.dart`, `system_strip.dart`, `header_bar.dart` | Dashboard pieces. |
| `lib/screens/discovery_screen.dart`, `dashboard_screen.dart` | The two screens. |

> RPM is **estimated** (`livePercent% × ratedRpm`) because no encoders are fitted — current and
> voltage are read live. The remote labels it the same way the panel does.

## Run

```bash
flutter pub get
flutter run            # pick a device (Android / iOS / macOS)
flutter test           # model parsing + widget smoke tests
flutter analyze        # clean
```

The device must be on the **same LAN** as the panel. Platform permissions are already wired:
Android cleartext + UDP broadcast, iOS `NSLocalNetworkUsageDescription` + local-networking ATS,
macOS network client/server entitlements.

> ⚠️ The panel's API is **unauthenticated** by design (trusted, isolated vessel LAN). Anyone who can
> reach it can drive the fans — keep it off untrusted networks.
