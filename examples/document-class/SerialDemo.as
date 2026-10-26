package {

import com.airserial.Serial;
import com.airserial.SerialPort;
import com.airserial.SerialPortEvent;
import com.airserial.SerialPortInfo;
import com.airserial.framing.DelimiterFramer;
import com.airserial.framing.FrameEvent;

import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.InvokeEvent;
import flash.text.TextField;
import flash.text.TextFormat;

/**
 * AirSerial example: document class (Animate "Document class", Flash Builder / IntelliJ main class, amxmlc).
 *
 * Opens a serial port, answers every text line it receives with "echo: <line>", and says hello
 * whenever the connection is (re)established. Unplug the device and plug it back in: it reconnects.
 * Everything is shown in a text field created in code, so no stage objects are needed.
 *
 * Port: first command line argument (e.g. "COM3"), otherwise the first USB serial device,
 * otherwise the first port.
 */
public class SerialDemo extends Sprite {

    public var port:SerialPort;
    public var lines:DelimiterFramer;

    private var output:TextField;

    public function SerialDemo() {
        output = new TextField();
        output.defaultTextFormat = new TextFormat("Consolas", 13);
        output.width = 640;
        output.height = 400;
        output.multiline = true;
        addChild(output);

        NativeApplication.nativeApplication.addEventListener(Event.EXITING, closeApp);
        NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, function (e:InvokeEvent):void {
            initApp(e.arguments.length > 0 ? e.arguments[0] : null);
        });
    }

    public function initApp(portName:String):void {
        if (!Serial.isSupported) {
            log("AirSerial is not available (Windows only, ANE must be packaged)");
            return;
        }
        log("AirSerial " + Serial.nativeVersion);
        portName ||= pickPort();
        if (!portName) {
            log("No serial port found");
            return;
        }

        port = new SerialPort();
        port.autoReconnect = true;
        port.addEventListener(Event.CONNECT, onConnect);
        port.addEventListener(Event.CLOSE, onLost);
        port.addEventListener(IOErrorEvent.IO_ERROR, onError);
        port.addEventListener(SerialPortEvent.RECONNECTING, onReconnecting);

        // one FrameEvent per received text line ("\n"; a trailing "\r" is removed)
        lines = new DelimiterFramer(port);
        lines.addEventListener(FrameEvent.FRAME, onLine);

        log("Opening " + portName + " at 9600 baud");
        port.open(portName, 9600);
    }

    protected function closeApp(event:Event):void {
        if (port) port.close();
    }

    // ------------------------------------------------------------------ connection

    private function onConnect(event:Event):void {
        log("Connected: " + port.portName + (port.info ? " (" + port.info.displayName + ")" : ""));
        port.send("hello from AirSerial\n");
    }

    private function onLost(event:Event):void {
        log("Connection lost: " + port.lastError);
    }

    private function onReconnecting(event:SerialPortEvent):void {
        log("Waiting for " + event.portName + " to come back...");
    }

    private function onError(event:IOErrorEvent):void {
        log("Cannot open: " + event.text);
    }

    // ------------------------------------------------------------------ data

    private function onLine(event:FrameEvent):void {
        var line:String = event.text;
        log("< " + line);
        port.writeUTFBytes("echo: " + line + "\n");
        port.flush();
    }

    // ------------------------------------------------------------------ helpers

    private function pickPort():String {
        var ports:Vector.<SerialPortInfo> = Serial.listPorts();
        for each (var p:SerialPortInfo in ports) {
            log("found " + p);
            if (p.isUSB) return p.port;
        }
        return ports.length > 0 ? ports[0].port : null;
    }

    private function log(message:String):void {
        trace(message);
        output.appendText(message + "\n");
        output.scrollV = output.maxScrollV;
    }
}
}
