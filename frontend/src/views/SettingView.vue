<template>
  <div class="settings-container">
    <h1 class="settings-title">Settings</h1>

    <div class="settings-section">
      <h2 class="section-title">Account Settings</h2>
      <div class="section-content">
        <label for="username" class="settings-label">Username</label>
        <input type="text" id="username" v-model="accountSettings.username" class="settings-input" />

        <label for="email" class="settings-label">Email</label>
        <input type="email" id="email" v-model="accountSettings.email" class="settings-input" />

        <button @click="saveAccountSettings" class="btn save-btn">Save Changes</button>
      </div>
    </div>

    <div class="settings-section">
      <h2 class="section-title">Appearance</h2>
      <div class="section-content">
        <label for="theme" class="settings-label">Theme</label>
        <select id="theme" v-model="appearanceSettings.theme" class="settings-select">
          <option value="light">Light</option>
          <option value="dark">Dark</option>
        </select>

        <button @click="applyTheme" class="btn apply-btn">Apply Theme</button>
      </div>
    </div>

    <div class="settings-section">
      <h2 class="section-title">Notification Settings</h2>
      <div class="section-content">
        <label class="settings-label">
          <input type="checkbox" v-model="notificationSettings.emailNotifications" />
          Email Notifications
        </label>
        <label class="settings-label">
          <input type="checkbox" v-model="notificationSettings.smsNotifications" />
          SMS Notifications
        </label>

        <button @click="saveNotificationSettings" class="btn save-btn">Save Notifications</button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      accountSettings: {
        username: 'JohnDoe',
        email: 'johndoe@example.com',
      },
      appearanceSettings: {
        theme: 'light',
      },
      notificationSettings: {
        emailNotifications: true,
        smsNotifications: false,
      },
    };
  },
  methods: {
    saveAccountSettings() {
      console.log('Saving account settings:', this.accountSettings);
      alert('Account settings saved!');
    },
    applyTheme() {
      console.log('Applying theme:', this.appearanceSettings.theme);
      alert(`Theme set to ${this.appearanceSettings.theme}`);
    },
    saveNotificationSettings() {
      console.log('Saving notification settings:', this.notificationSettings);
      alert('Notification settings saved!');
    },
  },
};
</script>

<style scoped>
.settings-container {
  padding: 20px;
  background-color: #f9f9f9;
  border-radius: 10px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.settings-title {
  font-size: 2rem;
  margin-bottom: 20px;
}

.settings-section {
  margin-bottom: 30px;
}

.section-title {
  font-size: 1.5rem;
  margin-bottom: 10px;
  border-bottom: 1px solid #ddd;
  padding-bottom: 5px;
}

.section-content {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.settings-label {
  font-size: 1rem;
  margin-bottom: 5px;
}

.settings-input,
.settings-select {
  padding: 8px;
  border: 2px solid #ccc;
  border-radius: 5px;
  width: 100%;
}

.btn {
  background-color: #007bff;
  color: white;
  padding: 10px 15px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}

.btn:hover {
  background-color: #0056b3;
}

.save-btn {
  align-self: flex-start;
}

.apply-btn {
  align-self: flex-start;
}
</style>
