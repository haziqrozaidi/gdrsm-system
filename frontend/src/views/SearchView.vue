<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import { useToast } from 'primevue/usetoast';
import debounce from 'lodash/debounce'; // Ensure lodash debounce is available

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
const selectedSemester = ref('');

const debouncedApplyFilters = debounce(applyFilters, 300);

// Re-compute categories for searching
const filteredCategories = computed(() => {
    return categories.value.filter(category =>
        category.name.toLowerCase().includes(categorySearch.value.toLowerCase())
    );
});

const apiBaseURL = 'http://127.0.0.1:3000/api';

async function fetchResources() {
    try {
        const response = await fetch(`${apiBaseURL}/resources`, { method: 'GET', credentials: 'include', headers: { 'Content-Type': 'application/json' } });
        if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);
        resources.value = await response.json();
        debouncedApplyFilters();
    } catch (error) {
        console.error("Failed to fetch resources:", error);
        toast.add({ severity: 'error', summary: 'Fetch Failed', detail: error.message, life: 3000 });
    }
}

async function fetchCategories() {
    try {
        const response = await fetch(`${apiBaseURL}/categories`, { method: 'GET', credentials: 'include', headers: { 'Content-Type': 'application/json' } });
        if (!response.ok) throw new Error('Failed to fetch categories');
        categories.value = await response.json();
    } catch (error) {
        console.error('Error fetching categories:', error);
        toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to load categories', life: 3000 });
    }
}

onMounted(() => {
    fetchResources();
    fetchCategories();
});

function applyFilters() {
    let result = resources.value;
    if (searchTerm.value) {
        result = result.filter(file => file.name.toLowerCase().includes(searchTerm.value.toLowerCase()));
    }
    if (selectedCategory.value) {
        result = result.filter(file => file.category_id === selectedCategory.value.category_id);
    }
    if (dateFrom.value && dateTo.value) {
        result = result.filter(file => new Date(file.date_created) >= new Date(dateFrom.value) && new Date(file.date_created) <= new Date(dateTo.value));
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

watch(searchTerm, debouncedApplyFilters);

const toggleDropdown = () => {
    isDropdownOpen.value = !isDropdownOpen.value;
};

const selectCategory = (category) => {
    selectedCategory.value = category;
    isDropdownOpen.value = false;
    debouncedApplyFilters();
};

</script>

<template>
    <div class="flex flex-col p-5 gap-2.5">
        <!-- Search Bar with Category Dropdown -->
        <div class="flex items-center gap-2.5 bg-gray-100 p-2.5 rounded-lg">
            <div class="relative flex-grow">
                <i class="pi pi-search absolute left-2.5 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                <input type="text" v-model="searchTerm" placeholder="Search files..."
                    class="pl-10 pr-2.5 py-2.5 w-full border border-gray-300 rounded-lg text-sm">
            </div>
            <div class="relative">
                <button @click="toggleDropdown"
                    class="bg-white border border-gray-300 text-black px-2.5 py-2 rounded-lg flex items-center gap-2">
                    {{ selectedCategory?.name || "All Categories" }}
                    <i class="pi pi-chevron-down"></i>
                </button>
                <div v-if="isDropdownOpen"
                    class="absolute w-64 mt-1 bg-white border border-gray-300 rounded-lg overflow-auto max-h-72 z-10">
                    <input type="text" v-model="categorySearch" placeholder="Search categories..."
                        class="w-full border-b border-gray-300 p-2">
                    <ul class="list-none m-0 p-0">
                        <li v-for="category in filteredCategories" :key="category.category_id"
                            @click="selectCategory(category)"
                            class="flex items-center p-2 cursor-pointer hover:bg-gray-100">
                            {{ category.name }}
                        </li>
                    </ul>
                </div>
            </div>
            <button @click="performSearch" class="bg-black text-white px-5 py-2.5 rounded-lg cursor-pointer text-sm">
                Search
            </button>
        </div>

        <!-- Filters -->
        <div class="filters flex flex-wrap gap-4 bg-white p-4 rounded-lg shadow">
            <!-- Date From -->
            <div class="flex-1 min-w-[200px]">
                <label for="dateFrom" class="block text-sm font-medium text-gray-700 mb-1">Date From</label>
                <input type="date" id="dateFrom" v-model="dateFrom" @change="applyFilters"
                    class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
            </div>

            <!-- Date To -->
            <div class="flex-1 min-w-[200px]">
                <label for="dateTo" class="block text-sm font-medium text-gray-700 mb-1">Date To</label>
                <input type="date" id="dateTo" v-model="dateTo" @change="applyFilters"
                    class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
            </div>

            <!-- Shared By -->
            <div class="flex-1 min-w-[200px]">
                <label for="sharedBy" class="block text-sm font-medium text-gray-700 mb-1">Shared By</label>
                <input type="text" id="sharedBy" v-model="sharedBy" @input="applyFilters"
                    class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
                    placeholder="Enter username">
            </div>

            <!-- Session -->
            <div class="flex-1 min-w-[200px]">
                <label for="session" class="block text-sm font-medium text-gray-700 mb-1">Session</label>
                <select id="session" v-model="selectedSession" @change="applyFilters"
                    class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none">
                    <option value="">--Select Session--</option>
                    <option value="2023/2024">2023/2024</option>
                    <option value="2024/2025">2024/2025</option>
                    <option value="2025/2026">2025/2026</option>
                </select>
            </div>

            <!-- Semester -->
            <div class="flex-1 min-w-[200px]">
                <label for="semester" class="block text-sm font-medium text-gray-700 mb-1">Semester</label>
                <select id="semester" v-model="selectedSemester" @change="applyFilters"
                    class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none">
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
            <Column field="type" header="Type"></Column>
            <Column field="date_created" header="Date Added" :sortable="true"></Column>
            <Column field="session" header="Session"></Column>
            <Column field="semester" header="Semester"></Column>
            <Column header="Actions">
                <template #body="slotProps">
                    <Button icon="pi pi-download" class="p-button-rounded p-button-info"
                        @click="downloadResource(slotProps.data)" />
                    <Button icon="pi pi-share-alt" class="p-button-rounded p-button-success"
                        @click="shareResource(slotProps.data)" />
                </template>
            </Column>
        </DataTable>
        <div v-else
            class="mt-5 bg-white border border-red-500 text-center p-4 rounded-lg shadow flex items-center justify-center">
            <i class="pi pi-exclamation-circle text-red-500 mr-2"></i>
            <span class="text-gray-500 italic">No resources found.</span>
        </div>
    </div>
</template>
