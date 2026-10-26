// -----------------------------------------------------
// AirSerial + 패킷 파서 예제 (Frame Script)
//  - 패킷 포맷: S..E (예: "S01E")
//  - 붙어서 들어오는 패킷(S01ES01E)은 DelimiterFramer 가 'E' 기준으로 나눠줌
//  - USB 를 뽑았다 꽂으면 자동 재연결 (autoReconnect)
// 스테이지: txtLog (동적 텍스트), btnSend (무비클립). 메인 타임라인 1프레임에 붙여넣기 (examples/README.md 참고)
// -----------------------------------------------------

import com.airserial.*;
import com.airserial.framing.*;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;

// =======================
// 설정
// =======================
var comPort:String = "";      // 비워두면 USB 시리얼 포트를 자동 선택. 직접 지정: "COM3"
var baudRate:uint = 9600;     // 장치 쪽 Serial.begin() 속도와 같아야 함

var port:SerialPort = new SerialPort();
var packets:DelimiterFramer;
var autoPick:Boolean = (comPort == "");

initApp();

// =======================
// 초기화
// =======================
function initApp():void
{
    if (txtLog) txtLog.text = "";

    if (!Serial.isSupported)
    {
        log("[INIT] AirSerial ANE 를 불러오지 못했습니다. (ANE 등록 / Windows 확인)");
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

    // 'E' 가 올 때마다 한 덩어리 (E 포함)
    packets = new DelimiterFramer(port, "E", true);
    packets.addEventListener(FrameEvent.FRAME, onFrame);

    // USB 꽂기/뽑기 알림
    Serial.addEventListener(SerialPortEvent.PORT_ADDED, onPortAdded);
    Serial.addEventListener(SerialPortEvent.PORT_REMOVED, onPortRemoved);

    if (comPort)
    {
        log("[INIT] 포트 열기: " + comPort + " @ " + baudRate);
        port.open(comPort, baudRate);
    }
    else
    {
        log("[INIT] 시리얼 포트가 없습니다. 장치를 꽂으면 목록에 표시됩니다.");
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

// USB 장치를 우선 선택, 없으면 첫 번째 포트
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
// 연결 상태
// =======================
function onConnect(e:Event):void
{
    log("[OPEN] " + port.portName + " 연결됨" + (port.info ? " - " + port.info.displayName : ""));
}

function onLost(e:Event):void
{
    log("[LOST] 연결 끊김: " + port.lastError);
}

function onReconnecting(e:SerialPortEvent):void
{
    log("[WAIT] 장치를 다시 꽂으면 자동으로 연결합니다...");
}

function onError(e:IOErrorEvent):void
{
    log("[ERROR] " + e.text);
}

function onPortAdded(e:SerialPortEvent):void
{
    log("[PLUG] 연결됨: " + (e.info ? e.info.toString() : e.portName));

    // 자동 선택 모드에서 아직 USB 장치를 못 잡았다면 새로 꽂힌 USB 장치로 전환
    var usingUSB:Boolean = port.connected && port.info && port.info.isUSB;
    if (autoPick && !port.reconnecting && !usingUSB && e.info && e.info.isUSB)
    {
        comPort = e.portName;
        log("[INIT] 포트 열기: " + comPort + " @ " + baudRate);
        port.open(comPort, baudRate);
    }
}

function onPortRemoved(e:SerialPortEvent):void
{
    log("[PLUG] 제거됨: " + e.portName);
}

// =======================
// 수신 처리
// =======================
function onFrame(e:FrameEvent):void
{
    // 예: "S01E", 앞에 잡음이 있으면 "xxS01E" -> 마지막 'S' 부터 사용
    var text:String = e.text;
    var start:int = text.lastIndexOf("S");
    if (start < 0)
    {
        log("[WARN] S 없이 끝난 데이터 버림: " + text);
        return;
    }
    handlePacket(text.substr(start));
}

// 완성된 패킷 처리 (예: "S01E")
function handlePacket(packet:String):void
{
    log("[PKT] " + packet);

    var value:String = packet.substring(1, packet.length - 1);   // "S01E" -> "01"
    log("[VAL] " + value);

    // 여기서 value 에 따라 원하는 동작 실행
    // if (value == "01") { ... }
}

// =======================
// 송신 (테스트 버튼)
// =======================
function onSendClick(e:MouseEvent):void
{
    if (!port.connected)
    {
        log("[TX] 포트가 열려있지 않습니다");
        return;
    }
    var sendStr:String = "S01E";
    port.writeUTFBytes(sendStr);
    port.flush();
    log("[TX] 전송: " + sendStr);
}

// =======================
// 앱 종료 시 정리
// =======================
function onAppClosing(e:Event):void
{
    port.close();
}
