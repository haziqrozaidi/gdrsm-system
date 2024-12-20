<script setup>
import { ref, onMounted, watch } from "vue";
import Button from "primevue/button";
import Card from "primevue/card";
import InputText from "primevue/inputtext";
import Password from "primevue/password";
import Divider from "primevue/divider";
import ToggleButton from "primevue/togglebutton";
import Sidebar from "../components/Sidebar.vue";

// State management for user information
const fullName = ref('');
const email = ref('');
const currentPassword = ref('');
const newPassword = ref('');
const confirmPassword = ref('');

// Theme preferences with localStorage support
const isDarkMode = ref(localStorage.getItem('theme') === 'dark');

// Notification preferences
const emailNotifications = ref(true);
const systemNotifications = ref(true);

// Fetch user data from session
const fetchUserData = () => {
    const storedSession = sessionStorage.getItem('utmwebfc_session');
    try {
        const userSession = JSON.parse(storedSession);
        fullName.value = userSession?.full_name || '';
        email.value = userSession?.email || '';
    } catch (error) {
        console.error('Error parsing user session:', error);
    }
};

// Initialize theme on component mount
onMounted(() => {
    fetchUserData();
    initializeTheme();
});

// Function to initialize theme based on stored preference
const initializeTheme = () => {
    // Check localStorage first, then system preference
    const storedTheme = localStorage.getItem('theme');
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    if (storedTheme) {
        isDarkMode.value = storedTheme === 'dark';
    } else {
        isDarkMode.value = systemPrefersDark;
    }
    
    applyTheme(isDarkMode.value);
};

// Function to apply theme
const applyTheme = (isDark) => {
    if (isDark) {
        document.documentElement.classList.add('dark');
    } else {
        document.documentElement.classList.remove('dark');
    }
};

// Handle theme toggle with persistence
const toggleTheme = () => {
    // Update localStorage with new theme preference
    localStorage.setItem('theme', isDarkMode.value ? 'dark' : 'light');
    applyTheme(isDarkMode.value);
};

// Watch for theme changes
watch(isDarkMode, (newValue) => {
    applyTheme(newValue);
});

// Handle profile update
const updateProfile = () => {
    // TODO: Implement profile update logic
    console.log('Profile update requested');
};

// Handle password change
const changePassword = () => {
    // TODO: Implement password change logic
    console.log('Password change requested');
};
</script>

<template>
    <div class="flex min-h-screen bg-gray-50 dark:bg-gray-900 transition-colors duration-200">
        <Sidebar />
        <div class="grow p-6">
            <div class="container mx-auto max-w-4xl">
                <!-- Page Header -->
                <div class="flex justify-between items-center mb-8">
                    <h1 class="text-3xl font-bold text-gray-800 dark:text-white">
                        Settings
                    </h1>
                </div>

                <!-- Profile Settings -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md mb-6 transition-all duration-200">
                    <div class="p-6">
                        <div class="flex items-center mb-4">
                            <i class="pi pi-user text-blue-500 mr-2"></i>
                            <h2 class="text-xl font-semibold text-gray-800 dark:text-white">Profile Settings</h2>
                        </div>
                        <div class="space-y-4">
                            <div>
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Full Name
                                </label>
                                <InputText v-model="fullName" 
                                         class="w-full p-3 bg-gray-50 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg
                                                focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400 focus:border-transparent" />
                            </div>
                            <div>
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Email
                                </label>
                                <InputText v-model="email" type="email" 
                                         class="w-full p-3 bg-gray-50 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg
                                                focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400 focus:border-transparent" />
                            </div>
                            <Button label="Update Profile" 
                                   icon="pi pi-check" 
                                   @click="updateProfile"
                                   class="w-full md:w-auto bg-blue-500 hover:bg-blue-600 transition-colors duration-200" />
                        </div>
                    </div>
                </div>

                <!-- Password Change -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md mb-6 transition-all duration-200">
                    <div class="p-6">
                        <div class="flex items-center mb-4">
                            <i class="pi pi-lock text-green-500 mr-2"></i>
                            <h2 class="text-xl font-semibold text-gray-800 dark:text-white">Change Password</h2>
                        </div>
                        <div class="space-y-4">
                            <div>
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Current Password
                                </label>
                                <Password v-model="currentPassword" toggleMask 
                                         class="w-full" 
                                         inputClass="w-full p-3 bg-gray-50 dark:bg-gray-700" />
                            </div>
                            <div>
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    New Password
                                </label>
                                <Password v-model="newPassword" toggleMask 
                                         class="w-full"
                                         inputClass="w-full p-3 bg-gray-50 dark:bg-gray-700" />
                            </div>
                            <div>
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Confirm New Password
                                </label>
                                <Password v-model="confirmPassword" toggleMask 
                                         class="w-full"
                                         inputClass="w-full p-3 bg-gray-50 dark:bg-gray-700" />
                            </div>
                            <Button label="Change Password" 
                                   icon="pi pi-lock" 
                                   @click="changePassword"
                                   class="w-full md:w-auto bg-green-500 hover:bg-green-600 transition-colors duration-200" />
                        </div>
                    </div>
                </div>

                <!-- Preferences -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md transition-all duration-200">
                    <div class="p-6">
                        <div class="flex items-center mb-4">
                            <i class="pi pi-cog text-purple-500 mr-2"></i>
                            <h2 class="text-xl font-semibold text-gray-800 dark:text-white">Preferences</h2>
                        </div>
                        <div class="space-y-4">
                            <div class="flex justify-between items-center p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors duration-200">
                                <div class="flex items-center space-x-3">
                                    <i :class="[
                                        isDarkMode ? 'pi pi-moon text-indigo-500 dark:text-indigo-400' : 'pi pi-sun text-yellow-500 dark:text-yellow-400'
                                    ]"></i>
                                    <div>
                                        <span class="block text-gray-700 dark:text-gray-200 font-medium">Theme Mode</span>
                                        <span class="text-sm text-gray-500 dark:text-gray-400">
                                            {{ isDarkMode ? 'Dark theme enabled' : 'Light theme enabled' }}
                                        </span>
                                    </div>
                                </div>
                                <ToggleButton v-model="isDarkMode" 
                                            @change="toggleTheme"
                                            class="transform hover:scale-105 transition-transform duration-200"
                                            :class="{'dark-mode-toggle': true}"
                                            :onIcon="'pi pi-moon'"
                                            :offIcon="'pi pi-sun'"
                                            :onLabel="'Dark'"
                                            :offLabel="'Light'"
                                            aria-label="Toggle Theme" />
                            </div>
                            
                            <!-- Other preference toggles with similar styling -->
                            <div class="flex justify-between items-center p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors duration-200">
                                <div class="flex items-center space-x-3">
                                    <i class="pi pi-envelope text-green-500 dark:text-green-400"></i>
                                    <div>
                                        <span class="block text-gray-700 dark:text-gray-200 font-medium">Email Notifications</span>
                                        <span class="text-sm text-gray-500 dark:text-gray-400">
                                            Receive email updates about your account
                                        </span>
                                    </div>
                                </div>
                                <ToggleButton v-model="emailNotifications"
                                            class="transform hover:scale-105 transition-transform duration-200" />
                            </div>

                            <div class="flex justify-between items-center p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors duration-200">
                                <div class="flex items-center space-x-3">
                                    <i class="pi pi-bell text-yellow-500 dark:text-yellow-400"></i>
                                    <div>
                                        <span class="block text-gray-700 dark:text-gray-200 font-medium">System Notifications</span>
                                        <span class="text-sm text-gray-500 dark:text-gray-400">
                                            Receive system notifications and alerts
                                        </span>
                                    </div>
                                </div>
                                <ToggleButton v-model="systemNotifications"
                                            class="transform hover:scale-105 transition-transform duration-200" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
/* Custom styles for dark mode toggle */
:deep(.dark-mode-toggle.p-button) {
    background: var(--surface-200);
    border: none;
    transition: all 0.2s ease;
    min-width: 80px; /* Add minimum width for better appearance */
}

:deep(.dark-mode-toggle.p-button:not(.p-disabled):hover) {
    background: var(--surface-300);
}

:deep(.dark-mode-toggle.p-button.p-highlight) {
    background: var(--primary-color);
}

/* Add icon specific styles */
:deep(.dark-mode-toggle.p-button .p-button-icon) {
    font-size: 1.2rem;
    transition: transform 0.3s ease;
}

:deep(.dark-mode-toggle.p-button:hover .p-button-icon) {
    transform: rotate(12deg);
}

/* Add specific styles for light mode icon */
:deep(.dark-mode-toggle.p-button:not(.p-highlight) .pi-sun) {
    color: var(--yellow-500);
}

/* Add specific styles for dark mode icon */
:deep(.dark-mode-toggle.p-button.p-highlight .pi-moon) {
    color: var(--indigo-200);
}

/* Password input dark mode styles */
:deep(.p-password input) {
    width: 100%;
    transition: all 0.2s ease;
}

:deep(.dark .p-password input) {
    background-color: var(--surface-900);
    color: var(--surface-0);
    border-color: var(--surface-700);
}

/* Toggle button general styles */
:deep(.p-togglebutton.p-button) {
    background: var(--surface-200);
    border: none;
    transition: all 0.2s ease;
}

:deep(.p-togglebutton.p-button.p-highlight) {
    background: var(--primary-color);
}

/* Add smooth transitions for all interactive elements */
.transition-all {
    transition-property: all;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 150ms;
}
</style>
