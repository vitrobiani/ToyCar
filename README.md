# Monster Truck BLE Controller

A Flutter-controlled monster truck using an ESP32 over Bluetooth Low Energy (BLE).

---

## Hardware

- ESP32 dev board
- L293D motor driver chip
- 2x DC motors (drive + steering)
- 4.8V NiCd battery
- Switch on the power line

### Wiring

```
Battery + → Switch → ESP32 5V pin → L293D Pin 16 (logic power)
Battery +                         → L293D Pin 8  (motor power)
Battery - → ESP32 GND             → L293D GND pins (4, 5, 12, 13)
```

Motor control pins (ESP32 → L293D):
| Signal | ESP32 Pin |
|--------|-----------|
| IN1    | 18        |
| IN2    | 19        |
| EN1    | 16        |
| IN3    | 5         |
| IN4    | 4         |
| EN2    | 17        |

---

## ESP32 Firmware

Uses the **Nordic UART Service (NUS)** BLE profile for serial-like communication.

| UUID | Role |
|------|------|
| `6E400001-...` | Service |
| `6E400002-...` | RX - receives commands from Flutter |
| `6E400003-...` | TX - sends data to Flutter (not really used but nice to have) |

### Supported commands

| Command      | Action                  |
|--------------|-------------------------|
| `FORWARD`    | Drive forward           |
| `BACKWARD`   | Drive backward          |
| `LEFT`       | Steer left              |
| `RIGHT`      | Steer right             |
| `DRIVE_LEFT` | Drive forward + steer left  |
| `DRIVE_RIGHT`| Drive forward + steer right |
| `STOP`       | Stop all motors         |

The ESP32 restarts BLE advertising automatically after a disconnect.

---

## Flutter App

Built with `flutter_blue_plus`. The app:

1. Requests `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and `LOCATION` permissions at runtime
2. Scans for the ESP32 by MAC address (`F4:2D:C9:6D:92:62`)
3. Connects and discovers the service
4. Sends commands via the RX characteristic 
5. Listens for responses via notifications on the TX characteristic

### Key files

- `BleService.dart`: handles scan, connect, send, and receive
- `main.dart`: joystick UI that sends commands to `BleService`

### Android permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
```

---

## Dependencies

```yaml
dependencies:
  flutter_blue_plus: ^1.32.0
  flutter_joystick: ^0.2.2
```
