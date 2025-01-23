<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import MultiSelect from 'primevue/multiselect';
import { useToast } from 'primevue/usetoast';
import Sidebar from "../components/Sidebar.vue";

const toast = useToast();
const sharedResources = ref([]);
const resources = ref([]);
const categories = ref([]);
const filteredFiles = ref([]);
const searchTerm = ref('');
const selectedCategory = ref(null);
const categorySearch = ref('');
const isDropdownOpen = ref(false);
const dateFrom = ref('');
const dateTo = ref('');
const sharedBy = ref('');
const folder = ref('');
const selectedSession = ref('');
const selectedSemester = ref(''); // Semester filter
const showShareDialog = ref(false);
const users = ref([]);
const groups = ref([]);
const selectedUsers = ref([]);
const selectedGroups = ref([]);
const resourceToShare = ref(null);

// Re-compute categories for searching
const filteredCategories = computed(() => {
    return categories.value.filter(category =>
        category.name.toLowerCase().includes(categorySearch.value.toLowerCase())
    );
});

const apiBaseURL = 'http://127.0.0.1:3000/api';

async function fetchResources() {
    try {
        const response = await fetch(`${apiBaseURL}/resources`, {
            method: 'GET',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
        });
        if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);
        resources.value = await response.json();
        applyFilters(); // Apply filters after fetching resources
    } catch (error) {
        console.error("Failed to fetch resources:", error);
        toast.add({ severity: 'error', summary: 'Fetch Failed', detail: error.message, life: 3000 });
    }
}

async function fetchCategories() {
    try {
        const response = await fetch(`${apiBaseURL}/categories`, {
            method: 'GET',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
        });
        if (!response.ok) throw new Error('Failed to fetch categories');
        categories.value = await response.json();
    } catch (error) {
        console.error('Error fetching categories:', error);
        toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to load categories', life: 3000 });
    }
}

async function fetchUsersAndGroups() {
    try {
        const usersResponse = await fetch(`${apiBaseURL}/users`, {
            method: 'GET',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
        });
        const groupsResponse = await fetch(`${apiBaseURL}/groups`, {
            method: 'GET',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
        });
        if (!usersResponse.ok || !groupsResponse.ok) {
            throw new Error('Failed to fetch users or groups');
        }
        users.value = await usersResponse.json();
        groups.value = await groupsResponse.json();
    } catch (error) {
        console.error('Error fetching users or groups:', error);
        toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to load users or groups', life: 3000 });
    }
}

function applyFilters() {
    let result = resources.value;
    if (searchTerm.value) {
        result = result.filter(file => file.name.toLowerCase().includes(searchTerm.value.toLowerCase()));
    }
    if (selectedCategory.value) {
        result = result.filter(file => file.category_id === selectedCategory.value.category_id);
    }
    if (dateFrom.value && dateTo.value) {
        result = result.filter(file =>
            new Date(file.date_created) >= new Date(dateFrom.value) &&
            new Date(file.date_created) <= new Date(dateTo.value)
        );
    }
    if (sharedBy.value) {
        result = result.filter(file => file.owner.toLowerCase().includes(sharedBy.value.toLowerCase()));
    }
    if (folder.value) {
        result = result.filter(file => file.folder_id === folder.value);
    }
    if (selectedSession.value) {
        result = result.filter(file => file.session === selectedSession.value);
    }
    if (selectedSemester.value) {
        result = result.filter(file => file.semester === selectedSemester.value);
    }
    filteredFiles.value = result;
}

watch([searchTerm, selectedSession, selectedSemester], applyFilters);

const toggleDropdown = () => {
    isDropdownOpen.value = !isDropdownOpen.value;
};

const selectCategory = (category) => {
    selectedCategory.value = category;
    isDropdownOpen.value = false;
    applyFilters();
};

// Share Functionality
const openShareDialog = async (resource) => {
    resourceToShare.value = resource;
    selectedUsers.value = [];
    selectedGroups.value = [];
    await fetchUsersAndGroups();
    showShareDialog.value = true;
};

const shareResource = async () => {
    if (!selectedUsers.value.length && !selectedGroups.value.length) {
        toast.add({
            severity: 'warn',
            summary: 'Warning',
            detail: 'Select users or groups to share with',
            life: 3000,
        });
        return;
    }

    try {
        const response = await fetch(`${apiBaseURL}/resources/share`, {
            method: 'POST',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                resource_id: resourceToShare.value.resource_id,
                user_ids: selectedUsers.value,
                group_ids: selectedGroups.value,
            }),
        });
        if (!response.ok) throw new Error('Failed to share resource');
        toast.add({
            severity: 'success',
            summary: 'Success',
            detail: 'Resource shared successfully',
            life: 3000,
        });
        showShareDialog.value = false;
    } catch (error) {
        console.error('Error sharing resource:', error.message);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to share resource',
            life: 3000,
        });
    }
};

onMounted(() => {
    fetchResources();
    fetchCategories();
});
</script>

<template>
  <div class="flex min-h-screen">
    <Sidebar />
    <div class="grow bg-gray-100 p-4">
      <div class="card">
        <div class="flex justify-between mb-4">
          <h2 class="text-2xl font-bold">Search Resources</h2>
        </div>
        <div class="flex flex-col gap-2.5">
          <!-- Search Bar with Category Dropdown -->
          <div class="flex items-center gap-2.5 bg-gray-100 rounded-lg">
            <div class="relative flex-grow">
              <i class="pi pi-search absolute left-2.5 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
              <input
                type="text"
                v-model="searchTerm"
                placeholder="Search resources..."
                class="pl-10 pr-2.5 py-2.5 w-full border border-gray-300 rounded-lg text-sm"
              />
            </div>
            <div class="relative">
              <button
                @click="toggleDropdown"
                class="bg-white border border-gray-300 text-black px-2.5 py-2 rounded-lg flex items-center gap-2"
              >
                {{ selectedCategory?.name || "All Categories" }}
                <i class="pi pi-chevron-down"></i>
              </button>
              <div
                v-if="isDropdownOpen"
                class="absolute w-64 mt-1 bg-white border border-gray-300 rounded-lg overflow-auto max-h-72 z-10"
              >
                <input
                  type="text"
                  v-model="categorySearch"
                  placeholder="Search categories..."
                  class="w-full border-b border-gray-300 p-2"
                />
                <ul class="list-none m-0 p-0">
                  <li
                    v-for="category in filteredCategories"
                    :key="category.category_id"
                    @click="selectCategory(category)"
                    class="flex items-center p-2 cursor-pointer hover:bg-gray-100"
                  >
                    {{ category.name }}
                  </li>
                </ul>
              </div>
            </div>
            <button
              @click="applyFilters"
              class="bg-black text-white px-5 py-2.5 rounded-lg cursor-pointer text-sm"
            >
              Search
            </button>
          </div>

          <!-- Filters -->
          <div class="filters flex flex-wrap gap-4 bg-white p-4 rounded-lg shadow">
            <div class="flex-1 min-w-[200px]">
              <label for="dateFrom" class="block text-sm font-medium text-gray-700 mb-1">Date From</label>
              <input
                type="date"
                id="dateFrom"
                v-model="dateFrom"
                @change="applyFilters"
                class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
              />
            </div>
            <div class="flex-1 min-w-[200px]">
              <label for="dateTo" class="block text-sm font-medium text-gray-700 mb-1">Date To</label>
              <input
                type="date"
                id="dateTo"
                v-model="dateTo"
                @change="applyFilters"
                class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
              />
            </div>
            <div class="flex-1 min-w-[200px]">
              <label for="session" class="block text-sm font-medium text-gray-700 mb-1">Session</label>
              <select
                id="session"
                v-model="selectedSession"
                @change="applyFilters"
                class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
              >
                <option value="">--Select Session--</option>
                <option value="2023/2024">2023/2024</option>
                <option value="2024/2025">2024/2025</option>
                <option value="2025/2026">2025/2026</option>
              </select>
            </div>
            <div class="flex-1 min-w-[200px]">
              <label for="semester" class="block text-sm font-medium text-gray-700 mb-1">Semester</label>
              <select
                id="semester"
                v-model="selectedSemester"
                @change="applyFilters"
                class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
              >
                <option value="">--Select Semester--</option>
                <option value="Semester 1">Semester 1</option>
                <option value="Semester 2">Semester 2</option>
                <option value="Semester 3">Semester 3</option>
              </select>
            </div>
          </div>
        </div>

        <!-- Results Table -->
        <div class="search-results overflow-x-auto bg-white shadow rounded-lg mt-4">
          <DataTable v-if="filteredFiles.length > 0" :value="filteredFiles" class="p-datatable-striped">
            <Column field="name" header="Name"></Column>
            <Column field="category_name" header="Category"></Column>
            <Column field="date_created" header="Date Added" :sortable="true"></Column>
            <Column field="session" header="Session"></Column>
            <Column field="semester" header="Semester"></Column>
            <Column header="Actions">
              <template #body="{ data }">
                <Button
                  icon="pi pi-share-alt"
                  class="p-button-rounded p-button-success"
                  @click="openShareDialog(data)"
                />
              </template>
            </Column>
          </DataTable>
          <div
            v-else
            class="mt-5 bg-white border border-red-500 text-center p-4 rounded-lg shadow flex items-center justify-center"
          >
            <i class="pi pi-exclamation-circle text-red-500 mr-2"></i>
            <span class="text-gray-500 italic">No resources found.</span>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Share Dialog -->
  <Dialog
    v-model:visible="showShareDialog"
    header="Share Resource"
    :style="{ width: '35rem' }"
    modal
  >
    <h3 class="text-lg mb-4">Share: {{ resourceToShare ? resourceToShare.name : '' }}</h3>
    <div class="mb-4">
      <label class="block text-sm font-medium mb-2">Select Users</label>
      <MultiSelect
                            id="users"
                            v-model="selectedUsers"
                            :options="users"
                            optionLabel="email"
                            optionValue="user_id"
                            placeholder="Select Users to Share With"
                            display="chip"
                            class="flex-auto"
                            filter
                            :maxSelectedLabels="1"
                        />
    </div>
    <div class="mb-4">
      <label class="block text-sm font-medium mb-2">Select Groups</label>
      <MultiSelect
        v-model="selectedGroups"
        :options="groups"
        optionLabel="name"
        optionValue="id"
        placeholder="Select groups"
        class="w-full"
      />
    </div>
    <div class="flex justify-end gap-2">
      <Button label="Cancel" class="p-button-secondary" @click="showShareDialog = false" />
      <Button label="Share" class="p-button-primary" @click="shareResource" />
    </div>
  </Dialog>
</template>
