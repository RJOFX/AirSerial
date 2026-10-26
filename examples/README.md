# Examples

| Example | What it shows |
|---|---|
| [document-class/SerialDemo.as](document-class/SerialDemo.as) | The smallest complete app as a class: `initApp()` / `closeApp()`, picks a USB serial device (or the port given on the command line), echoes every received line back, auto reconnect. Works as an Animate *Document class*, a Flash Builder / IntelliJ main class or with `amxmlc` |
| [animate/FrameScript.as](animate/FrameScript.as) ([한국어](animate/FrameScript.ko.as)) | Complete Animate frame script: auto-pick a USB serial device, text packets with `DelimiterFramer`, send button, plug/unplug events, auto reconnect, clean-up on exit |
| [arduino/AirSerialEcho](arduino/AirSerialEcho/AirSerialEcho.ino) | Arduino sketch that echoes everything back (115200 baud) — a quick way to test your AirSerial app with real hardware |

## Document class (SerialDemo)

[SerialDemo.as](document-class/SerialDemo.as) opens a port at **9600** baud, sends `hello from AirSerial`, and answers every line it receives with `echo: <line>`. Without a port name it uses the first USB serial device, otherwise the first COM port.

**Animate**
1. **File › New › AIR for Desktop**, save the FLA next to `SerialDemo.as`.
2. Add `AirSerial.ane` (**File › ActionScript Settings › Library path › + (Add Native Extension)**).
3. In the **Properties** panel, set **Class** (Document class) to `SerialDemo` and press **Ctrl+Enter**.

**Flash Builder / IntelliJ IDEA**
Create an ActionScript AIR desktop project with `SerialDemo.as` as the main class, add `AirSerial.ane` as a native extension and run it. To choose the port, put it in the launch arguments (e.g. `COM5`).

**Command line**
```bat
amxmlc -external-library-path+=AirSerial.ane -output SerialDemo.swf SerialDemo.as
mkdir ext\AirSerial.ane
tar -xf AirSerial.ane -C ext\AirSerial.ane
adl -profile extendedDesktop -extdir ext SerialDemo-app.xml . -- COM5
```
[SerialDemo-app.xml](document-class/SerialDemo-app.xml) is a ready-made application descriptor (change `<versionNumber>` / `<id>` for your own app).

To try it with an Arduino, upload the [echo sketch](#arduino-echo-sketch) and change both baud rates to the same value.

## Animate frame script

1. **File › New › AIR for Desktop**.
2. Add `AirSerial.ane`: **File › ActionScript Settings › Library path › + (Add Native Extension)**.
3. On the stage, create a **dynamic text field** with instance name `txtLog` (multiline, large enough for a log) and a **movie clip** with instance name `btnSend`.
4. Select frame 1 of the main timeline, open **Window › Actions** and paste [FrameScript.as](animate/FrameScript.as).
5. Set `baudRate` at the top to match your device and press **Ctrl+Enter**.

The script expects text packets like `S01E` (start `S`, value, end `E`). Change `handlePacket()` for your own protocol, or swap the `DelimiterFramer` for a `LengthPrefixFramer` for binary protocols (see the [README](../README.md#packets-framing)).

## Arduino echo sketch

Upload [AirSerialEcho.ino](arduino/AirSerialEcho/AirSerialEcho.ino) with the Arduino IDE, close the IDE's Serial Monitor (it would hold the port), then open the board's port at **115200** from AirSerial. The board prints `READY` after it boots (opening the port resets most boards) and returns every byte you send.

## Example code license

You may copy and change the example code freely in your own applications (see [LICENSE](../LICENSE), section 5).
