# UnLateBoard - Smart Electric Skateboard App

A comprehensive iOS app for controlling and monitoring a smart electric skateboard with ML-powered object detection.

## 🚀 Features

- **Real-time Motor Control**: Precise speed and acceleration control
- **ML Object Detection**: YOLOv5-based real-time object detection
- **Connection Management**: Robust TCP connection with auto-reconnect
- **Trip Tracking**: Distance, time, and performance metrics
- **Safety Features**: Emergency stop, brake control, and speed limits
- **Modern UI**: Dark theme with smooth animations

## 🏗️ Architecture

The app has been completely restructured with a clean, modular architecture:

### Core Components

- **AppStateManager**: Central app state and navigation management
- **ConnectionManager**: Robust TCP connection handling with heartbeat and reconnection
- **MotorManagement**: Motor control and trip statistics
- **MLProcessor**: YOLOv5 object detection with real-time streaming
- **AppConfig**: Centralized configuration management

### Key Improvements

1. **Eliminated Crashes**: Fixed race conditions, memory leaks, and thread safety issues
2. **Better Error Handling**: Comprehensive error handling with user-friendly messages
3. **Centralized Configuration**: All hardcoded values moved to AppConfig
4. **Proper Logging**: Structured logging with different levels
5. **Clean Architecture**: Separation of concerns and dependency injection
6. **Thread Safety**: Proper use of DispatchQueue and locks

## 📱 Screens

- **Intro**: Welcome screen with app branding
- **Login/Signup**: User authentication
- **Main**: Dashboard with navigation to different features
- **Control Panel**: Motor control interface
- **ML Vision**: Real-time object detection
- **Settings**: App configuration

## 🔧 Configuration

All configuration is centralized in `AppConfig.swift`:

```swift
// Network settings
AppConfig.Network.defaultHost = "192.168.4.1"
AppConfig.Network.defaultPort = 3333

// ML settings
AppConfig.ML.confidenceThreshold = 0.3
AppConfig.ML.modelInputSize = CGSize(width: 416, height: 416)

// Motor settings
AppConfig.Motor.defaultMaxSpeed = 25.0 // m/s
AppConfig.Motor.defaultMaxAcceleration = 10.0 // m/s²
```

## 🚨 Safety Features

- **Emergency Stop**: Immediate halt with increased braking force
- **Speed Limits**: Configurable maximum speed with warnings
- **Brake Control**: Adjustable braking intensity
- **Connection Monitoring**: Automatic reconnection on connection loss

## 📊 Performance Tracking

- **Trip Statistics**: Distance, time, average speed
- **Real-time Metrics**: Current speed, acceleration, heading
- **Connection Quality**: Network performance monitoring
- **ML Performance**: FPS and detection accuracy

## 🔌 Connection Protocol

The app communicates with the ESP32 using a custom TCP protocol:

### Commands
- `MOTOR:speed=<value>`: Set motor speed
- `MOTOR:direction=<value>`: Set direction
- `MOTOR:maxVelo=<value>`: Set maximum velocity
- `MOTOR:maxAccel=<value>`: Set maximum acceleration
- `STATUS`: Request device status
- `PING`: Heartbeat ping

### Responses
- `STATUS:<status>`: Device status response
- `MOTOR:<data>`: Motor data updates
- `ERROR:<message>`: Error messages
- `PONG`: Heartbeat response

## 🧠 ML Integration

The app uses YOLOv5 for real-time object detection:

- **Model**: yolov5l.mlmodel (45MB)
- **Input Size**: 416x416 pixels
- **Confidence Threshold**: 30%
- **Frame Rate**: Up to 60 FPS
- **Detection Types**: 80 COCO classes

## 🛠️ Development

### Requirements
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

### Dependencies
- GoogleMaps (via CocoaPods)
- Vision framework (built-in)
- CoreML framework (built-in)

### Building
1. Clone the repository
2. Run `pod install` to install dependencies
3. Open `UnLateBoard.xcworkspace`
4. Build and run

## 🐛 Bug Fixes

### Major Issues Resolved

1. **ML Crashes**: Fixed race conditions in frame processing
2. **Connection Drops**: Implemented robust reconnection logic
3. **Memory Leaks**: Proper cleanup in deinit methods
4. **Thread Safety**: Used proper dispatch queues and locks
5. **State Management**: Centralized app state management
6. **Error Handling**: Comprehensive error handling throughout

### Performance Improvements

1. **Frame Processing**: Optimized ML pipeline
2. **Connection**: Reduced latency with keepalive
3. **UI**: Smooth animations and transitions
4. **Memory**: Reduced memory footprint

## 📝 Logging

The app includes comprehensive logging:

```swift
Logger.shared.debug("Debug message")
Logger.shared.info("Info message")
Logger.shared.warning("Warning message")
Logger.shared.error("Error message")
Logger.shared.fatal("Fatal error")
```

Log levels are configurable per environment (development/production).

## 🔒 Security

- API keys stored in configuration
- User authentication with UserDefaults
- Secure TCP connections
- Input validation throughout

## 📈 Future Enhancements

- [ ] Bluetooth connectivity
- [ ] GPS navigation
- [ ] Cloud data sync
- [ ] Advanced ML models
- [ ] Social features
- [ ] Performance analytics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support, email support@unlateboard.com or create an issue in the repository.

---

**Note**: This app is designed for educational and development purposes. Always follow local laws and safety regulations when using electric skateboards. 