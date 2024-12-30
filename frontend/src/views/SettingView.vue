<script setup>
import { ref, onMounted } from "vue";
import Sidebar from "../components/Sidebar.vue";

const userData = ref({
    username: '',
    full_name: '',
    email: '',
    role: '',
    faculty: ''
});

// Retrieve user data from sessionStorage
const getSessionData = () => {
    const sessionData = sessionStorage.getItem('user');
    if (sessionData) {
        const user = JSON.parse(sessionData);
        return {
            username: user.login_name,
            full_name: user.full_name,
            email: user.email,
            role: user.description || 'student',
            faculty: 'Faculty of Computing'
        };
    }
    return null;
};

// Fetch user data from the backend
const fetchUserData = async () => {
    try {
        // First, try to retrieve data from sessionStorage
        const sessionData = getSessionData();
        if (sessionData) {
            userData.value = sessionData;
            return;
        }

        const response = await fetch('/api/user/profile', {
            method: 'GET',
            credentials: 'include',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const data = await response.json();
        
        if (data.success) {
            userData.value = data.user;
        } else {
            console.error('Error:', data.error);
        }
    } catch (error) {
        console.error('Error fetching user data:', error);
    }
};

// Fetch data when the component is mounted
onMounted(() => {
    fetchUserData();
});
</script>

<template>
    <div class="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div class="grow p-6">
            <div class="container mx-auto max-w-4xl">
                <!-- Page Title -->
                <div class="flex justify-between items-center mb-8">
                    <h1 class="text-3xl font-bold text-gray-800">
                        User Profile
                    </h1>
                </div>

                <!-- Profile Information Display -->
                <div class="bg-white rounded-lg shadow-md mb-6">
                    <div class="p-6">
                        <!-- Loading State -->
                        <div v-if="loading" class="flex justify-center items-center py-8">
                            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
                            <span class="ml-2 text-gray-600">Loading profile data...</span>
                        </div>

                        <!-- Error State -->
                        <div v-else-if="error" class="text-center py-8">
                            <p class="text-red-500 mb-4">{{ error }}</p>
                            <button 
                                @click="retryFetch"
                                class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
                            >
                                Retry
                            </button>
                        </div>

                        <!-- Data Display -->
                        <div v-else class="space-y-6">
                            <div class="flex items-center mb-4">
                                <i class="pi pi-user text-blue-500 mr-2"></i>
                                <h2 class="text-xl font-semibold text-gray-800">Profile Information</h2>
                            </div>
                            
                            <!-- User Data Display -->
                            <div v-for="(value, key) in userData" :key="key" class="mb-4">
                                <label class="block text-sm font-medium text-gray-700 mb-1 capitalize">
                                    {{ key.replace('_', ' ') }}
                                </label>
                                <p class="w-full p-3 bg-gray-50 border border-gray-300 rounded-lg">
                                    {{ value }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.rounded-lg {
    border-radius: 0.5rem;
}

.shadow-md {
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}
</style>
