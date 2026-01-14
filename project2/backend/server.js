const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const redis = require('redis');
const { createAdapter } = require('@socket.io/redis-adapter');
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const cors = require('cors');

const app = express();
const server = http.createServer(app);

// CORS 설정
app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:8080",
  credentials: true
}));

// Redis 클라이언트 설정
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'redis-service',
    port: parseInt(process.env.REDIS_PORT) || 6379
  },
  password: process.env.REDIS_PASSWORD
});

const pubClient = redisClient.duplicate();
const subClient = redisClient.duplicate();

// Redis 에러 핸들러 추가
redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err);
});

pubClient.on('error', (err) => {
  console.error('Redis Pub Client Error:', err);
});

subClient.on('error', (err) => {
  console.error('Redis Sub Client Error:', err);
});

// Redis 연결
Promise.all([
  redisClient.connect(),
  pubClient.connect(),
  subClient.connect()
]).then(() => {
  console.log('Redis clients connected');
}).catch((err) => {
  console.error('Redis connection failed:', err);
});

// 세션 설정
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET || 'your-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 1000 * 60 * 60 * 24 // 24시간
  }
}));

// Socket.IO 설정
const io = socketIo(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:8080",
    methods: ["GET", "POST"],
    credentials: true
  },
  adapter: createAdapter(pubClient, subClient)
});

const port = process.env.PORT || 3000;

app.use(express.json());

// 채팅 관련 이벤트 처리
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // 사용자가 채팅방에 참여
  socket.on('join-room', (roomId, username) => {
    socket.join(roomId);
    socket.username = username;
    socket.roomId = roomId;
    
    // 다른 사용자들에게 참여 알림
    socket.to(roomId).emit('user-joined', {
      username: username,
      message: `${username}님이 채팅방에 참여했습니다.`,
      timestamp: new Date()
    });
    
    console.log(`${username} joined room: ${roomId}`);
  });

  // 메시지 전송
  socket.on('send-message', async (data) => {
    const messageData = {
      id: Date.now(),
      username: socket.username,
      message: data.message,
      roomId: socket.roomId,
      timestamp: new Date()
    };

    // Redis에 메시지 저장 (채팅 히스토리)
    try {
      await redisClient.lPush(`chat:${socket.roomId}`, JSON.stringify(messageData));
      await redisClient.lTrim(`chat:${socket.roomId}`, 0, 99); // 최근 100개 메시지만 유지
    } catch (error) {
      console.error('Redis save error:', error);
    }

    // 같은 방의 모든 사용자에게 메시지 전송
    io.to(socket.roomId).emit('receive-message', messageData);
  });

  // 채팅 히스토리 요청
  socket.on('get-history', async (roomId) => {
    try {
      const messages = await redisClient.lRange(`chat:${roomId}`, 0, -1);
      const parsedMessages = messages.reverse().map(msg => JSON.parse(msg));
      socket.emit('chat-history', parsedMessages);
    } catch (error) {
      console.error('Get history error:', error);
      socket.emit('chat-history', []);
    }
  });

  // 연결 해제
  socket.on('disconnect', () => {
    if (socket.username && socket.roomId) {
      socket.to(socket.roomId).emit('user-left', {
        username: socket.username,
        message: `${socket.username}님이 채팅방을 나갔습니다.`,
        timestamp: new Date()
      });
    }
    console.log('User disconnected:', socket.id);
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'WebSocket Chat Server Running', 
    timestamp: new Date(),
    version: process.env.APP_VERSION || '1.0.0',
    redis: redisClient.isReady ? 'connected' : 'disconnected'
  });
});

// 채팅방 목록 API
app.get('/api/rooms', async (req, res) => {
  try {
    const rooms = await redisClient.keys('chat:*');
    const roomList = rooms.map(room => room.replace('chat:', ''));
    res.json({ rooms: roomList });
  } catch (error) {
    res.status(500).json({ error: 'Failed to get rooms' });
  }
});

// Data endpoint
app.get('/api/data', (req, res) => {
  res.json({ 
    message: 'WebSocket Chat Backend',
    database: process.env.DB_HOST || 'Not connected',
    environment: process.env.NODE_ENV || 'development',
    redis: redisClient.isReady ? 'connected' : 'disconnected'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({ message: 'WebSocket Chat API is running' });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`WebSocket Chat Server running on port ${port}`);
});