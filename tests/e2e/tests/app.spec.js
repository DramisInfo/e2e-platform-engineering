const { test, expect } = require('@playwright/test');

test.describe('E2E SDLC Platform Demo', () => {
  test('should load the application', async ({ page }) => {
    await page.goto('/');
    
    // Check page title
    await expect(page.locator('h1')).toContainText('E2E SDLC Platform Demo');
  });

  test('should display version information', async ({ page }) => {
    await page.goto('/');
    
    // Wait for version info to load
    await page.waitForSelector('.version-details', { timeout: 10000 });
    
    // Check version badge exists
    const versionBadge = page.locator('.version-badge');
    await expect(versionBadge).toBeVisible();
    
    // Check environment badge exists
    const environmentBadge = page.locator('.environment-badge');
    await expect(environmentBadge).toBeVisible();
  });

  test('should load and display items', async ({ page }) => {
    await page.goto('/');
    
    // Wait for items to load
    await page.waitForSelector('.items-list', { timeout: 10000 });
    
    // Check that items list is visible
    const itemsList = page.locator('.items-list');
    await expect(itemsList).toBeVisible();
  });

  test('should create a new item', async ({ page }) => {
    await page.goto('/');
    
    // Wait for form to be ready
    await page.waitForSelector('#create-form');
    
    // Fill in the form
    const itemName = `Test Item ${Date.now()}`;
    await page.fill('#item-name', itemName);
    await page.fill('#item-description', 'E2E test item');
    
    // Submit the form
    await page.click('button[type="submit"]');
    
    // Wait for success message
    await page.waitForSelector('.message-success', { timeout: 5000 });
    
    // Check that the item appears in the list
    await expect(page.locator('.item-name', { hasText: itemName })).toBeVisible();
  });

  test('should show validation error when creating item without name', async ({ page }) => {
    await page.goto('/');
    
    // Wait for form to be ready
    await page.waitForSelector('#create-form');
    
    // Try to submit empty form
    await page.click('button[type="submit"]');
    
    // Form should not submit (HTML5 validation)
    const nameInput = page.locator('#item-name');
    await expect(nameInput).toHaveAttribute('required');
  });

  test('should delete an item', async ({ page }) => {
    await page.goto('/');
    
    // First create an item
    await page.waitForSelector('#create-form');
    const itemName = `Item to Delete ${Date.now()}`;
    await page.fill('#item-name', itemName);
    await page.click('button[type="submit"]');
    
    // Wait for success message
    await page.waitForSelector('.message-success', { timeout: 5000 });
    
    // Wait for item to appear
    await page.waitForSelector(`.item-name:has-text("${itemName}")`);
    
    // Set up dialog handler
    page.on('dialog', dialog => dialog.accept());
    
    // Find and click the delete button for this item
    const itemCard = page.locator('.item-card', { has: page.locator('.item-name', { hasText: itemName }) });
    const deleteButton = itemCard.locator('.delete-btn');
    await deleteButton.click();
    
    // Wait for success message
    await page.waitForSelector('.message-success', { timeout: 5000 });
    
    // Verify item is no longer visible
    await expect(page.locator('.item-name', { hasText: itemName })).not.toBeVisible({ timeout: 5000 });
  });

  test('should have responsive design', async ({ page }) => {
    await page.goto('/');
    
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await expect(page.locator('.container')).toBeVisible();
    
    // Test tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await expect(page.locator('.container')).toBeVisible();
    
    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 });
    await expect(page.locator('.container')).toBeVisible();
  });

  test('should handle API errors gracefully', async ({ page }) => {
    // This test assumes the backend might be unavailable
    // In a real scenario, you might mock network failures
    await page.goto('/');
    
    // The app should still render even if API calls fail
    await expect(page.locator('.container')).toBeVisible();
    await expect(page.locator('h1')).toContainText('E2E SDLC Platform Demo');
  });
});
