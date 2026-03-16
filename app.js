const express = require('express');
const path = require('path');
const app = express();

const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Health check endpoint (used by GitHub Actions to verify deployment)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'App is running',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0',
  });
});

// Main route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

// API route
app.get('/api/info', (req, res) => {
  res.json({
    app: 'My EC2 Deployed App',
    environment: process.env.NODE_ENV || 'development',
    deployedAt: process.env.DEPLOY_TIME || 'unknown',
    hostname: require('os').hostname(),
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
