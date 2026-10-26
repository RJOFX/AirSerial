# AirSerial

**Serial port (COM) native extension for Adobe AIR on Windows.**
Talk to Arduino boards, USB-serial adapters (FTDI, CH340, CP210x, PL2303), PLCs, Modbus devices, sensors and on-board COM ports from ActionScript 3 — with the same API as `flash.net.Socket`.

[![Latest release](https://img.shields.io/github/v/release/RJOFX/AirSerial?label=release)](https://github.com/RJOFX/AirSerial/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/RJOFX/AirSerial/total)](https://github.com/RJOFX/AirSerial/releases)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11%20x86%20%7C%20x64-blue)
![AIR](https://img.shields.io/badge/Adobe%20AIR-32%20%E2%80%93%2051-red)
[![License](https://img.shields.io/badge/license-free%20for%20non--commercial%20use-lightgrey)](LICENSE)

[한국어 문서 (Korean)](README.ko.md) · [API reference](docs/API.md) · [Changelog](CHANGELOG.md) · [Examples](examples)

---

## Features

- **Socket-style API** — `IDataInput` / `IDataOutput`, `ProgressEvent.SOCKET_DATA`, `flush()`. If you know `Socket`, you know AirSerial.
- **Any line settings** — any baud rate the driver accepts (9600 … 3 Mbps), 5–8 data bits, parity, 1/1.5/2 stop bits, RTS/CTS or XON/XOFF flow control, DTR/RTS control.
- **Port discovery with device details** — device name, manufacturer, USB VID/PID and serial number, so you can find "the Arduino" instead of guessing `COM5`.
- **Hot-plug and auto reconnect** — `PORT_ADDED` / `PORT_REMOVED` events; a port that loses its device reopens by itself when it comes back (even on a different COM number, for devices with a serial number).
- **Never blocks removal** — honours Windows removal requests (Device Manager *Disable*, *Safely remove hardware*), and detects unplugging within a fraction of a second.
- **Multiple ports at once**, each with its own I/O threads.
- **Packet framing helpers** — line/delimiter, fixed length, sync + length prefix with checksum validation (XOR, SUM, CRC-16 Modbus, CRC-16 CCITT), plus a zero-allocation fast path.
- **Fast** — 0.05 ms round trip, 250+ MB/s through a virtual port pair, writes never stall the UI.
- **One ANE for everything** — AIR 32 to AIR 51, 32-bit and 64-bit apps. No extra DLLs, no Visual C++ redistributable.

## Requirements

| | |
|---|---|
| OS | Windows 10 or 11, 32-bit or 64-bit apps |
| Runtime | Adobe AIR 32 or newer (tested with AIR 32.0 and HARMAN AIR 51.2) |
| Tools | Adobe Animate, or any AS3 toolchain (Flash Builder, IntelliJ IDEA, VS Code + AIR SDK, command line `amxmlc`/`adt`) |
| App profile | `extendedDesktop` (required for native extensions) |

## Download

Get **`AirSerial.ane`** from the [latest release](https://github.com/RJOFX/AirSerial/releases/latest).
`AirSerial.swc` is the same ActionScript library without the native part — some IDEs use it for code completion.

| File | What it is |
|---|---|
| `AirSerial.ane` | The extension. Add it to your project and package it with your app. |
| `AirSerial.swc` | Optional. Code hints in IDEs that do not read ANEs. Must be the same version as the ANE. |

Direct links to the newest version: [AirSerial.ane](https://github.com/RJOFX/AirSerial/releases/latest/download/AirSerial.ane) · [AirSerial.swc](https://github.com/RJOFX/AirSerial/releases/latest/download/AirSerial.swc)

## Installation

### Adobe Animate

1. **File › ActionScript Settings › Library path** → **+ (Add Native Extension)** → choose `AirSerial.ane`.
2. Make sure your AIR application descriptor (`YourApp-app.xml`) lists the extension (Animate normally adds it for you):
   ```xml
   <extensions>
       <extensionID>com.airserial.SerialANE</extensionID>
   </extensions>
   ```
3. **Control › Test (Ctrl+Enter)**. The Output panel shows `[SWF] com.airserial.SerialANE ...` when the extension is loaded.
4. **Publish** (File › Publish Settings › AIR settings): choose installer or captive runtime (`.exe`) and a signing certificate (a self-signed one can be created on the same screen). The ANE is packaged automatically.

> **Do not use parentheses in the app file name** (`<filename>` in the descriptor, e.g. `my (test) app`). AIR's packager (ADT) fails with `Unmatched closing ')'`. The display name (`<name>`) may contain anything.

### Command line / other IDEs

```bat
:: compile: link the ANE externally
amxmlc -external-library-path+=AirSerial.ane -output MyApp.swf MyApp.as

:: test with ADL: unzip the ANE into a folder named AirSerial.ane first
mkdir ext\AirSerial.ane
tar -xf AirSerial.ane -C ext\AirSerial.ane
adl -profile extendedDesktop -extdir ext MyApp-app.xml .

:: package: point -extdir at the folder that contains AirSerial.ane
adt -package -storetype pkcs12 -keystore cert.p12 -target bundle MyApp MyApp-app.xml MyApp.swf -extdir anes
:: 64-bit app (AIR 33+):  add  -arch x64  after -target bundle
```

Your descriptor needs `<supportedProfiles>extendedDesktop desktop</supportedProfiles>` (or no `supportedProfiles` at all) and the `<extensions>` entry above.

## Quick start

```actionscript
import com.airserial.*;
import flash.events.*;

var port:SerialPort = new SerialPort();
port.addEventListener(Event.CONNECT, function (e:Event):void { trace("open:", port.portName); });
port.addEventListener(ProgressEvent.SOCKET_DATA, onData);
port.addEventListener(Event.CLOSE, function (e:Event):void { trace("lost:", port.lastError); });

if (!port.open("COM3", 115200)) trace("cannot open:", port.lastError);

function onData(e:ProgressEvent):void {
    trace(port.readUTFBytes(port.bytesAvailable));
}

port.writeUTFBytes("hello\n");
port.flush();                 // like Socket: data is sent on flush()
port.send("hello\n");         // write + flush in one call (String, ByteArray, [bytes])
```

Close the port when you are done (`port.close()`), e.g. on `Event.CLOSING` of the window.

## Finding the right port

```actionscript
for each (var p:SerialPortInfo in Serial.listPorts())
    trace(p.port, p.displayName, p.vendorIdHex, p.productIdHex, p.serialNumber);
// COM5  Arduino Uno (COM5)  2341  0043  85736323930351F07181

var arduinos:Vector.<SerialPortInfo> = Serial.findPorts(0x2341);      // by USB vendor id
var ftdi:Vector.<SerialPortInfo> = Serial.findPorts(0x0403, 0x6001);  // vendor + product id
```

## Line settings

```actionscript
// 7 data bits, even parity, 2 stop bits, hardware handshake
var o:SerialPortOptions = new SerialPortOptions(7, Parity.EVEN, 2, FlowControl.RTS_CTS);
o.dtr = true;          // default true. Arduino Leonardo/Micro only send while DTR is on
port.open("COM3", 9600, o);
```

## Packets (framing)

A framer reads everything the port receives and hands you complete packets. Attach it to a `SerialPort` (or a `flash.net.Socket`), or feed it with `push()`. Once attached, read from the framer only.

```actionscript
import com.airserial.framing.*;

// one frame per text line ("\n", a trailing "\r" is removed)
var lines:DelimiterFramer = new DelimiterFramer(port);
lines.addEventListener(FrameEvent.FRAME, function (e:FrameEvent):void { trace(e.text); });

// fixed size records
var records:FixedLengthFramer = new FixedLengthFramer(port, 6);

// AA 55 | length (1 byte) | payload | XOR checksum (1 byte)
var packets:LengthPrefixFramer = new LengthPrefixFramer(port, [0xAA, 0x55], 1, Endian.BIG_ENDIAN, 0, 1);
packets.validator = function (frame:ByteArray, offset:uint, length:uint):Boolean {
    return Checksum.xor8(frame, offset, length) == frame[offset + length];
};
packets.addEventListener(FrameEvent.FRAME, function (e:FrameEvent):void {
    var payload:ByteArray = e.payload;
});
```

Thousands of packets per second? Use the fast path — no event object and no ByteArray per packet (3× faster for small packets):

```actionscript
packets.reuseFrame = true;    // the same ByteArray is reused: copy what you keep
packets.frameHandler = function (frame:ByteArray, payloadOffset:uint, payloadLength:uint):void {
    frame.position = payloadOffset;
    var value:int = frame.readShort();
};
```

## Unplugging and reconnecting

```actionscript
port.autoReconnect = true;    // reopen automatically when the device is back
port.addEventListener(SerialPortEvent.RECONNECTING, function (e:SerialPortEvent):void { trace("waiting for", e.portName); });

Serial.addEventListener(SerialPortEvent.PORT_ADDED,   function (e:SerialPortEvent):void { trace("+", e.portName, e.info); });
Serial.addEventListener(SerialPortEvent.PORT_REMOVED, function (e:SerialPortEvent):void { trace("-", e.portName); });
```

AirSerial notices a lost device in three ways — I/O errors, Windows removal notifications, and the port disappearing from the system list — so it also works with drivers that keep a removed port's handle alive. Typical detection time is 0.2–0.6 s; reconnection follows about 0.3 s after the device is back.

## Events

| Dispatcher | Event | When |
|---|---|---|
| `SerialPort` | `Event.CONNECT` | after a successful `open()` (next frame) and after each automatic reconnect |
| | `ProgressEvent.SOCKET_DATA` | new bytes are available (`bytesLoaded` = how many) |
| | `Event.CLOSE` | the device was lost (unplugged, disabled, driver error); reason in `lastError`. Not dispatched by `close()` |
| | `IOErrorEvent.IO_ERROR` | `open()` failed — only if you listen for it; `open()` also returns `false` |
| | `SerialPortEvent.RECONNECTING` | `autoReconnect` started waiting for the device |
| | `SerialPortEvent.BUFFER_OVERFLOW` | the receive buffer (4 MB by default) was full and the oldest bytes were dropped |
| `Serial` (static) | `SerialPortEvent.PORT_ADDED` / `PORT_REMOVED` | a COM port appeared / disappeared |

## Diagnostics

```actionscript
trace(Serial.VERSION, Serial.nativeVersion);   // 1.0.0  1.0.0 (Windows x64)
trace(port.stats);   // [SerialPortStats rx=20971520 tx=0 reads=320 events=155 dropped=0 buffered=0 pending=0 removalWatch=0]
```

`droppedBytes` growing means your code does not read fast enough. Please include both lines when you report a problem.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Serial.isSupported` is `false` / "native extension is not available" | The ANE is not added to the project, the app does not use the `extendedDesktop` profile, or the app is not running on Windows. |
| "Port is in use by another program" | Close the other program (Arduino IDE serial monitor, terminal programs, another instance of your app). |
| "Port settings rejected by driver" | The device/driver does not support that baud rate or setting. On-board COM ports usually stop at 115200. |
| The Arduino restarts when the port opens | Normal for most boards (DTR reset). Wait for its first message, or set `options.dtr = false`. |
| Arduino Leonardo / Micro / Pro Micro sends nothing | Keep `dtr = true` (default). |
| Warning "library x is used with native y" | The SWC and ANE come from different releases. Use files from one release. |
| Publishing fails with `Unmatched closing ')'` | Remove parentheses from the app `<filename>`. |
| Device Manager asks for a reboot when disabling a virtual port (com0com, VSPE) | Those drivers do not support removal notifications; close the port first. Real USB devices are fine. |

## Feedback

Bug reports, questions and feature requests are welcome in [Issues](https://github.com/RJOFX/AirSerial/issues). Please include Windows version, AIR SDK version, `Serial.VERSION` / `Serial.nativeVersion`, the device or USB adapter, and a few lines of code that show the problem.

## Versioning

AirSerial follows [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`. Every release lists its changes in the [changelog](CHANGELOG.md), and the version is stamped into the ANE descriptor, the DLL file properties and `Serial.VERSION`.

## License

AirSerial is **free for personal, educational and other non-commercial use**. Commercial use requires a separate license — open an issue titled *Commercial license*. See [LICENSE](LICENSE) for the full terms.

© 2026 RJOFX
