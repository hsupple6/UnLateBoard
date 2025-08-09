const net = require('net');
const http = require('http');
const WebSocket = require('ws');
const express = require('express');
const cors = require('cors');

// Configuration
const ARDUINO_HOST = '192.168.4.1';        // Arduino bt_classic WiFi AP
const ARDUINO_PORT = 8080;                 // Arduino control server port
const BRIDGE_PORT = 3000;                  // Different port for bridge server

// Express app for HTTP endpoints
const app = express();
app.use(cors());
app.use(express.text());
app.use(express.json());

// Create HTTP server
const server = http.createServer(app);

// WebSocket server for real-time communication
const wss = new WebSocket.Server({ server });

// Arduino TCP connection
let arduinoSocket = null;
let isConnectedToArduino = false;
let webClients = new Set();

// Buffer for incoming data from Arduino
let arduinoBuffer = '';

// Logging function
function log(message, type = 'INFO') {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${type}] ${message}`);
}

// Connect to Arduino bt_classic
function connectToArduino() {
    log('Attempting to connect to Arduino bt_classic...');
    
    arduinoSocket = new net.Socket();
    
    arduinoSocket.connect(ARDUINO_PORT, ARDUINO_HOST, () => {
        log('✅ Connected to Arduino bt_classic successfully!');
        isConnectedToArduino = true;
        broadcastToClients('ARDUINO_STATUS', 'Connected to Arduino bt_classic');
        
        // Send initial handshake (Arduino doesn't need this, but ESP32 part might)
        // arduinoSocket.write('HELLO\n');
    });
    
    arduinoSocket.on('data', (data) => {
        arduinoBuffer += data.toString();
        
        // Process complete lines
        while (arduinoBuffer.includes('\n')) {
            const lineEnd = arduinoBuffer.indexOf('\n');
            const line = arduinoBuffer.substring(0, lineEnd).trim();
            arduinoBuffer = arduinoBuffer.substring(lineEnd + 1);
            
            if (line.length > 0) {
                log(`📥 Arduino: ${line}`);
                broadcastToClients('ARDUINO_RESPONSE', line);
            }
        }
    });
    
    arduinoSocket.on('close', () => {
        log('❌ Arduino bt_classic connection closed');
        isConnectedToArduino = false;
        broadcastToClients('ARDUINO_STATUS', 'Disconnected from Arduino bt_classic');
        
        // Reconnect after 3 seconds
        setTimeout(connectToArduino, 3000);
    });
    
    arduinoSocket.on('error', (err) => {
        log(`❌ Arduino bt_classic connection error: ${err.message}`, 'ERROR');
        isConnectedToArduino = false;
        broadcastToClients('ARDUINO_STATUS', `Connection error: ${err.message}`);
        
        // Reconnect after 5 seconds
        setTimeout(connectToArduino, 5000);
    });
}

// Send command to Arduino
function sendToArduino(command) {
    if (!isConnectedToArduino || !arduinoSocket) {
        log(`❌ Cannot send command - not connected to Arduino: ${command}`, 'ERROR');
        return false;
    }
    
    try {
        const fullCommand = command.endsWith('\n') ? command : command + '\n';
        arduinoSocket.write(fullCommand);
        log(`📤 Sent to Arduino: ${command}`);
        return true;
    } catch (error) {
        log(`❌ Error sending to Arduino: ${error.message}`, 'ERROR');
        return false;
    }
}

// Broadcast message to all connected web clients
function broadcastToClients(type, data) {
    const message = JSON.stringify({ type, data, timestamp: Date.now() });
    
    webClients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
}

// WebSocket connection handler
wss.on('connection', (ws) => {
    log('🌐 Web client connected');
    webClients.add(ws);
    
    // Send current status
    ws.send(JSON.stringify({
        type: 'ARDUINO_STATUS',
        data: isConnectedToArduino ? 'Connected to Arduino bt_classic' : 'Disconnected from Arduino bt_classic',
        timestamp: Date.now()
    }));
    
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            
            if (data.type === 'COMMAND') {
                log(`🌐 Web command: ${data.command}`);
                if (sendToArduino(data.command)) {
                    ws.send(JSON.stringify({
                        type: 'COMMAND_SENT',
                        data: data.command,
                        timestamp: Date.now()
                    }));
                } else {
                    ws.send(JSON.stringify({
                        type: 'COMMAND_FAILED',
                        data: `Failed to send: ${data.command}`,
                        timestamp: Date.now()
                    }));
                }
            }
        } catch (error) {
            log(`❌ Invalid WebSocket message: ${error.message}`, 'ERROR');
        }
    });
    
    ws.on('close', () => {
        log('🌐 Web client disconnected');
        webClients.delete(ws);
    });
    
    ws.on('error', (error) => {
        log(`🌐 WebSocket error: ${error.message}`, 'ERROR');
        webClients.delete(ws);
    });
});

// HTTP endpoints
app.get('/', (req, res) => {
    res.json({
        status: 'Arduino bt_classic Bridge Server',
        arduinoConnected: isConnectedToArduino,
        connectedClients: webClients.size,
        endpoints: {
            '/status': 'GET - Server status',
            '/command': 'POST - Send command to Arduino',
            '/ws': 'WebSocket - Real-time communication'
        }
    });
});

app.get('/status', (req, res) => {
    res.json({
        arduinoConnected: isConnectedToArduino,
        arduinoHost: ARDUINO_HOST,
        arduinoPort: ARDUINO_PORT,
        connectedClients: webClients.size,
        uptime: process.uptime()
    });
});

app.post('/command', (req, res) => {
    const command = req.body;
    
    if (!command) {
        return res.status(400).json({ error: 'No command provided' });
    }
    
    log(`🌐 HTTP command: ${command}`);
    
    if (sendToArduino(command)) {
        res.json({ 
            success: true, 
            command: command,
            timestamp: Date.now()
        });
    } else {
        res.status(500).json({ 
            success: false, 
            error: 'Failed to send command to Arduino',
            command: command
        });
    }
});

// CORS preflight
app.options('*', cors());

// Start the bridge server
server.listen(BRIDGE_PORT, () => {
    log(`🚀 Arduino bt_classic Bridge Server started on port ${BRIDGE_PORT}`);
    log(`📡 Will connect to Arduino bt_classic at ${ARDUINO_HOST}:${ARDUINO_PORT}`);
    log(`🌐 WebSocket endpoint: ws://localhost:${BRIDGE_PORT}`);
    log(`🔗 HTTP endpoint: http://localhost:${BRIDGE_PORT}`);
    
    // Connect to Arduino bt_classic
    connectToArduino();
});

// Graceful shutdown
process.on('SIGINT', () => {
    log('📴 Shutting down bridge server...');
    
    if (arduinoSocket) {
        arduinoSocket.destroy();
    }
    
    webClients.forEach(client => {
        client.close();
    });
    
    server.close(() => {
        log('✅ Bridge server shut down gracefully');
        process.exit(0);
    });
});

// Keep alive ping to Arduino
setInterval(() => {
    if (isConnectedToArduino) {
        sendToArduino('PING');
    }
}, 30000); // Every 30 seconds

log('🔧 Arduino bt_classic Bridge Server initializing...'); 