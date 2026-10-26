// -----------------------------------------------------
// AirSerial example: frame script for Adobe Animate (AIR for Desktop)
//  - Text packets of the form S..E (e.g. "S01E"); packets that arrive glued
//    together ("S01ES02E") are split by DelimiterFramer at each 'E'
//  - Picks the first USB serial device automatically; reconnects after unplugging
// Stage: a dynamic text field named txtLog and a movie clip named btnSend.
// Paste into frame 1 of the main timeline. See examples/README.md.
// -----------------------------------------------------

import com.airserial.*;
import com.airserial.framing.*;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;

// =======================
// Settings
// =======================
var comPort:String = "";      // empty = pick a USB serial device automatically, or set e.g. "COM3"
var baudRate:uint = 9600;     // must match Serial.begin() on the device

var port:SerialPort = new SerialPort();
var packets:DelimiterFramer;
var autoPick:Boolean = (comPort == "");

initApp();

// =======================
// Start-up
// =======================
function initApp():void
{
    if (txtLog) txtLog.text = "";

    if (!Serial.isSupported)
    {
        log("[INIT] AirSerial is not available (add the ANE, Windows only)");
        return;
    }
    log("[INIT] AirSerial " + Serial.nativeVersion);

    var ports:Vector.<SerialPortInfo> = Serial.listPorts();
    for each (var p:SerialPortInfo in ports) log("[PORT] " + p);
    if (!comPort) comPort = pickPort(ports);

    port.autoReconnect = true;
    port.addEventListener(Event.CONNECT, onConnect);
    port.addEventListener(Event.CLOSE, onLost);
    port.addEventListener(SerialPortEvent.RECONNECTING, onReconnecting);
    port.addEventListener(IOErrorEvent.IO_ERROR, onError);

    // one frame up to and including each 'E'
    packets = new DelimiterFramer(port, "E", true);
    packets.addEventListener(FrameEvent.FRAME, onFrame);

    // plug / unplug notifications
    Serial.addEventListener(SerialPortEvent.PORT_ADDED, onPortAdded);
    Serial.addEventListener(SerialPortEvent.PORT_REMOVED, onPortRemoved);

    if (comPort)
    {
        log("[INIT] opening " + comPort + " @ " + baudRate);
        port.open(comPort, baudRate);
    }
    else
    {
        log("[INIT] no serial port yet - plug in a device");
    }

    if (btnSend)
    {
        btnSend.buttonMode = true;
        btnSend.addEventListener(MouseEvent.CLICK, onSendClick);
    }

    if (stage && stage.nativeWindow)
    {
        stage.nativeWindow.addEventListener(Event.CLOSING, onAppClosing);
    }
}

// prefer a USB device, otherwise the first port
function pickPort(ports:Vector.<SerialPortInfo>):String
{
    for each (var p:SerialPortInfo in ports)
    {
        if (p.isUSB) return p.port;
    }
    return ports.length ? ports[0].port : "";
}

function log(msg:String):void
{
    trace(msg);
    if (txtLog)
    {
        txtLog.appendText(msg + "\n");
        txtLog.scrollV = txtLog.maxScrollV;
    }
}

// =======================
// Connection state
// =======================
function onConnect(e:Event):void
{
    log("[OPEN] " + port.portName + " connected" + (port.info ? " - " + port.info.displayName : ""));
}

function onLost(e:Event):void
{
    log("[LOST] " + port.lastError);
}

function onReconnecting(e:SerialPortEvent):void
{
    log("[WAIT] plug the device back in to reconnect...");
}

function onError(e:IOErrorEvent):void
{
    log("[ERROR] " + e.text);
}

function onPortAdded(e:SerialPortEvent):void
{
    log("[PLUG] added: " + (e.info ? e.info.toString() : e.portName));

    // in auto-pick mode, switch to a USB device that was plugged in later
    var usingUSB:Boolean = port.connected && port.info && port.info.isUSB;
    if (autoPick && !port.reconnecting && !usingUSB && e.info && e.info.isUSB)
    {
        comPort = e.portName;
        log("[INIT] opening " + comPort + " @ " + baudRate);
        port.open(comPort, baudRate);
    }
}

function onPortRemoved(e:SerialPortEvent):void
{
    log("[PLUG] removed: " + e.portName);
}

// =======================
// Receiving
// =======================
function onFrame(e:FrameEvent):void
{
    // e.g. "S01E"; with noise in front ("xxS01E") use the last 'S'
    var text:String = e.text;
    var start:int = text.lastIndexOf("S");
    if (start < 0)
    {
        log("[WARN] dropped data without 'S': " + text);
        return;
    }
    handlePacket(text.substr(start));
}

// one complete packet, e.g. "S01E"
function handlePacket(packet:String):void
{
    log("[PKT] " + packet);

    var value:String = packet.substring(1, packet.length - 1);   // "S01E" -> "01"
    log("[VAL] " + value);

    // react to the value here
    // if (value == "01") { ... }
}

// =======================
// Sending (test button)
// =======================
function onSendClick(e:MouseEvent):void
{
    if (!port.connected)
    {
        log("[TX] port is not open");
        return;
    }
    var sendStr:String = "S01E";
    port.writeUTFBytes(sendStr);
    port.flush();
    log("[TX] sent: " + sendStr);
}

// =======================
// Clean up on exit
// =======================
function onAppClosing(e:Event):void
{
    port.close();
}
