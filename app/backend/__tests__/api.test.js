const request = require('supertest');
const app = require('../src/index');

describe('Backend API Tests', () => {
  describe('Health Endpoints', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
    });

    it('should return ready status', async () => {
      const response = await request(app).get('/ready');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ready');
    });

    it('should return version information', async () => {
      const response = await request(app).get('/version');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('commitSha');
      expect(response.body).toHaveProperty('environment');
    });
  });

  describe('Items API', () => {
    it('should get all items', async () => {
      const response = await request(app).get('/api/items');
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body).toHaveProperty('count');
    });

    it('should create a new item', async () => {
      const newItem = {
        name: 'Test Item',
        description: 'Test description'
      };
      const response = await request(app)
        .post('/api/items')
        .send(newItem);
      
      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(newItem.name);
      expect(response.body.data).toHaveProperty('id');
    });

    it('should fail to create item without name', async () => {
      const response = await request(app)
        .post('/api/items')
        .send({ description: 'No name' });
      
      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should get item by id', async () => {
      const response = await request(app).get('/api/items/1');
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(1);
    });

    it('should return 404 for non-existent item', async () => {
      const response = await request(app).get('/api/items/9999');
      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });

    it('should update an item', async () => {
      const updates = {
        name: 'Updated Name',
        description: 'Updated description'
      };
      const response = await request(app)
        .put('/api/items/1')
        .send(updates);
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(updates.name);
    });

    it('should delete an item', async () => {
      // First create an item
      const createResponse = await request(app)
        .post('/api/items')
        .send({ name: 'To Delete' });
      
      const itemId = createResponse.body.data.id;
      
      // Then delete it
      const deleteResponse = await request(app)
        .delete(`/api/items/${itemId}`);
      
      expect(deleteResponse.status).toBe(200);
      expect(deleteResponse.body.success).toBe(true);
      
      // Verify it's gone
      const getResponse = await request(app).get(`/api/items/${itemId}`);
      expect(getResponse.status).toBe(404);
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for unknown endpoint', async () => {
      const response = await request(app).get('/unknown-endpoint');
      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });
  });
});
