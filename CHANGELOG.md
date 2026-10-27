# Changelog

All notable changes to AirSerial are listed here. Versions follow [Semantic Versioning](https://semver.org):
MAJOR for incompatible API changes, MINOR for new features, PATCH for fixes.

## [1.2.0] - 2026-10-27

### Added
- `SerialLink`: keeps one device connected for the life of the app, so the app only calls `send()`.
  - Picks the port by name, or `"auto"` (USB device by VID/PID, else the first USB serial port).
  - Keeps retrying until the port opens, and tries again as soon as a device is plugged in.
  - Reconnects after the device is lost; with `"auto"` follows it to another USB socket even without a serial number.
  - Holds the latest message while disconnected and sends it on connect; resends the last message after a reconnect.
  - Adds `prefix` / `suffix` bytes to every message and splits received data at `suffix` (`FrameEvent.FRAME`).
  - Logs to `trace`, a `log` event and an optional log file.
  - `configure()` reads settings from a plain object such as a parsed JSON file, with defaults for missing keys.

## [1.1.0] - 2026-10-27

### Fixed
- The app froze for about 3.5 s when opening a Prolific PL2303 adapter (and other USB adapters whose driver is slow to open the port) right after it was plugged in — also during automatic reconnection.

### Changed
- `open()` no longer holds the app for more than about 0.1 s. When the driver is slow, `open()` returns `true`, `connected` stays `false` until the port is ready, and `Event.CONNECT` follows — or `IOErrorEvent.IO_ERROR` with `lastError` if the port then fails to open. Ports that open normally behave exactly as before.

## [1.0.1] - 2026-10-26

### Fixed
- The app could crash while exiting when ports were still open or hot-plug events were still being watched and `close()` was not called. The extension now stays loaded until the process ends and stops any leftover background threads itself.

### Documentation
- README restructured: background, Flash Builder setup, reading and sending data, migrating from as3-arduino-connector, FAQ.
- New document-class example (`examples/document-class/SerialDemo.as`).

## [1.0.0] - 2026-10-26

First public release.

### Ports
- `SerialPort` with a `flash.net.Socket` style API (`IDataInput` / `IDataOutput`, `ProgressEvent.SOCKET_DATA`, `flush()`), `send()` helper.
- Any baud rate the driver accepts, 5–8 data bits, none/odd/even/mark/space parity, 1/1.5/2 stop bits, RTS/CTS and XON/XOFF flow control, DTR/RTS line control.
- Any number of ports open at the same time.
- Writes are queued and sent by a background thread; reads are batched into one event per arrival burst.

### Discovery and hot-plug
- `Serial.listPorts()` with device name, manufacturer, USB VID/PID and serial number; `Serial.findPorts(vendorId, productId)`; `Serial.portNames()`.
- `PORT_ADDED` / `PORT_REMOVED` events.
- `autoReconnect`: reopens the port when the device comes back, also on a new COM number for USB devices with a serial number.
- Disconnect detection through I/O errors, Windows removal notifications and the system port list; honours Device Manager *Disable* and *Safely remove hardware* instead of blocking them.

### Framing
- `DelimiterFramer`, `FixedLengthFramer`, `LengthPrefixFramer` (sync bytes, 1/2/4-byte length, adjustable length meaning, trailer, validator).
- `Checksum.xor8`, `sum8`, `crc16Modbus`, `crc16Ccitt`.
- Fast path: `frameHandler` + `reuseFrame` without per-frame allocations.

### Diagnostics
- `SerialPort.stats` (bytes, reads, events, dropped bytes, buffered, pending, removal notification support).
- `Serial.VERSION` / `Serial.nativeVersion`, with a warning when the SWC and ANE come from different releases.

### Platform
- One ANE for AIR 32 – AIR 51, Windows x86 and x64. No additional DLLs or Visual C++ redistributable.
- Windows 10 or later.

[1.2.0]: https://github.com/RJOFX/AirSerial/releases/tag/v1.2.0
[1.1.0]: https://github.com/RJOFX/AirSerial/releases/tag/v1.1.0
[1.0.1]: https://github.com/RJOFX/AirSerial/releases/tag/v1.0.1
[1.0.0]: https://github.com/RJOFX/AirSerial/releases/tag/v1.0.0
