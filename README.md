# ESP32-CAM Motor Control Web Interface

A complete solution for controlling ESP32-CAM motors through a web browser using a Node.js bridge server.

## 🚀 Quick Start

### Prerequisites
- Node.js installed on your computer
- ESP32-CAM running the motor control firmware
- Connected to ESP32-CAM WiFi network

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
   🚀 ESP32-CAM Bridge Server started on port 8080
   📡 Will connect to ESP32-CAM at 192.168.4.1:3333
   ✅ Connected to ESP32-CAM successfully!
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
- **Live Status**: See actual ESP32-CAM responses
- **Command Logging**: Track all sent commands and responses
- **Connection Status**: Monitor bridge and ESP32 connectivity
- **Automatic Reconnection**: Bridge server reconnects to ESP32-CAM automatically

### Keyboard Controls
- **Arrow Keys**: Directional control
- **Spacebar**: Emergency stop

## 🔧 How It Works

```
Web Browser → Bridge Server → ESP32-CAM → Arduino (Motors)
     ↑              ↑              ↑           ↑
  WebSocket      TCP Socket    UART Serial   PWM Signals
```

1. **Web Browser** sends commands via WebSocket to bridge server
2. **Bridge Server** forwards commands via TCP to ESP32-CAM  
3. **ESP32-CAM** relays commands via UART to Arduino
4. **Arduino** controls motors via PWM signals

## 📡 Commands Supported

- `X -50 Y 25` - Joystick control (steering + throttle)
- `SPEED 5` - Set speed limit (0-30)
- `STATUS` - Get system status
- `PING` - Heartbeat/connectivity test
- `EMERGENCY_STOP` - Stop all motors immediately

## 🛠️ Configuration

### Bridge Server Settings
Edit `ESP32_Bridge_Server.js`:
```javascript
const ESP32_HOST = '192.168.4.1';  // ESP32-CAM IP
const ESP32_PORT = 3333;           // ESP32-CAM TCP port
const BRIDGE_PORT = 8080;          // Bridge server port
```

### Web App Settings
Default bridge address: `localhost:8080`
(Can be changed in the web interface)

## 📊 Monitoring

### Bridge Server Logs
```bash
[2024-01-15T10:30:45.123Z] [INFO] ✅ Connected to ESP32-CAM successfully!
[2024-01-15T10:30:50.456Z] [INFO] 🌐 Web client connected
[2024-01-15T10:30:55.789Z] [INFO] 📤 Sent to ESP32: X 0 Y 25
[2024-01-15T10:30:56.012Z] [INFO] 📥 ESP32: Status: driving, Streaming: ON...
```

### ESP32-CAM Serial Monitor
You should see:
```
WiFi client connected! Start sending frames.
[123456ms] [SERIAL] Received: 'X 0 Y 25'
[123456ms] [JOYSTICK] Raw X=0.00, Y=25.00 -> Throttle=10.00%, Steering=0.00°
```

## 🚨 Troubleshooting

### Bridge Server Won't Connect to ESP32-CAM
- Check ESP32-CAM is powered and running
- Verify you're connected to ESP32-CAM WiFi network
- Check IP address (default: 192.168.4.1)
- Look for "TCP Server started" in ESP32-CAM serial output

### Web App Won't Connect to Bridge
- Make sure bridge server is running (`npm start`)
- Check bridge address (default: localhost:8080)
- Try refreshing the web page
- Check browser console for errors

### Commands Not Working
- Verify ESP32-CAM shows "UART: ..." responses
- Check Arduino serial monitor for command reception
- Test with direct iOS app connection first

## 📁 Files

- `ESP32_Bridge_Server.js` - Node.js bridge server
- `ESP32_Motor_Control.html` - Web interface
- `package.json` - Node.js dependencies
- `README.md` - This file

## 🔒 Security Note

This setup is intended for local development and testing. For production use:
- Add authentication to the bridge server
- Use HTTPS/WSS connections
- Implement rate limiting
- Add input validation

## 📱 Alternative Control Methods

- **UnLateBoard iOS App** - Native TCP connection
- **Desktop Applications** - Direct TCP socket access
- **Serial Terminal** - Direct Arduino UART connection
- **Custom Scripts** - Python/Node.js with socket libraries

---

**Happy motor controlling!** 🚗💨

## ✅ Fixed the Command Issue!

The problem was that the web app was sending `MOTOR1` and `MOTOR2` commands, but your Arduino only understands:

- ✅ `X [steering] Y [throttle]` (joystick style)
- ✅ `STATUS` (status request)  
- ✅ `PING` (heartbeat)
- ✅ `SPEED [value]` (speed limit)

### **🔧 What I Fixed:**

1. **Individual Motor Controls** now convert to `X Y` format:
   - Motor1=25%, Motor2=75% → `X 100 Y 50` (steering right, medium throttle)
   - Motor1=50%, Motor2=50% → `X 0 Y 50` (straight, medium throttle)

2. **Emergency Stop** now sends `X 0 Y 0` instead of `EMERGENCY_STOP`

3. **Combined Controls** were already correct (using `sendCombined()`)

### **🧪 Test It Now:**

1. **Make sure your bridge server is running**:
   ```bash
   npm start
   ```

2. **Try the individual motor sliders** - you should now see:
   ```
   ESP32-CAM logs: [123ms] [SERIAL] Received: 'X 0 Y 25'
   Arduino logs: [123ms] [JOYSTICK] Raw X=0.00, Y=25.00 -> Throttle=10.00%, Steering=0.00°
   ```

3. **Try the joystick and arrow keys** - these should work immediately

Now your motor commands should actually reach the Arduino and control the motors! 🚗💨
