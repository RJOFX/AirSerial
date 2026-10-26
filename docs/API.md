# AirSerial API reference

Packages: `com.airserial` (ports) and `com.airserial.framing` (packet helpers).

- [Serial](#serial) — discovery, hot-plug events, versions
- [SerialPort](#serialport) — one COM port
- [SerialPortOptions](#serialportoptions), [Parity](#parity), [FlowControl](#flowcontrol)
- [SerialPortInfo](#serialportinfo), [SerialPortStats](#serialportstats), [SerialPortEvent](#serialportevent)
- Framing: [Framer](#framer), [DelimiterFramer](#delimiterframer), [FixedLengthFramer](#fixedlengthframer), [LengthPrefixFramer](#lengthprefixframer), [FrameEvent](#frameevent), [Checksum](#checksum)

---

## Serial

`com.airserial.Serial` — static class.

| Member | Description |
|---|---|
| `EXTENSION_ID:String` | `"com.airserial.SerialANE"` — the id to put in the app descriptor. |
| `VERSION:String` | Version of the ActionScript library, e.g. `"1.0.0"`. |
| `nativeVersion:String` (get) | Version and architecture of the native part, e.g. `"1.0.0 (Windows x64)"`. `null` if not supported. |
| `isSupported:Boolean` (get) | `true` when the extension loaded (Windows, ANE packaged, `extendedDesktop` profile). |
| `pollInterval:uint` | How often (ms) the port list is re-checked while hot-plug events are watched. Default 1000. |
| `listPorts():Vector.<SerialPortInfo>` | All present ports with device details, sorted `COM1, COM2, … COM10`. About 2 ms. |
| `portNames():Vector.<String>` | Names of present ports only. Very cheap (≈0.04 ms). |
| `getPortInfo(portName):SerialPortInfo` | Details of one port, or `null` if it is not present. |
| `findPorts(vendorId:int, productId:int = -1):Vector.<SerialPortInfo>` | Ports of a USB device by vendor id (and product id). |
| `addEventListener(type, listener, …)` / `removeEventListener` / `hasEventListener` | Static event dispatcher for `SerialPortEvent.PORT_ADDED` / `PORT_REMOVED`. Watching starts while a listener is registered. |

If `VERSION` and `nativeVersion` differ (SWC and ANE from different releases) a warning is traced once.

---

## SerialPort

`com.airserial.SerialPort extends EventDispatcher implements IDataInput, IDataOutput`

Each instance owns its own native context and I/O threads, so any number of ports can be open at once.

### Opening and closing

| Member | Description |
|---|---|
| `SerialPort()` | Creates a closed port. |
| `open(portName:String, baudRate:uint = 9600, options:SerialPortOptions = null):Boolean` | Opens the port (`"COM3"`, `"COM12"`, …). Returns `true` on success and dispatches `Event.CONNECT` on the next frame. On failure returns `false`, sets `lastError` and, if a listener is registered, dispatches `IOErrorEvent.IO_ERROR`. Throws `ArgumentError` for invalid options. Opening an open port closes it first. |
| `close():void` | Closes the port and stops automatic reconnection. Does not dispatch `Event.CLOSE`. |
| `connected:Boolean` (get) | `true` while open. |
| `autoReconnect:Boolean` | When the device is lost, wait for it and reopen automatically (`Event.CONNECT` again). Matches the same port name, or — for USB devices with a serial number — the same VID + PID + serial number on another COM port. Default `false`. |
| `reconnectInterval:uint` | Milliseconds between reconnect attempts. Default 1000. Plug-in events also trigger an immediate attempt. |
| `reconnecting:Boolean` (get) | `true` while waiting for the device. |
| `portName:String`, `baudRate:uint`, `options:SerialPortOptions` (get) | Settings of the current/last open (`options` is a copy). |
| `info:SerialPortInfo` (get) | Device details of the open port (`null` if Windows reports none). Looked up on first access, or at `open()` when `autoReconnect` is on. |
| `lastError:String` (get) | Message of the last open failure or connection loss. |
| `stats:SerialPortStats` (get) | Running totals since `open()`. |

### Reading (`IDataInput`)

Received bytes are buffered; read them in your `ProgressEvent.SOCKET_DATA` handler or later.

`bytesAvailable`, `readBytes(bytes, offset = 0, length = 0)`, `readBoolean()`, `readByte()`, `readUnsignedByte()`, `readShort()`, `readUnsignedShort()`, `readInt()`, `readUnsignedInt()`, `readFloat()`, `readDouble()`, `readMultiByte(length, charSet)`, `readUTF()`, `readUTFBytes(length)`, `readObject()`, plus:

| Member | Description |
|---|---|
| `readAllText():String` | Reads every available byte as UTF-8. |
| `discardInput():void` | Drops everything received but not read yet. |

### Writing (`IDataOutput`)

Writes go to an output buffer; `flush()` queues it for sending. Sending happens on a background thread, so `flush()` never blocks.

`writeBytes(bytes, offset = 0, length = 0)`, `writeBoolean()`, `writeByte()`, `writeShort()`, `writeInt()`, `writeUnsignedInt()`, `writeFloat()`, `writeDouble()`, `writeMultiByte(value, charSet)`, `writeUTF()`, `writeUTFBytes()`, `writeObject()`, plus:

| Member | Description |
|---|---|
| `flush():void` | Sends everything written since the last flush. Throws `IOError` if the port is not open. |
| `send(data:*):void` | Write + flush. Accepts `ByteArray`, `String` (UTF-8), `Array`/`Vector` of byte values, or a single byte value. |
| `bytesPending:uint` (get) | Bytes written but not yet handed to the driver. |
| `endian:String`, `objectEncoding:uint` | Shared by reading and writing. Default `Endian.BIG_ENDIAN`, like `Socket`. |

### Events

| Event | When |
|---|---|
| `Event.CONNECT` | After `open()` succeeded, and after each automatic reconnect. |
| `ProgressEvent.SOCKET_DATA` | New bytes arrived (`bytesLoaded` = count). Arrivals are batched: one event per batch. |
| `Event.CLOSE` | The device was lost: unplugged, disabled in Device Manager, driver error, or the port disappeared from the system. Reason in `lastError`. |
| `IOErrorEvent.IO_ERROR` | `open()` failed (only dispatched if you listen for it). |
| `SerialPortEvent.RECONNECTING` | `autoReconnect` started waiting. |
| `SerialPortEvent.BUFFER_OVERFLOW` | The native receive buffer was full and old bytes were dropped (`droppedBytes` = total so far). |

---

## SerialPortOptions

| Member | Default | Description |
|---|---|---|
| `SerialPortOptions(dataBits = 8, parity = "none", stopBits = 1, flowControl = "none")` | | |
| `dataBits:uint` | 8 | 5, 6, 7 or 8 |
| `parity:String` | `Parity.NONE` | See [Parity](#parity) |
| `stopBits:Number` | 1 | 1, 1.5 or 2 |
| `flowControl:String` | `FlowControl.NONE` | See [FlowControl](#flowcontrol) |
| `dtr:Boolean` | `true` | DTR line while open. Most Arduino boards reset when DTR goes on; Leonardo/Micro only send while it is on. |
| `rts:Boolean` | `true` | RTS line while open (ignored with RTS/CTS flow control). |
| `readBufferSize:uint` | 4 MB | Native receive buffer; when full the oldest bytes are dropped. |
| `clone():SerialPortOptions`, `validate():void`, `toString():String` | | `validate()` throws `ArgumentError` for invalid values. |

## Parity

`Parity.NONE`, `Parity.ODD`, `Parity.EVEN`, `Parity.MARK`, `Parity.SPACE`

## FlowControl

`FlowControl.NONE`, `FlowControl.RTS_CTS` (hardware), `FlowControl.XON_XOFF` (software, XON 0x11 / XOFF 0x13)

---

## SerialPortInfo

| Member | Example | Description |
|---|---|---|
| `port` | `"COM5"` | Port name to pass to `open()` |
| `friendlyName` | `"Arduino Uno (COM5)"` | Device Manager name |
| `description` | `"USB Serial Device"` | Driver description |
| `productName` | `"Arduino Uno"` | Name reported by the USB device itself |
| `manufacturer` | `"Microsoft"` | Driver manufacturer |
| `vendorId`, `productId` | `0x2341`, `0x0043` | USB ids, `-1` if not a USB device |
| `serialNumber` | `"85736323930351F07181"` | Device serial number, `""` if it has none |
| `hardwareId`, `instanceId` | | Raw Windows ids |
| `isUSB` (get) | | `vendorId >= 0` |
| `vendorIdHex`, `productIdHex` (get) | `"2341"` | 4-digit hex, `""` if unknown |
| `displayName` (get) | | Best readable name available |

## SerialPortStats

| Member | Description |
|---|---|
| `bytesReceived`, `bytesSent` | Totals since `open()` |
| `reads` | Driver reads that returned data |
| `dataEvents` | `SOCKET_DATA` batches delivered |
| `droppedBytes` | Bytes dropped because the receive buffer was full |
| `buffered` | Bytes received natively but not yet moved to ActionScript |
| `pending` | Bytes flushed but not yet sent by the driver |
| `removalWatch` | `0` if Windows notifies AirSerial before removing the device; other values: the driver does not support it (common for virtual ports) |

## SerialPortEvent

| Constant | Dispatched by | Properties |
|---|---|---|
| `PORT_ADDED` | `Serial` | `portName`, `info` (may be `null` while Windows is still installing the device) |
| `PORT_REMOVED` | `Serial` | `portName` |
| `RECONNECTING` | `SerialPort` | `portName`, `info` |
| `BUFFER_OVERFLOW` | `SerialPort` | `portName`, `droppedBytes` |

---

## Framer

`com.airserial.framing.Framer extends EventDispatcher` — base class of the framers.

| Member | Description |
|---|---|
| `attach(source:IEventDispatcher)` / `detach()` / `source` | Read from anything that dispatches `ProgressEvent.SOCKET_DATA` and implements `IDataInput` (`SerialPort`, `flash.net.Socket`). The constructor's `source` argument calls `attach`. |
| `push(bytes:ByteArray, offset = 0, length = 0)` | Feed bytes manually. |
| `reset()` | Drop buffered bytes. |
| `bufferedBytes:uint` (get) | Bytes waiting for the rest of a frame. |
| `maxBufferLength:uint` | Unframed bytes beyond this (default 1 MB) are discarded. |
| `frameEndian:String` | Endian of the frame ByteArrays. |
| `frameHandler:Function` | Fast path: `function (frame:ByteArray, payloadOffset:uint, payloadLength:uint):void` called instead of dispatching `FrameEvent.FRAME`. |
| `reuseFrame:Boolean` | With `frameHandler`: reuse one ByteArray for all frames (valid only during the call). |

Events: `FrameEvent.FRAME`, `FrameEvent.DISCARD` (bytes skipped while resynchronising or on overflow).

## DelimiterFramer

`DelimiterFramer(source = null, delimiter:* = "\n", includeDelimiter = false)`

| Member | Description |
|---|---|
| `delimiter` | `String` (UTF-8), `ByteArray` or `Array` of bytes |
| `includeDelimiter:Boolean` | Keep the delimiter at the end of each frame |
| `trimCR:Boolean` | With `"\n"`: also remove a `"\r"` before it (CRLF). Default `true` |
| `skipEmpty:Boolean` | Skip empty frames (blank lines). Default `false` |

## FixedLengthFramer

`FixedLengthFramer(source = null, frameLength:uint = 1)` — every `frameLength` bytes is one frame.

## LengthPrefixFramer

`LengthPrefixFramer(source = null, sync:* = null, lengthSize:uint = 1, lengthEndian:String = "bigEndian", lengthAdjust:int = 0, trailerSize:uint = 0)`

Packet layout: `[sync bytes][length field][body: length + lengthAdjust bytes][trailer bytes]`. The frame contains the whole packet; `payloadOffset` / `payloadLength` point at the body.

| Member | Description |
|---|---|
| `sync` | Marker before every packet: `Array` of bytes, `ByteArray`, `String`, or `null` |
| `lengthSize` | 1, 2 or 4 bytes |
| `lengthAdjust` | Added to the length field to get the body size, e.g. `-2` if the field counts itself |
| `trailerSize` | Bytes after the body (checksum, end marker) |
| `validator:Function` | `function (frame:ByteArray, payloadOffset:uint, payloadLength:uint):Boolean`; `false` drops one byte and resynchronises |
| `maxFrameLength:uint` | Larger packets are treated as corrupt. Default 65536 |

## FrameEvent

| Member | Description |
|---|---|
| `FRAME`, `DISCARD` | Event types |
| `frame:ByteArray` | The frame (position 0). For `DISCARD`, the discarded bytes |
| `payloadOffset`, `payloadLength` | Where the payload is inside `frame` |
| `text:String` (get) | Payload as UTF-8 |
| `payload:ByteArray` (get) | Copy of the payload |

## Checksum

Static functions over `bytes[offset, offset + length)`:

| Function | |
|---|---|
| `xor8(bytes, offset, length):uint` | XOR of all bytes |
| `sum8(bytes, offset, length):uint` | Sum modulo 256 |
| `crc16Modbus(bytes, offset, length):uint` | CRC-16/MODBUS (sent low byte first) |
| `crc16Ccitt(bytes, offset, length):uint` | CRC-16/CCITT-FALSE |
