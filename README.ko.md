# AirSerial

**Adobe AIR(Windows)용 시리얼 포트(COM) 네이티브 익스텐션.**
아두이노, USB-시리얼 어댑터(FTDI, CH340, CP210x, PL2303), PLC, Modbus 장비, 센서, 메인보드 COM 포트와 ActionScript 3 로 통신합니다. 사용법은 `flash.net.Socket` 과 같습니다.

[![Latest release](https://img.shields.io/github/v/release/RJOFX/AirSerial?label=release)](https://github.com/RJOFX/AirSerial/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/RJOFX/AirSerial/total)](https://github.com/RJOFX/AirSerial/releases)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11%20x86%20%7C%20x64-blue)
![AIR](https://img.shields.io/badge/Adobe%20AIR-32%20%E2%80%93%2051-red)
[![License](https://img.shields.io/badge/license-free%20for%20non--commercial%20use-lightgrey)](LICENSE)

[English](README.md) · [API 레퍼런스](docs/API.md) · [변경 이력](CHANGELOG.md) · [예제](examples)

---

## 특징

- **Socket 과 같은 API** — `IDataInput` / `IDataOutput`, `ProgressEvent.SOCKET_DATA`, `flush()`. Socket 을 써봤다면 바로 사용할 수 있습니다.
- **모든 회선 설정** — 드라이버가 허용하는 아무 보레이트, 데이터비트 5–8, 패리티, 스톱비트 1/1.5/2, RTS/CTS·XON/XOFF 흐름제어, DTR/RTS.
- **장치 정보와 함께 포트 찾기** — 장치명, 제조사, USB VID/PID, 시리얼번호. `COM5` 를 짐작하지 않고 "아두이노" 를 찾을 수 있습니다.
- **꽂기·뽑기 감지와 자동 재연결** — `PORT_ADDED` / `PORT_REMOVED` 이벤트. 장치가 다시 연결되면 포트가 저절로 다시 열립니다 (시리얼번호가 있는 장치는 COM 번호가 바뀌어도).
- **장치 제거를 막지 않음** — 장치 관리자 "사용 안 함", "하드웨어 안전하게 제거" 요청을 받으면 포트를 스스로 닫습니다. 케이블 분리는 1초 안에 감지합니다.
- **여러 포트 동시 사용** — 포트마다 독립된 입출력 스레드.
- **패킷 분리 도우미** — 줄/구분자, 고정 길이, 시작바이트+길이(체크섬 검증: XOR, SUM, CRC-16 Modbus, CRC-16 CCITT), 객체 할당 없는 고속 모드.
- **빠름** — 왕복 지연 0.05 ms, 가상 포트 쌍에서 250 MB/s 이상, 송신 중에도 화면이 멈추지 않음.
- **ANE 하나로 전부** — AIR 32 ~ AIR 51, 32비트·64비트 앱. 추가 DLL 이나 VC++ 재배포 패키지가 필요 없습니다.

## 요구 사항

| | |
|---|---|
| OS | Windows 10 / 11, 32비트·64비트 앱 |
| 런타임 | Adobe AIR 32 이상 (AIR 32.0, HARMAN AIR 51.2 에서 검증) |
| 도구 | Adobe Animate 또는 AS3 개발 환경 (Flash Builder, IntelliJ IDEA, VS Code + AIR SDK, 명령줄 `amxmlc`/`adt`) |
| 앱 프로필 | `extendedDesktop` (네이티브 익스텐션 필수 조건) |

## 다운로드

[최신 릴리스](https://github.com/RJOFX/AirSerial/releases/latest)에서 **`AirSerial.ane`** 를 받으세요.

| 파일 | 설명 |
|---|---|
| `AirSerial.ane` | 익스텐션 본체. 프로젝트에 추가하면 앱과 함께 패키징됩니다. |
| `AirSerial.swc` | 선택. ANE 를 읽지 못하는 IDE 의 코드 힌트용. ANE 와 같은 버전이어야 합니다. |

최신 버전 바로 받기: [AirSerial.ane](https://github.com/RJOFX/AirSerial/releases/latest/download/AirSerial.ane) · [AirSerial.swc](https://github.com/RJOFX/AirSerial/releases/latest/download/AirSerial.swc)

## 설치

### Adobe Animate

1. **파일 › ActionScript 설정 › 라이브러리 경로** → **+ (네이티브 익스텐션 추가)** → `AirSerial.ane` 선택
2. AIR 앱 설명 파일(`앱이름-app.xml`)에 익스텐션이 들어 있는지 확인 (보통 Animate 가 자동으로 넣어줌):
   ```xml
   <extensions>
       <extensionID>com.airserial.SerialANE</extensionID>
   </extensions>
   ```
3. **컨트롤 › 테스트 (Ctrl+Enter)**. 출력 창에 `[SWF] com.airserial.SerialANE ...` 가 보이면 정상입니다.
4. **게시** (파일 › 게시 설정 › AIR 설정): 설치 프로그램 또는 캡티브 런타임(`.exe`)과 서명 인증서를 지정합니다 (같은 화면에서 자체 서명 인증서를 만들 수 있음). ANE 는 자동으로 포함됩니다.

> **앱 파일 이름(`<filename>`)에 괄호를 넣지 마세요** (예: `my (test) app`). AIR 패키저(ADT)가 `Unmatched closing ')'` 오류로 실패합니다. 표시 이름(`<name>`)은 상관없습니다.

### 명령줄 / 다른 IDE

```bat
:: 컴파일: ANE 를 외부 라이브러리로 연결
amxmlc -external-library-path+=AirSerial.ane -output MyApp.swf MyApp.as

:: ADL 로 테스트: ANE 를 AirSerial.ane 라는 이름의 폴더에 풀어서 사용
mkdir ext\AirSerial.ane
tar -xf AirSerial.ane -C ext\AirSerial.ane
adl -profile extendedDesktop -extdir ext MyApp-app.xml .

:: 패키징: -extdir 에 AirSerial.ane 파일이 들어 있는 폴더를 지정
adt -package -storetype pkcs12 -keystore cert.p12 -target bundle MyApp MyApp-app.xml MyApp.swf -extdir anes
:: 64비트 앱 (AIR 33 이상):  -target bundle 뒤에  -arch x64  추가
```

앱 설명 파일에는 `<supportedProfiles>extendedDesktop desktop</supportedProfiles>` (또는 `supportedProfiles` 생략)와 위의 `<extensions>` 항목이 필요합니다.

## 빠른 시작

```actionscript
import com.airserial.*;
import flash.events.*;

var port:SerialPort = new SerialPort();
port.addEventListener(Event.CONNECT, function (e:Event):void { trace("열림:", port.portName); });
port.addEventListener(ProgressEvent.SOCKET_DATA, onData);
port.addEventListener(Event.CLOSE, function (e:Event):void { trace("끊김:", port.lastError); });

if (!port.open("COM3", 115200)) trace("열기 실패:", port.lastError);

function onData(e:ProgressEvent):void {
    trace(port.readUTFBytes(port.bytesAvailable));
}

port.writeUTFBytes("hello\n");
port.flush();                 // Socket 과 동일: flush() 해야 전송됨
port.send("hello\n");         // 쓰기 + flush 한 번에 (String, ByteArray, [바이트 배열])
```

다 쓰면 `port.close()` 로 닫으세요 (예: 창의 `Event.CLOSING` 에서).

## 포트 찾기

```actionscript
for each (var p:SerialPortInfo in Serial.listPorts())
    trace(p.port, p.displayName, p.vendorIdHex, p.productIdHex, p.serialNumber);
// COM5  Arduino Uno (COM5)  2341  0043  85736323930351F07181

var arduinos:Vector.<SerialPortInfo> = Serial.findPorts(0x2341);      // USB 제조사 ID 로 찾기
var ftdi:Vector.<SerialPortInfo> = Serial.findPorts(0x0403, 0x6001);  // 제조사 + 제품 ID
```

## 회선 설정

```actionscript
// 데이터비트 7, 짝수 패리티, 스톱비트 2, 하드웨어 흐름제어
var o:SerialPortOptions = new SerialPortOptions(7, Parity.EVEN, 2, FlowControl.RTS_CTS);
o.dtr = true;          // 기본값 true. 아두이노 레오나르도/마이크로는 DTR 이 켜져 있어야 데이터를 보냄
port.open("COM3", 9600, o);
```

## 패킷 나누기 (framing)

프레이머는 포트로 들어오는 바이트를 모두 받아 완성된 패킷 단위로 넘겨줍니다. `SerialPort`(또는 `flash.net.Socket`)에 붙이거나 `push()` 로 직접 넣을 수 있습니다. 붙인 뒤에는 포트에서 직접 읽지 말고 프레이머만 사용하세요.

```actionscript
import com.airserial.framing.*;

// 한 줄 = 한 프레임 ("\n", 끝의 "\r" 은 자동 제거)
var lines:DelimiterFramer = new DelimiterFramer(port);
lines.addEventListener(FrameEvent.FRAME, function (e:FrameEvent):void { trace(e.text); });

// 고정 길이 레코드
var records:FixedLengthFramer = new FixedLengthFramer(port, 6);

// AA 55 | 길이(1바이트) | 데이터 | XOR 체크섬(1바이트)
var packets:LengthPrefixFramer = new LengthPrefixFramer(port, [0xAA, 0x55], 1, Endian.BIG_ENDIAN, 0, 1);
packets.validator = function (frame:ByteArray, offset:uint, length:uint):Boolean {
    return Checksum.xor8(frame, offset, length) == frame[offset + length];
};
packets.addEventListener(FrameEvent.FRAME, function (e:FrameEvent):void {
    var payload:ByteArray = e.payload;
});
```

초당 수천 패킷 이상이면 고속 모드를 쓰세요. 패킷마다 이벤트·ByteArray 를 만들지 않아 작은 패킷 기준 약 3배 빠릅니다.

```actionscript
packets.reuseFrame = true;    // 같은 ByteArray 를 재사용: 보관할 값은 복사할 것
packets.frameHandler = function (frame:ByteArray, payloadOffset:uint, payloadLength:uint):void {
    frame.position = payloadOffset;
    var value:int = frame.readShort();
};
```

## 뽑기 · 다시 꽂기

```actionscript
port.autoReconnect = true;    // 장치가 돌아오면 자동으로 다시 열기
port.addEventListener(SerialPortEvent.RECONNECTING, function (e:SerialPortEvent):void { trace("기다리는 중:", e.portName); });

Serial.addEventListener(SerialPortEvent.PORT_ADDED,   function (e:SerialPortEvent):void { trace("+", e.portName, e.info); });
Serial.addEventListener(SerialPortEvent.PORT_REMOVED, function (e:SerialPortEvent):void { trace("-", e.portName); });
```

AirSerial 은 장치 분리를 세 가지 방법(입출력 오류, Windows 제거 알림, 시스템 포트 목록에서 사라짐)으로 감지하므로, 제거된 포트를 오류 없이 붙잡고 있는 드라이버에서도 동작합니다. 보통 0.2–0.6 초 안에 감지하고, 장치가 돌아오면 약 0.3 초 뒤 다시 연결됩니다.

## 이벤트

| 대상 | 이벤트 | 시점 |
|---|---|---|
| `SerialPort` | `Event.CONNECT` | `open()` 성공 직후(다음 프레임), 자동 재연결 성공 시 |
| | `ProgressEvent.SOCKET_DATA` | 새 데이터 도착 (`bytesLoaded` = 바이트 수) |
| | `Event.CLOSE` | 장치를 잃음 (분리, 사용 안 함, 드라이버 오류). 이유는 `lastError`. `close()` 로 닫을 때는 발생 안 함 |
| | `IOErrorEvent.IO_ERROR` | `open()` 실패 — 리스너를 등록했을 때만. `open()` 도 `false` 를 반환 |
| | `SerialPortEvent.RECONNECTING` | `autoReconnect` 가 장치를 기다리기 시작 |
| | `SerialPortEvent.BUFFER_OVERFLOW` | 수신 버퍼(기본 4 MB)가 가득 차 오래된 바이트를 버림 |
| `Serial` (static) | `SerialPortEvent.PORT_ADDED` / `PORT_REMOVED` | COM 포트가 생김 / 사라짐 |

## 진단

```actionscript
trace(Serial.VERSION, Serial.nativeVersion);   // 1.0.0  1.0.0 (Windows x64)
trace(port.stats);   // [SerialPortStats rx=20971520 tx=0 reads=320 events=155 dropped=0 buffered=0 pending=0 removalWatch=0]
```

`droppedBytes` 가 늘면 코드가 수신 속도를 따라가지 못하는 것입니다. 문제를 알려주실 때 위 두 줄의 출력을 함께 보내주세요.

## 문제 해결

| 증상 | 원인 / 해결 |
|---|---|
| `Serial.isSupported` 가 `false` / "native extension is not available" | ANE 가 프로젝트에 추가되지 않았거나, 앱 프로필이 `extendedDesktop` 이 아니거나, Windows 가 아님 |
| "Port is in use by another program" | 다른 프로그램을 닫으세요 (아두이노 IDE 시리얼 모니터, 터미널 프로그램, 앱의 다른 인스턴스) |
| "Port settings rejected by driver" | 장치·드라이버가 그 보레이트나 설정을 지원하지 않음. 메인보드 COM 포트는 보통 115200 까지 |
| 포트를 열면 아두이노가 재시작됨 | 대부분의 보드에서 정상 (DTR 리셋). 첫 메시지를 기다리거나 `options.dtr = false` |
| 아두이노 레오나르도 / 마이크로가 아무것도 안 보냄 | `dtr = true` 유지 (기본값) |
| "library x is used with native y" 경고 | SWC 와 ANE 의 릴리스가 다름. 같은 릴리스의 파일을 사용 |
| 게시 시 `Unmatched closing ')'` | 앱 `<filename>` 에서 괄호 제거 |
| 가상 포트(com0com, VSPE)를 장치 관리자에서 끄면 재부팅을 요구 | 해당 드라이버가 제거 알림을 지원하지 않음. 먼저 포트를 닫으세요. 실제 USB 장치는 문제 없음 |

## 피드백

버그, 질문, 기능 요청은 [Issues](https://github.com/RJOFX/AirSerial/issues) 에 남겨주세요. Windows 버전, AIR SDK 버전, `Serial.VERSION` / `Serial.nativeVersion`, 사용한 장치나 USB 어댑터, 문제를 보여주는 짧은 코드를 함께 적어주시면 빠르게 확인할 수 있습니다.

## 버전

[유의적 버전(Semantic Versioning)](https://semver.org/lang/ko/) `MAJOR.MINOR.PATCH` 를 따릅니다. 릴리스마다 [변경 이력](CHANGELOG.md)에 내용을 기록하고, 버전은 ANE 정보, DLL 파일 속성, `Serial.VERSION` 에 똑같이 들어갑니다.

## 라이선스

AirSerial 은 **개인·교육·비상업적 용도로 무료**입니다. 상업적 사용은 별도 라이선스가 필요합니다 — *Commercial license* 라는 제목으로 이슈를 남겨주세요. 전체 조건은 [LICENSE](LICENSE) 를 참고하세요.

© 2026 RJOFX
