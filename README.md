# UnLateBoard Motor Control System

A complete dual-controller solution for the UnLateBoard project using Arduino bt_classic for motor control and ESP32-CAM for camera streaming.

## 🏗️ Architecture

The system now uses a **dual-controller architecture** to eliminate DMA overflow issues and provide better performance:

```
[iOS App / Web Interface]
         │
    ┌────▼────┐     ┌─────────────┐
    │ Arduino │◄────┤ ESP32-CAM   │
    │bt_classic│     │ (Camera Only)│
    │(Control)│     └─────────────┘
    └─────────┘
```

### Controller Responsibilities

**🤖 Arduino bt_classic (Main Controller)**
- WiFi SoftAP: `UnLateBoard-Control` / Password: `12345678`
- TCP Server: `192.168.4.1:8080`
- Motor control and steering
- Command processing from iOS/Web
- Status reporting and logging
- UART communication with ESP32-CAM

**📹 ESP32-CAM (Camera Only)**
- WiFi SoftAP: `ESP32-CAM` / Password: `12345678` 
- TCP Server: `192.168.4.1:3333`
- Camera capture and streaming only
- No motor control or command processing
- Minimal firmware to prevent DMA overflow

## 🚀 Quick Start

### Prerequisites
- Node.js installed on your computer
- Arduino bt_classic running the control firmware
- ESP32-CAM running the camera-only firmware
- Connected to UnLateBoard-Control WiFi network

### Setup

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Start the Bridge Server**
   ```bash
   npm start
   ```
   
   You should see:
   ```
   🚀 Arduino bt_classic Bridge Server started on port 3000
   📡 Will connect to Arduino bt_classic at 192.168.4.1:8080
   ✅ Connected to Arduino bt_classic successfully!
   ```

3. **Open the Web Interface**
   - Open `ESP32_Motor_Control.html` in your web browser
   - Click "Connect to Bridge"
   - Start controlling your motors!

## 🎮 Features

### Motor Controls
- **Individual Motor Control**: Separate sliders for left and right motors
- **Combined Control**: Virtual joystick for steering + throttle
- **Quick Actions**: Forward, reverse, left, right buttons
- **Emergency Stop**: Immediate stop all motors

### Real-time Features
- **Live Status**: See actual Arduino responses
- **Command Logging**: Track all sent commands and responses
- **Connection Status**: Monitor bridge and Arduino connectivity
- **Automatic Reconnection**: Bridge server reconnects to Arduino automatically

### Dual Connection Support
- **Control Connection**: Arduino bt_classic at `192.168.4.1:8080`
- **Camera Stream**: ESP32-CAM at `192.168.4.1:3333`
- **iOS App Support**: Connects directly to Arduino control server

### Keyboard Controls
- **Arrow Keys**: Directional control
- **Spacebar**: Emergency stop

## 🔧 How It Works

```
Web Browser → Bridge Server → Arduino bt_classic → ESP32-CAM
     ↑              ↑              ↑                  ↑
  WebSocket      TCP Socket    Motor Control     Camera Stream
```

1. **Web Browser** sends commands via WebSocket to bridge server
2. **Bridge Server** forwards commands via TCP to Arduino bt_classic
3. **Arduino bt_classic** processes commands and controls motors directly
4. **ESP32-CAM** handles camera streaming independently

## 📡 Commands Supported

- `X -50 Y 25` - Joystick control (steering + throttle)
- `SPEED 5` - Set speed limit (0-30)
- `STATUS` - Get system status
- `PING` - Heartbeat/connectivity test
- `FL 1` - LED control (flash on/off)
- `ACC 2.5` - Set acceleration

## 🛠️ Configuration

### Bridge Server Settings
Edit `ESP32_Bridge_Server.js`:
```javascript
const ARDUINO_HOST = '192.168.4.1';  // Arduino bt_classic IP
const ARDUINO_PORT = 8080;           // Arduino control port
const BRIDGE_PORT = 3000;            // Bridge server port
```

### Web App Settings
Default bridge address: `localhost:3000`
(Can be changed in the web interface)

## 📊 Monitoring

### Bridge Server Logs
```bash
[2024-01-15T10:30:45.123Z] [INFO] ✅ Connected to Arduino bt_classic successfully!
[2024-01-15T10:30:50.456Z] [INFO] 🌐 Web client connected
[2024-01-15T10:30:55.789Z] [INFO] 📤 Sent to Arduino: X 0 Y 25
[2024-01-15T10:30:56.012Z] [INFO] 📥 Arduino: OK: Status: driving, Streaming: ON...
```

### Arduino bt_classic Serial Monitor
You should see:
```
[123456ms] [WIFI_CMD] Received: 'X 0 Y 25'
[123456ms] [JOYSTICK] Raw X=0.00, Y=25.00 -> Throttle=10.00%, Steering=0.00°
[123456ms] [RESPONSE_WIFI] Status: driving, Streaming: ON, Last: X 0 Y 25, WiFi: CONNECTED
```

## 🚨 Troubleshooting

### Bridge Server Won't Connect to Arduino
- Check Arduino bt_classic is powered and running
- Verify you're connected to UnLateBoard-Control WiFi network
- Check IP address (default: 192.168.4.1:8080)
- Look for "TCP Server started" in Arduino serial output

### Web App Won't Connect to Bridge
- Make sure bridge server is running (`npm start`)
- Check bridge address (default: localhost:3000)
- Try refreshing the web page
- Check browser console for errors

### Commands Not Working
- Verify Arduino shows "WIFI_CMD: ..." messages
- Check Arduino serial monitor for command processing
- Test direct connection to Arduino at 192.168.4.1:8080

### Camera Stream Issues
- ESP32-CAM runs independently on 192.168.4.1:3333
- DMA overflow errors should be eliminated with camera-only firmware
- Connect separately to ESP32-CAM WiFi for camera access

## 📁 Files

- `ESP32_Bridge_Server.js` - Node.js bridge server
- `ESP32_Motor_Control.html` - Web interface
- `package.json` - Node.js dependencies
- `bt_classic_device_discovery.ino` - Arduino control firmware
- `CameraWebServer.ino` - ESP32-CAM camera-only firmware
- `README.md` - This file

## 🔒 Security Note

This setup is intended for local development and testing. For production use:
- Add authentication to the bridge server
- Use HTTPS/WSS connections
- Implement rate limiting
- Add input validation

## 📱 Alternative Control Methods

- **UnLateBoard iOS App** - Direct TCP connection to Arduino
- **Desktop Applications** - Direct TCP socket to Arduino at port 8080
- **Serial Terminal** - Direct Arduino UART connection
- **Custom Scripts** - Python/Node.js with socket libraries

---

**Happy motor controlling with your dual-controller UnLateBoard!** 🚗💨
