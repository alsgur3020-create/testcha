const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'Backend Pod Running', 
    timestamp: new Date(),
    version: process.env.APP_VERSION || '1.0.0'
  });
});

// Data endpoint
app.get('/api/data', (req, res) => {
  res.json({ 
    message: 'Data from backend',
    database: process.env.DB_HOST || 'Not connected',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({ message: 'Backend API is running' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Backend running on port ${port}`);
});