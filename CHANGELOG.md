# Changelog

All notable changes to AirSerial are listed here. Versions follow [Semantic Versioning](https://semver.org):
MAJOR for incompatible API changes, MINOR for new features, PATCH for fixes.

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

[1.0.0]: https://github.com/RJOFX/AirSerial/releases/tag/v1.0.0
