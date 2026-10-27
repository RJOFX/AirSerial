# AirSerial

**Serial port (COM) native extension for Adobe AIR on Windows.**
Talk to Arduino boards, USB-serial adapters (FTDI, CH340, CP210x, PL2303), PLCs, Modbus devices, sensors and on-board COM ports from ActionScript 3 — with the same API as `flash.net.Socket`.

[![Latest release](https://img.shields.io/github/v/release/RJOFX/AirSerial?label=release)](https://github.com/RJOFX/AirSerial/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/RJOFX/AirSerial/total)](https://github.com/RJOFX/AirSerial/releases)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11%20x86%20%7C%20x64-blue)
![AIR](https://img.shields.io/badge/Adobe%20AIR-32%20%E2%80%93%2051-red)
[![License](https://img.shields.io/badge/license-free%20for%20non--commercial%20use-lightgrey)](LICENSE)

[한국어 문서 (Korean)](README.ko.md) · [API reference](docs/API.md) · [Examples](examples) · [Changelog](CHANGELOG.md) · [FAQ](#faq)

---

## Background

AIR has no serial port API. For years the usual workaround was a proxy program that relayed the COM port to a TCP socket, so most AS3 serial code — and libraries built on it — was written against `flash.net.Socket`.

AirSerial talks to the COM port directly and **behaves like a `Socket`**: the same `IDataInput` / `IDataOutput` methods, the same `ProgressEvent.SOCKET_DATA` event (`"socketData"`), the same `flush()`. Code that reads from a socket can read from a serial port with few or no changes. On top of that it adds what a serial device needs: port discovery, line settings, hot-plug handling and packet framing.

## Features

- **Socket-style API** — `IDataInput` / `IDataOutput`, `ProgressEvent.SOCKET_DATA`, `flush()`.
- **Any line settings** — any baud rate the driver accepts (9600, 115200, 921600, 1000000, …), 5–8 data bits, parity, 1/1.5/2 stop bits, RTS/CTS or XON/XOFF flow control, DTR/RTS control.
- **Port discovery with device details** — device name, manufacturer, USB VID/PID and serial number, so you can find "the Arduino" instead of guessing `COM5`.
- **Hot-plug and auto reconnect** — `PORT_ADDED` / `PORT_REMOVED` events; a port that loses its device reopens by itself when it comes back (even on a different COM number, for devices with a serial number).
- **Never blocks removal** — honours Windows removal requests (Device Manager *Disable*, *Safely remove hardware*) and detects unplugging within a fraction of a second.
- **Stay-connected helper**: `SerialLink` finds the device, keeps retrying and reconnecting, holds and resends the latest message, adds start/end bytes and logs everything, so a kiosk or exhibit needs only `send()`.
- **Multiple ports at once**, each with its own I/O threads.
- **Packet framing helpers** — line/delimiter, fixed length, sync + length prefix with checksum validation (XOR, SUM, CRC-16 Modbus, CRC-16 CCITT), plus a zero-allocation fast path.
- **Fast** — 0.05 ms round trip, 250+ MB/s through a virtual port pair; writes never stall the UI.
- **One ANE for everything** — AIR 32 to AIR 51, 32-bit and 64-bit apps. No extra DLLs, no Visual C++ redistributable.

## Requirements

| | |
|---|---|
| OS | Windows 10 or 11, 32-bit or 64-bit apps |
| Runtime | Adobe AIR 32 or newer (tested with AIR 32.0 and HARMAN AIR 51.2) |
| Tools | Adobe Animate, Flash Builder, IntelliJ IDEA, VS Code + AIR SDK, or the command line (`amxmlc` / `adt`) |
| App profile | `extendedDesktop` (required for native extensions) |

## Download

Get **`AirSerial.ane`** from the [latest release](https://github.com/RJOFX/AirSerial/releases/latest) — or the zip, which also contains the documentation and examples.

| File | What it is |
|---|---|
| `AirSerial.ane` | The extension. Add it to your project; it is packaged with your app. |
| `AirSerial.swc` | Optional. Code hints in IDEs that do not read ANEs. Must be the same version as the ANE. |
| `AirSerial-x.y.z.zip` | Both files plus README, license and examples. |

Direct links to the newest version: [AirSerial.ane](https://github.com/RJOFX/AirSerial/releases/latest/download/AirSerial.ane) · [AirSerial.swc](https://github.com/RJOFX/AirSerial/releases/latest/download/AirSerial.swc)

## Installation

### Adobe Animate

1. **File › ActionScript Settings › Library path** → **+ (Add Native Extension)** → choose `AirSerial.ane`.
2. Make sure the AIR application descriptor (`YourApp-app.xml`) lists the extension (Animate normally adds it for you):
   ```xml
   <extensions>
       <extensionID>com.airserial.SerialANE</extensionID>
   </extensions>
   ```
3. **Control › Test (Ctrl+Enter)**. The Output panel shows `[SWF] com.airserial.SerialANE ...` when the extension is loaded.
4. **Publish** (File › Publish Settings › AIR settings): choose installer or captive runtime (`.exe`) and a signing certificate (a self-signed one can be created on the same screen). The ANE is packaged automatically.

> **Do not use parentheses in the app file name** (`<filename>` in the descriptor, e.g. `my (test) app`). AIR's packager (ADT) fails with `Unmatched closing ')'`. The display name (`<name>`) may contain anything.

### Flash Builder

1. **Project › Properties › ActionScript Build Path › Native Extensions** → **Add ANE…** → `AirSerial.ane`.
2. **Project › Properties › ActionScript Build Packaging › Native Extensions** → tick **Package** for `AirSerial.ane`.
3. Run or debug as usual; the descriptor gets the `<extensions>` entry automatically.

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

The descriptor needs `<supportedProfiles>extendedDesktop desktop</supportedProfiles>` (or no `supportedProfiles` at all) and the `<extensions>` entry above.

## Use

Create a `SerialPort`, open it with the COM port and baud rate, and close it when your application ends.

```actionscript
import com.airserial.*;
import flash.desktop.NativeApplication;
import flash.events.*;

public var port:SerialPort;

public function initApp():void
{
    port = new SerialPort();
    port.addEventListener(ProgressEvent.SOCKET_DATA, onData);
    port.addEventListener(Event.CLOSE, onLost);
    if (!port.open("COM3", 9600))          // most Arduino sketches use 9600 or 115200
        trace("cannot open:", port.lastError);

    NativeApplication.nativeApplication.addEventListener(Event.EXITING, closeApp);
}

protected function closeApp(event:Event):void
{
    port.close();
}
```

Not sure which port it is? `Serial.listPorts()` lists the ports that exist right now, with device names and USB ids:

```actionscript
for each (var p:SerialPortInfo in Serial.listPorts())
    trace(p.port, p.displayName, p.vendorIdHex, p.productIdHex, p.serialNumber);
// COM5  Arduino Uno (COM5)  2341  0043  85736323930351F07181

var arduinos:Vector.<SerialPortInfo> = Serial.findPorts(0x2341);      // by USB vendor id
var ftdi:Vector.<SerialPortInfo> = Serial.findPorts(0x0403, 0x6001);  // vendor + product id
```

Line settings other than 8N1 go in a `SerialPortOptions`:

```actionscript
// 7 data bits, even parity, 2 stop bits, hardware handshake
var o:SerialPortOptions = new SerialPortOptions(7, Parity.EVEN, 2, FlowControl.RTS_CTS);
o.dtr = true;          // default true. Arduino Leonardo/Micro only send while DTR is on
port.open("COM3", 9600, o);
```

### Reading data

When data arrives, `SerialPort` dispatches `ProgressEvent.SOCKET_DATA` (`"socketData"`). Check `bytesAvailable` and read with any `IDataInput` method — exactly like a `Socket`:

```actionscript
function onData(event:ProgressEvent):void
{
    while (port.bytesAvailable > 0)
        trace(port.readUnsignedByte());
}
```

- `readUTFBytes(length)`, `readAllText()` — text
- `readBytes(byteArray, offset, length)` — raw bytes
- `readUnsignedByte()`, `readShort()`, `readInt()`, `readFloat()`, `readDouble()`, … — numbers (`endian` sets the byte order)

Bytes stay buffered until you read them, so you can also read later. Arrivals are batched into one event, and the native receive buffer holds 4 MB by default. For packets (lines, fixed records, binary frames) use a framer — see [Packets](#packets-framing).

### Sending data

Write with any `IDataOutput` method, then call `flush()` to send — exactly like a `Socket`. `send()` does both in one call:

```actionscript
port.writeUTFBytes("LED ON\n");
port.writeByte(0x01);
port.flush();

port.send("hello\n");                  // String (UTF-8)
port.send([0x01, 0x03, 0x00, 0x01]);   // bytes
```

`flush()` hands the data to a background thread and returns immediately; your frame rate is not affected even for large transfers. `bytesPending` tells how much is still waiting. Writing to a port that is not open throws an `IOError`.

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

Thousands of packets per second? Use the fast path — no event object and no ByteArray per packet (about 3× faster for small packets):

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

AirSerial notices a lost device in three ways — I/O errors, Windows removal notifications, and the port disappearing from the system list — so it also works with drivers that keep a removed port's handle alive. Typical detection time is 0.2–0.6 s; reconnection follows about 0.3 s after the device is back. `Event.CLOSE` reports the loss, `Event.CONNECT` the reconnection.

## Keeping a device connected (SerialLink)

For an app that should simply "always talk to the device" (a kiosk, an exhibit, a machine panel), `SerialLink` does the connection work for you:

```actionscript
var link:SerialLink = new SerialLink();
link.configure({port: "auto", baud: 115200, suffix: "\n", log: "serial.log"});
link.start();

link.send("LED ON");    // sent now, or held and sent as soon as the device is connected
link.addEventListener(FrameEvent.FRAME, function (e:FrameEvent):void { trace("device says", e.text); });
trace(link.status);     // connected COM5 @115200, last sent: LED ON, [SerialPortStats ...]
```

- **Finds the port**: a fixed name (`"COM3"`), or `"auto"`: the USB device with `vid`/`pid`, else the first USB serial port.
- **Keeps trying** until the port opens (device missing, port used by another program), and tries again at once when a device is plugged in.
- **Reconnects** when the device is lost; with `"auto"` it follows the device to another USB socket even if the chip has no serial number.
- **Never loses the latest message**: while disconnected the latest `send()` is held and sent on connect; after a reconnect the last message is sent again so the device matches the app.
- **Message framing**: `prefix` / `suffix` bytes are added to every message (e.g. `suffix: "\n"`, or `prefix: 0x02, suffix: 0x03`), and received data is split at `suffix`. Data without `prefix`, or that never gets its `suffix`, is logged as hex and dropped.
- **Log**: every connect, loss, send and receive goes to `trace`, a `log` event and optionally a log file in the app storage folder.

`configure()` takes a plain object, so the settings can live in a JSON file next to the app; a second object supplies defaults for keys the file does not have. Keys: `port`, `baud`, `vid`, `pid`, `dataBits`, `parity`, `stopBits`, `dtr`, `rts`, `prefix`, `suffix`, `retry`, `receiveTimeout`, `resend`, `log`. See the [API reference](docs/API.md#seriallink).

## Events

| Dispatcher | Event | When |
|---|---|---|
| `SerialPort` | `Event.CONNECT` | after a successful `open()` (next frame, or a few seconds later for a USB adapter that was just plugged in) and after each automatic reconnect |
| | `ProgressEvent.SOCKET_DATA` | new bytes are available (`bytesLoaded` = how many) |
| | `Event.CLOSE` | the device was lost (unplugged, disabled, driver error); reason in `lastError`. Not dispatched by `close()` |
| | `IOErrorEvent.IO_ERROR` | `open()` failed — only if you listen for it; `open()` also returns `false`, unless it was still finishing in the background |
| | `SerialPortEvent.RECONNECTING` | `autoReconnect` started waiting for the device |
| | `SerialPortEvent.BUFFER_OVERFLOW` | the receive buffer was full and the oldest bytes were dropped |
| `Serial` (static) | `SerialPortEvent.PORT_ADDED` / `PORT_REMOVED` | a COM port appeared / disappeared |
| `SerialLink` | `Event.CONNECT` / `Event.CLOSE` | connected (also after each reconnect) / connection lost |
| | `FrameEvent.FRAME` | a received message (data up to `suffix`, `prefix` removed) |
| | `FrameEvent.DISCARD` | received bytes that were dropped (no `prefix`, or no `suffix` in time) |
| | `"log"` (`TextEvent`) | a log line |

## Migrating from as3-arduino-connector

AirSerial can replace the `ArduinoConnector` ANE (`com.quetwo.Arduino`). The data event has the same name (`"socketData"`), so most listener code keeps working.

| ArduinoConnector | AirSerial |
|---|---|
| `new ArduinoConnector()` | `new SerialPort()` |
| `connect("COM10", 9600)` | `open("COM10", 9600)` — also returns `Boolean`; reason in `lastError` |
| `portOpen` | `connected` |
| `getComPorts()` (fixed list COM1–COM16) | `Serial.portNames()` (ports that exist) or `Serial.listPorts()` (with device details) |
| `addEventListener("socketData", …)` | unchanged, or `ProgressEvent.SOCKET_DATA` |
| `bytesAvailable` | `bytesAvailable` |
| `readBytesAsString()` | `readUTFBytes(bytesAvailable)` or `readAllText()` |
| `readBytesAsByteArray()` | `readBytes(myByteArray)` |
| `readBytesAsArray()` | loop over `readUnsignedByte()` |
| `readByte()` (returns `uint`) | `readUnsignedByte()` — AirSerial's `readByte()` is signed, as in `IDataInput` |
| `writeString(s)` / `writeByte(b)` / `writeBytes(ba)` | the same `write…` call followed by `flush()`, or `send(s)` / `send(b)` / `send(ba)` |
| `flush()` (did nothing) | `flush()` sends the written data |
| `close()` / `dispose()` | `close()` |
| `isSupported()` | `Serial.isSupported` |

What you gain: 64-bit apps and AIR 33–51, any baud rate and line setting, binary data, no 4 KB buffer limit, device discovery, hot-plug and auto reconnect, and no extra `pthreadGC2.dll`.

## Diagnostics

```actionscript
trace(Serial.VERSION, Serial.nativeVersion);   // 1.2.2  1.2.2 (Windows x64)
trace(port.stats);   // [SerialPortStats rx=20971520 tx=0 reads=320 events=155 dropped=0 buffered=0 pending=0 removalWatch=0]
```

`droppedBytes` growing means your code does not read fast enough. Please include both lines when you report a problem.

## FAQ

**`Serial.isSupported` is `false` / "native extension is not available".**
The ANE is not added to the project, the app does not run with the `extendedDesktop` profile, or it is not running on Windows. In Animate, check the library path; on the command line, check `-extdir` and the `<extensions>` entry.

**"Port is in use by another program".**
Only one program can open a COM port. Close the Arduino IDE's Serial Monitor, terminal programs, or another instance of your app.

**"Port settings rejected by driver".**
The device or driver does not support that baud rate or setting. On-board COM ports usually stop at 115200; USB adapters go much higher.

**The Arduino restarts every time I open the port.**
That is how most boards work (the DTR line resets them). Wait for the board's first message before sending, or set `options.dtr = false` if your board and sketch do not need the reset.

**My Arduino Leonardo / Micro / Pro Micro sends nothing.**
These boards only send while DTR is on. Keep `dtr = true` (the default).

**Text looks garbled.**
The baud rate does not match `Serial.begin()` on the device, or the device does not send UTF-8 (use `readMultiByte(length, "euc-kr")` etc.).

**Do I need to call `close()` before the app exits?**
It is good practice and releases the port immediately, but since 1.0.1 the app also shuts down cleanly if you forget.

**Warning "library x is used with native y".**
`AirSerial.swc` and `AirSerial.ane` come from different releases. Use both files from the same release.

**Publishing fails with `Unmatched closing ')'`.**
Remove parentheses from the app `<filename>` in the descriptor.

**Device Manager asks for a reboot when I disable a virtual port (com0com, VSPE).**
Those drivers do not support removal notifications. Close the port first. Real USB devices and on-board ports are released automatically.

## Feedback

Bug reports, questions and feature requests are welcome in [Issues](https://github.com/RJOFX/AirSerial/issues). Please include Windows version, AIR SDK version, `Serial.VERSION` / `Serial.nativeVersion`, the device or USB adapter, and a few lines of code that show the problem.

## Versioning

AirSerial follows [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`. Every release lists its changes in the [changelog](CHANGELOG.md), and the version is stamped into the ANE descriptor, the DLL file properties and `Serial.VERSION`.

## License

AirSerial is **free for personal, educational and other non-commercial use**. Commercial use requires a separate license — open an issue titled *Commercial license*. See [LICENSE](LICENSE) for the full terms.

© 2026 RJOFX
