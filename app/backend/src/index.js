const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8080;
const VERSION = process.env.VERSION || '1.0.0';

// Middleware
app.use(cors());
app.use(express.json());

// In-memory data store (no database for MVP)
let items = [
  { id: 1, name: 'Sample Item 1', description: 'This is a sample item' },
  { id: 2, name: 'Sample Item 2', description: 'Another sample item' }
];
let nextId = 3;

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Readiness check endpoint
app.get('/ready', (req, res) => {
  res.json({
    status: 'ready',
    timestamp: new Date().toISOString()
  });
});

// Version/build information endpoint
app.get('/version', (req, res) => {
  res.json({
    version: VERSION,
    buildTime: process.env.BUILD_TIME || new Date().toISOString(),
    commitSha: process.env.COMMIT_SHA || 'dev',
    environment: process.env.ENVIRONMENT || 'local'
  });
});

// Get all items
app.get('/api/items', (req, res) => {
  res.json({
    success: true,
    data: items,
    count: items.length
  });
});

// Get item by ID
app.get('/api/items/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const item = items.find(i => i.id === id);
  
  if (!item) {
    return res.status(404).json({
      success: false,
      error: 'Item not found'
    });
  }
  
  res.json({
    success: true,
    data: item
  });
});

// Create new item
app.post('/api/items', (req, res) => {
  const { name, description } = req.body;
  
  if (!name) {
    return res.status(400).json({
      success: false,
      error: 'Name is required'
    });
  }
  
  const newItem = {
    id: nextId++,
    name,
    description: description || ''
  };
  
  items.push(newItem);
  
  res.status(201).json({
    success: true,
    data: newItem
  });
});

// Update item
app.put('/api/items/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const itemIndex = items.findIndex(i => i.id === id);
  
  if (itemIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'Item not found'
    });
  }
  
  const { name, description } = req.body;
  
  if (name !== undefined) items[itemIndex].name = name;
  if (description !== undefined) items[itemIndex].description = description;
  
  res.json({
    success: true,
    data: items[itemIndex]
  });
});

// Delete item
app.delete('/api/items/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const itemIndex = items.findIndex(i => i.id === id);
  
  if (itemIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'Item not found'
    });
  }
  
  items.splice(itemIndex, 1);
  
  res.json({
    success: true,
    message: 'Item deleted'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`Backend API server running on port ${PORT}`);
  console.log(`Version: ${VERSION}`);
  console.log(`Environment: ${process.env.ENVIRONMENT || 'local'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

module.exports = app;
