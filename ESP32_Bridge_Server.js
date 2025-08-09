const net = require('net');
const http = require('http');
const WebSocket = require('ws');
const express = require('express');
const cors = require('cors');

// Configuration
const ESP32_HOST = '192.168.4.1';
const ESP32_PORT = 3333;
const BRIDGE_PORT = 8080;

// Express app for HTTP endpoints
const app = express();
app.use(cors());
app.use(express.text());
app.use(express.json());

// Create HTTP server
const server = http.createServer(app);

// WebSocket server for real-time communication
const wss = new WebSocket.Server({ server });

// ESP32 TCP connection
let esp32Socket = null;
let isConnectedToESP32 = false;
let webClients = new Set();

// Buffer for incoming data from ESP32
let esp32Buffer = '';

// Logging function
function log(message, type = 'INFO') {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${type}] ${message}`);
}

// Connect to ESP32-CAM
function connectToESP32() {
    log('Attempting to connect to ESP32-CAM...');
    
    esp32Socket = new net.Socket();
    
    esp32Socket.connect(ESP32_PORT, ESP32_HOST, () => {
        log('✅ Connected to ESP32-CAM successfully!');
        isConnectedToESP32 = true;
        broadcastToClients('ESP32_STATUS', 'Connected to ESP32-CAM');
        
        // Send initial handshake
        esp32Socket.write('HELLO\n');
    });
    
    esp32Socket.on('data', (data) => {
        esp32Buffer += data.toString();
        
        // Process complete lines
        while (esp32Buffer.includes('\n')) {
            const lineEnd = esp32Buffer.indexOf('\n');
            const line = esp32Buffer.substring(0, lineEnd).trim();
            esp32Buffer = esp32Buffer.substring(lineEnd + 1);
            
            if (line.length > 0) {
                log(`📥 ESP32: ${line}`);
                broadcastToClients('ESP32_RESPONSE', line);
            }
        }
    });
    
    esp32Socket.on('close', () => {
        log('❌ ESP32-CAM connection closed');
        isConnectedToESP32 = false;
        broadcastToClients('ESP32_STATUS', 'Disconnected from ESP32-CAM');
        
        // Reconnect after 3 seconds
        setTimeout(connectToESP32, 3000);
    });
    
    esp32Socket.on('error', (err) => {
        log(`❌ ESP32-CAM connection error: ${err.message}`, 'ERROR');
        isConnectedToESP32 = false;
        broadcastToClients('ESP32_STATUS', `Connection error: ${err.message}`);
        
        // Reconnect after 5 seconds
        setTimeout(connectToESP32, 5000);
    });
}

// Send command to ESP32
function sendToESP32(command) {
    if (!isConnectedToESP32 || !esp32Socket) {
        log(`❌ Cannot send command - not connected to ESP32: ${command}`, 'ERROR');
        return false;
    }
    
    try {
        const fullCommand = command.endsWith('\n') ? command : command + '\n';
        esp32Socket.write(fullCommand);
        log(`📤 Sent to ESP32: ${command}`);
        return true;
    } catch (error) {
        log(`❌ Error sending to ESP32: ${error.message}`, 'ERROR');
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
        type: 'ESP32_STATUS',
        data: isConnectedToESP32 ? 'Connected to ESP32-CAM' : 'Disconnected from ESP32-CAM',
        timestamp: Date.now()
    }));
    
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            
            if (data.type === 'COMMAND') {
                log(`🌐 Web command: ${data.command}`);
                if (sendToESP32(data.command)) {
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
        status: 'ESP32-CAM Bridge Server',
        esp32Connected: isConnectedToESP32,
        connectedClients: webClients.size,
        endpoints: {
            '/status': 'GET - Server status',
            '/command': 'POST - Send command to ESP32',
            '/ws': 'WebSocket - Real-time communication'
        }
    });
});

app.get('/status', (req, res) => {
    res.json({
        esp32Connected: isConnectedToESP32,
        esp32Host: ESP32_HOST,
        esp32Port: ESP32_PORT,
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
    
    if (sendToESP32(command)) {
        res.json({ 
            success: true, 
            command: command,
            timestamp: Date.now()
        });
    } else {
        res.status(500).json({ 
            success: false, 
            error: 'Failed to send command to ESP32',
            command: command
        });
    }
});

// CORS preflight
app.options('*', cors());

// Start the bridge server
server.listen(BRIDGE_PORT, () => {
    log(`🚀 ESP32-CAM Bridge Server started on port ${BRIDGE_PORT}`);
    log(`📡 Will connect to ESP32-CAM at ${ESP32_HOST}:${ESP32_PORT}`);
    log(`🌐 WebSocket endpoint: ws://localhost:${BRIDGE_PORT}`);
    log(`🔗 HTTP endpoint: http://localhost:${BRIDGE_PORT}`);
    
    // Connect to ESP32-CAM
    connectToESP32();
});

// Graceful shutdown
process.on('SIGINT', () => {
    log('📴 Shutting down bridge server...');
    
    if (esp32Socket) {
        esp32Socket.destroy();
    }
    
    webClients.forEach(client => {
        client.close();
    });
    
    server.close(() => {
        log('✅ Bridge server shut down gracefully');
        process.exit(0);
    });
});

// Keep alive ping to ESP32
setInterval(() => {
    if (isConnectedToESP32) {
        sendToESP32('PING');
    }
}, 30000); // Every 30 seconds

log('🔧 ESP32-CAM Bridge Server initializing...'); 