<template>
  <div :class="['settings-container p-6 rounded-lg shadow-md', themeClass]">
    <h1 class="settings-title text-3xl font-semibold mb-6" :class="textColorClass">Settings</h1>

    <!-- Account Settings -->
    <div class="settings-section mb-8">
      <h2 class="section-title text-2xl font-medium mb-4 border-b pb-2" :class="[textColorClass, borderColorClass]">
        Account Settings
      </h2>
      <div class="section-content flex flex-col gap-4">
        <label for="username" :class="labelClass">Username</label>
        <input
          type="text"
          id="username"
          v-model="accountSettings.username"
          class="settings-input p-2 border-2 rounded-md w-full"
          :class="inputClass"
        />

        <label for="email" :class="labelClass">Email</label>
        <input
          type="email"
          id="email"
          v-model="accountSettings.email"
          class="settings-input p-2 border-2 rounded-md w-full"
          :class="inputClass"
        />

        <label for="oldPassword" :class="labelClass">Old Password</label>
        <input
          type="password"
          id="oldPassword"
          v-model="password.oldPassword"
          class="settings-input p-2 border-2 rounded-md w-full"
          :class="inputClass"
        />

        <label for="newPassword" :class="labelClass">New Password</label>
        <input
          type="password"
          id="newPassword"
          v-model="password.newPassword"
          class="settings-input p-2 border-2 rounded-md w-full"
          :class="inputClass"
        />

        <button
          @click="changePassword"
          class="btn save-btn py-1 px-3 text-sm rounded-md w-32"
          :class="buttonClass"
        >
          Changed
        </button>

        <p v-if="passwordError" class="text-red-500 text-sm">{{ passwordError }}</p>
      </div>
    </div>

    <!-- Appearance Settings -->
    <div class="settings-section mb-8">
      <h2 class="section-title text-2xl font-medium mb-4 border-b pb-2" :class="[textColorClass, borderColorClass]">
        Appearance
      </h2>
      <div class="section-content flex flex-col gap-4">
        <label for="theme" :class="labelClass">Theme</label>
        <select
          id="theme"
          v-model="appearanceSettings.theme"
          class="settings-select p-2 border-2 rounded-md w-full"
          :class="inputClass"
          @change="applyTheme"
        >
          <option value="light">Light</option>
          <option value="dark">Dark</option>
        </select>

        <label for="language" :class="labelClass">Language</label>
        <select
          id="language"
          v-model="appearanceSettings.language"
          class="settings-select p-2 border-2 rounded-md w-full"
          :class="inputClass"
          @change="applyLanguage"
        >
          <option value="en">English</option>
          <option value="zh">Bahasa Cina</option>
          <option value="ms">Bahasa Melayu</option>
        </select>
      </div>
    </div>

    <!-- Notification Settings -->
    <div class="settings-section mb-8">
      <h2 class="section-title text-2xl font-medium mb-4 border-b pb-2" :class="[textColorClass, borderColorClass]">
        Notification Settings
      </h2>
      <div class="section-content flex flex-col gap-4">
        <label class="settings-label flex items-center gap-2" :class="labelClass">
          <input type="checkbox" v-model="notificationSettings.emailNotifications" class="form-checkbox" />
          Email Notifications
        </label>

        <label class="settings-label flex items-center gap-2" :class="labelClass">
          <input type="checkbox" v-model="notificationSettings.smsNotifications" class="form-checkbox" />
          SMS Notifications
        </label>

        <label class="settings-label flex items-center gap-2" :class="labelClass">
          <input type="checkbox" v-model="notificationSettings.pushNotifications" class="form-checkbox" />
          Push Notifications
        </label>

        <button
          @click="saveNotificationSettings"
          class="btn save-btn py-1 px-3 text-sm rounded-md w-32"
          :class="buttonClass"
        >
          Save Notifications
        </button>
      </div>
    </div>

    <!-- Privacy Settings -->
    <div class="settings-section">
      <h2 class="section-title text-2xl font-medium mb-4 border-b pb-2" :class="[textColorClass, borderColorClass]">
        Privacy Settings
      </h2>
      <div class="section-content flex flex-col gap-4">
        <button
          @click="viewHistory"
          class="btn view-btn py-1 px-3 text-sm rounded-md w-32"
          :class="buttonClass"
        >
          View History
        </button>

        <button
          @click="clearHistory"
          class="btn clear-btn py-1 px-3 text-sm rounded-md w-32 bg-red-600 hover:bg-red-700 text-white"
        >
          Clear History
        </button>
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
      password: {
        oldPassword: '',
        newPassword: '',
      },
      passwordError: '',
      appearanceSettings: {
        theme: 'light',
        language: 'en',
      },
      notificationSettings: {
        emailNotifications: true,
        smsNotifications: false,
        pushNotifications: true,
      },
    };
  },
  computed: {
    themeClass() {
      return this.appearanceSettings.theme === 'dark' ? 'bg-black' : 'bg-gray-100';
    },
    textColorClass() {
      return this.appearanceSettings.theme === 'dark' ? 'text-white' : 'text-black';
    },
    inputClass() {
      return this.appearanceSettings.theme === 'dark' ? 'border-gray-700 bg-gray-800 text-white' : 'border-gray-300 bg-white text-black';
    },
    buttonClass() {
      return this.appearanceSettings.theme === 'dark' ? 'bg-gray-700 text-white hover:bg-gray-600' : 'bg-blue-600 text-white hover:bg-blue-700';
    },
    borderColorClass() {
      return this.appearanceSettings.theme === 'dark' ? 'border-gray-700' : 'border-gray-300';
    },
    labelClass() {
      return `${this.textColorClass} text-lg font-medium`;
    },
  },
  methods: {
    changePassword() {
      if (this.password.oldPassword !== 'correct_password') {
        this.passwordError = 'The old password is incorrect. Please try again.';
      } else {
        this.passwordError = '';
        alert('Password changed successfully!');
      }
    },
    applyTheme() {
      console.log('Applying theme:', this.appearanceSettings.theme);
    },
    applyLanguage() {
      console.log('Applying language:', this.appearanceSettings.language);
      alert(`Language changed to ${this.appearanceSettings.language}`);
    },
    saveNotificationSettings() {
      console.log('Notification settings saved:', this.notificationSettings);
      alert('Notification settings saved!');
    },
    viewHistory() {
      console.log('Viewing history...');
      alert('Displaying browsing history (dummy implementation).');
    },
    clearHistory() {
      if (confirm('Are you sure you want to clear your history?')) {
        console.log('History cleared');
        alert('Your browsing history has been cleared.');
      }
    },
  },
};
</script>
