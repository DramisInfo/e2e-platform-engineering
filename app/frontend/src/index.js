import axios from 'axios';
import './styles.css';

const API_URL = window.BACKEND_URL || 'http://localhost:8080';

class App {
  constructor() {
    this.items = [];
    this.version = null;
    this.init();
  }

  async init() {
    this.render();
    await this.loadVersion();
    await this.loadItems();
    this.attachEventListeners();
  }

  async loadVersion() {
    try {
      const response = await axios.get(`${API_URL}/version`);
      this.version = response.data;
      this.updateVersionDisplay();
    } catch (error) {
      console.error('Failed to load version:', error);
    }
  }

  async loadItems() {
    try {
      const response = await axios.get(`${API_URL}/api/items`);
      this.items = response.data.data;
      this.renderItems();
    } catch (error) {
      console.error('Failed to load items:', error);
      this.showError('Failed to load items');
    }
  }

  async createItem(name, description) {
    try {
      const response = await axios.post(`${API_URL}/api/items`, {
        name,
        description
      });
      this.items.push(response.data.data);
      this.renderItems();
      this.showSuccess('Item created successfully');
    } catch (error) {
      console.error('Failed to create item:', error);
      this.showError('Failed to create item');
    }
  }

  async deleteItem(id) {
    try {
      await axios.delete(`${API_URL}/api/items/${id}`);
      this.items = this.items.filter(item => item.id !== id);
      this.renderItems();
      this.showSuccess('Item deleted successfully');
    } catch (error) {
      console.error('Failed to delete item:', error);
      this.showError('Failed to delete item');
    }
  }

  render() {
    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="container">
        <header class="header">
          <h1>🚀 E2E SDLC Platform Demo</h1>
          <div class="version-info" id="version-info">
            <span class="loading">Loading version...</span>
          </div>
        </header>

        <main class="main">
          <section class="create-section">
            <h2>Create New Item</h2>
            <form id="create-form">
              <input 
                type="text" 
                id="item-name" 
                placeholder="Item name" 
                required
                class="input"
              />
              <input 
                type="text" 
                id="item-description" 
                placeholder="Description (optional)"
                class="input"
              />
              <button type="submit" class="btn btn-primary">Add Item</button>
            </form>
          </section>

          <section class="items-section">
            <h2>Items</h2>
            <div id="items-list" class="items-list">
              <div class="loading">Loading items...</div>
            </div>
          </section>

          <div id="message" class="message"></div>
        </main>

        <footer class="footer">
          <p>GitOps Demo • Powered by ArgoCD, Argo Rollouts & Argo Events</p>
        </footer>
      </div>
    `;
  }

  renderItems() {
    const itemsList = document.getElementById('items-list');
    
    if (this.items.length === 0) {
      itemsList.innerHTML = '<p class="empty-state">No items yet. Create one above!</p>';
      return;
    }

    itemsList.innerHTML = this.items.map(item => `
      <div class="item-card" data-id="${item.id}">
        <div class="item-content">
          <h3 class="item-name">${this.escapeHtml(item.name)}</h3>
          <p class="item-description">${this.escapeHtml(item.description)}</p>
        </div>
        <button 
          class="btn btn-danger delete-btn" 
          data-id="${item.id}"
        >
          Delete
        </button>
      </div>
    `).join('');
  }

  updateVersionDisplay() {
    const versionInfo = document.getElementById('version-info');
    if (this.version) {
      versionInfo.innerHTML = `
        <div class="version-details">
          <span class="version-badge">v${this.version.version}</span>
          <span class="environment-badge">${this.version.environment}</span>
          <span class="commit-sha" title="Commit: ${this.version.commitSha}">
            ${this.version.commitSha.substring(0, 7)}
          </span>
        </div>
      `;
    }
  }

  attachEventListeners() {
    const form = document.getElementById('create-form');
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const name = document.getElementById('item-name').value.trim();
      const description = document.getElementById('item-description').value.trim();
      
      if (name) {
        this.createItem(name, description);
        form.reset();
      }
    });

    document.addEventListener('click', (e) => {
      if (e.target.classList.contains('delete-btn')) {
        const id = parseInt(e.target.dataset.id);
        if (confirm('Are you sure you want to delete this item?')) {
          this.deleteItem(id);
        }
      }
    });
  }

  showSuccess(message) {
    this.showMessage(message, 'success');
  }

  showError(message) {
    this.showMessage(message, 'error');
  }

  showMessage(message, type) {
    const messageEl = document.getElementById('message');
    messageEl.textContent = message;
    messageEl.className = `message message-${type} show`;
    
    setTimeout(() => {
      messageEl.classList.remove('show');
    }, 3000);
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  new App();
});
