const axios = require('axios');
const chalk = require('chalk');

const API_URL = process.env.API_URL || 'http://localhost:8080';

class TestRunner {
  constructor() {
    this.tests = [];
    this.passed = 0;
    this.failed = 0;
  }

  test(name, fn) {
    this.tests.push({ name, fn });
  }

  async run() {
    console.log(chalk.blue.bold('\n🧪 Running Integration Tests\n'));
    console.log(chalk.gray(`API URL: ${API_URL}\n`));

    for (const test of this.tests) {
      try {
        await test.fn();
        this.passed++;
        console.log(chalk.green('✓'), test.name);
      } catch (error) {
        this.failed++;
        console.log(chalk.red('✗'), test.name);
        console.log(chalk.red('  Error:'), error.message);
      }
    }

    console.log(chalk.blue.bold('\n📊 Test Results\n'));
    console.log(chalk.green(`Passed: ${this.passed}`));
    console.log(chalk.red(`Failed: ${this.failed}`));
    console.log(chalk.gray(`Total:  ${this.tests.length}\n`));

    if (this.failed > 0) {
      process.exit(1);
    }
  }
}

const runner = new TestRunner();

// Health Check Tests
runner.test('Health endpoint returns healthy status', async () => {
  const response = await axios.get(`${API_URL}/health`);
  if (response.status !== 200) throw new Error('Expected status 200');
  if (response.data.status !== 'healthy') throw new Error('Expected healthy status');
});

runner.test('Readiness endpoint returns ready status', async () => {
  const response = await axios.get(`${API_URL}/ready`);
  if (response.status !== 200) throw new Error('Expected status 200');
  if (response.data.status !== 'ready') throw new Error('Expected ready status');
});

runner.test('Version endpoint returns version info', async () => {
  const response = await axios.get(`${API_URL}/version`);
  if (response.status !== 200) throw new Error('Expected status 200');
  if (!response.data.version) throw new Error('Expected version field');
  if (!response.data.environment) throw new Error('Expected environment field');
});

// Items API Tests
runner.test('GET /api/items returns list of items', async () => {
  const response = await axios.get(`${API_URL}/api/items`);
  if (response.status !== 200) throw new Error('Expected status 200');
  if (!response.data.success) throw new Error('Expected success: true');
  if (!Array.isArray(response.data.data)) throw new Error('Expected data to be array');
});

runner.test('POST /api/items creates a new item', async () => {
  const newItem = {
    name: 'Test Item',
    description: 'Created by integration test'
  };
  const response = await axios.post(`${API_URL}/api/items`, newItem);
  if (response.status !== 201) throw new Error('Expected status 201');
  if (!response.data.success) throw new Error('Expected success: true');
  if (response.data.data.name !== newItem.name) throw new Error('Name mismatch');
});

runner.test('POST /api/items fails without name', async () => {
  try {
    await axios.post(`${API_URL}/api/items`, { description: 'No name' });
    throw new Error('Expected request to fail');
  } catch (error) {
    if (error.response.status !== 400) throw new Error('Expected status 400');
  }
});

runner.test('GET /api/items/:id returns specific item', async () => {
  const response = await axios.get(`${API_URL}/api/items/1`);
  if (response.status !== 200) throw new Error('Expected status 200');
  if (!response.data.success) throw new Error('Expected success: true');
  if (response.data.data.id !== 1) throw new Error('Expected item id 1');
});

runner.test('GET /api/items/:id returns 404 for non-existent item', async () => {
  try {
    await axios.get(`${API_URL}/api/items/99999`);
    throw new Error('Expected request to fail');
  } catch (error) {
    if (error.response.status !== 404) throw new Error('Expected status 404');
  }
});

runner.test('PUT /api/items/:id updates an item', async () => {
  const updates = { name: 'Updated Item' };
  const response = await axios.put(`${API_URL}/api/items/1`, updates);
  if (response.status !== 200) throw new Error('Expected status 200');
  if (!response.data.success) throw new Error('Expected success: true');
  if (response.data.data.name !== updates.name) throw new Error('Name not updated');
});

runner.test('DELETE /api/items/:id deletes an item', async () => {
  // First create an item to delete
  const createResponse = await axios.post(`${API_URL}/api/items`, {
    name: 'Item to Delete'
  });
  const itemId = createResponse.data.data.id;
  
  // Delete it
  const deleteResponse = await axios.delete(`${API_URL}/api/items/${itemId}`);
  if (deleteResponse.status !== 200) throw new Error('Expected status 200');
  
  // Verify it's gone
  try {
    await axios.get(`${API_URL}/api/items/${itemId}`);
    throw new Error('Item should not exist');
  } catch (error) {
    if (error.response.status !== 404) throw new Error('Expected status 404');
  }
});

// Error Handling Tests
runner.test('Unknown endpoint returns 404', async () => {
  try {
    await axios.get(`${API_URL}/unknown-endpoint`);
    throw new Error('Expected request to fail');
  } catch (error) {
    if (error.response.status !== 404) throw new Error('Expected status 404');
  }
});

// Run all tests
runner.run().catch(error => {
  console.error(chalk.red('\nFatal Error:'), error);
  process.exit(1);
});
