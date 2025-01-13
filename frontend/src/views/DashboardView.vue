<script setup>
import { ref, onMounted } from "vue";
import Button from "primevue/button";
import Card from "primevue/card";
import Sidebar from "../components/Sidebar.vue";

// State to store username and statistic
const fullName = ref("");
const totalSharedResources = ref(0);
const userUploadedResources = ref(0);
const activeCategory = ref(0);
const recentActivities = ref([]);

const fetchRecentActivities = async () => {
  try {
    const response = await fetch("http://127.0.0.1:3000/api/logs/recent", {
      method: "GET",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch recent activities: ${response.status}`);
    }

    recentActivities.value = await response.json();
  } catch (error) {
    console.error("Error fetching recent activities:", error.message);
  }
};

// Function to fetch the user object from sessionStorage
const fetchFullNameFromSession = () => {
  const storedSession = sessionStorage.getItem("user");
  try {
    // Parse the JSON object if it exists
    const userSession = storedSession ? JSON.parse(storedSession) : null;
    fullName.value = userSession?.full_name || "Guest"; // Fallback to 'Guest' if not available
  } catch (error) {
    console.error("Error parsing utmwebfc_session from sessionStorage:", error);
    fullName.value = "Guest"; // Fallback in case of parsing error
  }
};
// Function to fetch resource statistics
const fetchResourceStatistics = async () => {
  const url = "http://127.0.0.1:3000/api/resource/statistics";

  try {
    const response = await fetch(url, {
      method: "GET",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }

    const data = await response.json();
    totalSharedResources.value = data.total_shared_resources || 0;
    userUploadedResources.value = data.user_uploaded_resources || 0;
    activeCategory.value = data.active_category || 0;
  } catch (error) {
    console.error("Error fetching resource statistics:", error.message);
  }
};
// Fetch the full name when the component is mounted
onMounted(() => {
  console.log("Dashboard mounted, fetching username and statistic...");
  fetchFullNameFromSession();
  fetchResourceStatistics();
  fetchRecentActivities();
  console.log("Username set to:", fullName.value); // Debug log
});
</script>

<template>
  <div class="flex min-h-screen">
    <Sidebar />
    <div class="grow bg-gray-100 p-4">
      <div class="container mx-auto">
        <!-- Show Username -->
        <div class="flex justify-between items-center mb-6">
          <h1 class="text-2xl font-bold text-gray-800">Dashboard</h1>
          <div class="text-lg text-gray-600">
            Welcome,
            <span class="font-semibold text-gray-800">{{ fullName }}</span>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <!-- Quick Stats Cards -->
          <Card class="shadow-md">
            <template #title>Total Shared Resources</template>
            <template #content>
              <div class="text-3xl font-bold text-blue-600">
                {{ totalSharedResources }}
              </div>
              <div class="text-sm text-gray-500">
                Resources shared across courses
              </div>
            </template>
          </Card>

          <Card class="shadow-md">
            <template #title>Recent Uploads</template>
            <template #content>
              <div class="text-3xl font-bold text-green-600">
                {{ userUploadedResources }}
              </div>
              <div class="text-sm text-gray-500">New resources this week</div>
            </template>
          </Card>

          <Card class="shadow-md">
            <template #title>Active Categories</template>
            <template #content>
              <div class="text-3xl font-bold text-purple-600">
                {{ activeCategory }}
              </div>
              <div class="text-sm text-gray-500">Categories of resources</div>
            </template>
          </Card>
        </div>

        <!-- Quick Actions -->
        <div class="mt-8">
          <h2 class="text-xl font-semibold mb-4 text-gray-700">
            Quick Actions
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Button
              label="Upload New Resource"
              icon="pi pi-upload"
              class="p-button-primary w-full"
              @click="$router.push({ name: 'files' })"
            />
            <Button
              label="Create Shared Folder"
              icon="pi pi-folder-plus"
              class="p-button-secondary w-full"
              @click="$router.push({ name: 'folders' })"
            />
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="mt-8">
          <h2 class="text-xl font-semibold mb-4 text-gray-700">
            Recent Activity
          </h2>
          <Card>
            <template #content>
              <ul class="divide-y divide-gray-200">
                <li
                  v-for="activity in recentActivities"
                  :key="activity.timestamp"
                  class="py-3 flex justify-between items-center"
                >
                  <div>
                    <span class="font-medium text-gray-800">{{
                      activity.resource_name
                    }}</span>
                    <span class="block text-sm text-gray-500">{{
                      activity.action
                    }}</span>
                  </div>
                  <span class="text-sm text-gray-500">{{
                    new Date(activity.timestamp).toLocaleString()
                  }}</span>
                </li>
              </ul>
            </template>
          </Card>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>
