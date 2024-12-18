<template>
  <div class="search-container">
    <!-- Search Bar with Category Dropdown -->
    <div class="search-bar">
      <div class="search-input-wrapper">
        <i class="pi pi-search search-icon"></i>
        <input type="text" v-model="searchTerm" placeholder="Search files..." class="search-input" />
      </div>
      <div class="category-dropdown">
        <button @click="toggleDropdown" class="category-button">
          {{ selectedCategory?.label || "All Categories" }}
          <i class="pi pi-chevron-down"></i>
        </button>
        <div v-if="isDropdownOpen" class="dropdown-menu">
          <input type="text" v-model="categorySearch" placeholder="Search categories..." class="category-search" />
          <ul class="category-list">
            <li v-for="node in filteredCategories" :key="node.id">
              <div class="category-node" @click="toggleCategory(node)">
                <span v-if="node.children && node.children.length">
                  {{ isExpanded(node.id) ? "▼" : "▶" }}
                </span>
                <span v-else style="visibility: hidden;">▶</span>
                <span :class="{ 'selected-category': selectedCategory?.id === node.id }"
                  @click.stop="selectCategory(node)">
                  <i class="pi pi-folder"></i> {{ node.label }}
                </span>
              </div>
              <ul v-if="isExpanded(node.id)" class="sub-category-list">
                <li v-for="child in node.children" :key="child.id" @click.stop="selectCategory(child)"
                  class="category-child">
                  <i class="pi pi-folder"></i> {{ child.label }}
                </li>
              </ul>
            </li>
          </ul>
        </div>
      </div>
      <button @click="performSearch" class="btn search-btn">Search</button>
    </div>


    <!-- Filters -->
    <div class="filters flex flex-wrap gap-4 bg-white p-4 rounded-lg shadow">
      <!-- File Type -->
      <div class="flex-1 min-w-[200px]">
        <label for="fileType" class="block text-sm font-medium text-gray-700 mb-1">File Type</label>
        <select id="fileType" v-model="selectedFileType"
          class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none">
          <option value="">--Select type--</option>
          <option value=".pdf">PDF</option>
          <option value=".txt">TXT</option>
          <option value=".doc">DOC</option>
          <option value=".xls">XLS</option>
          <option value=".ppt">PPT</option>
          <option value=".jpg">JPG</option>
          <option value=".png">PNG</option>
          <option value=".mp3">MP3</option>
          <option value=".mov">MOV</option>
          <option value=".zip">ZIP</option>
        </select>
      </div>

      <!-- Date From -->
      <div class="flex-1 min-w-[200px]">
        <label for="dateFrom" class="block text-sm font-medium text-gray-700 mb-1">Date From</label>
        <input type="date" id="dateFrom" v-model="dateFrom"
          class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
      </div>

      <!-- Date To -->
      <div class="flex-1 min-w-[200px]">
        <label for="dateTo" class="block text-sm font-medium text-gray-700 mb-1">Date To</label>
        <input type="date" id="dateTo" v-model="dateTo"
          class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
      </div>

      <!-- Session -->
      <div class="flex-1 min-w-[200px]">
        <label for="session" class="block text-sm font-medium text-gray-700 mb-1">Session</label>
        <select id="session" v-model="selectedSession"
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
        <select id="semester" v-model="selectedSemester"
          class="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none">
          <option value="">--Select Semester--</option>
          <option value="Semester 1">Semester 1</option>
          <option value="Semester 2">Semester 2</option>
          <option value="Semester 3">Semester 3</option>
        </select>
      </div>
    </div>

    <!-- Results Table -->
    <div class="search-results overflow-x-auto bg-white shadow rounded-lg">
      <table class="w-full border-collapse text-sm border border-gray-300">
        <thead>
          <tr class="bg-gray-100 text-gray-700 uppercase text-left">
            <th class="p-3 border border-gray-300">Name</th>
            <th class="p-3 border border-gray-300">Folder</th>
            <th class="p-3 border border-gray-300">Date</th>
            <th class="p-3 border border-gray-300">File Size</th>
            <th class="p-3 border border-gray-300">Session</th>
            <th class="p-3 border border-gray-300">Semester</th>
            <th class="p-3 border border-gray-300">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="file in filteredFiles" :key="file.name" class="hover:bg-gray-50">
            <td class="p-3 border border-gray-300">{{ file.name }}</td>
            <td class="p-3 border border-gray-300">{{ file.folder }}</td>
            <td class="p-3 border border-gray-300">{{ file.dateAdded }}</td>
            <td class="p-3 border border-gray-300">{{ file.size }}</td>
            <td class="p-3 border border-gray-300">{{ file.session }}</td>
            <td class="p-3 border border-gray-300">{{ file.semester }}</td>
            <td class="p-3 border border-gray-300">
              <!-- Action Buttons -->
              <div class="flex space-x-4">
                <button
                  class="bg-blue-500 text-white px-4 py-2 rounded-lg shadow hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition duration-150">
                  Share
                </button>
                <button
                  class="bg-green-500 text-white px-4 py-2 rounded-lg shadow hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition duration-150">
                  Download
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      searchTerm: "",
      categorySearch: "",
      selectedFileType: "",
      selectedSession: "",
      selectedSemester: "",
      selectedCategory: null,
      expandedNodes: [],
      isDropdownOpen: false,
      folderTree: [
        {
          id: 1,
          label: "All Categories",
          children: [
            {
              id: 2,
              label: "WooCommerce files",
              children: [
                {
                  id: 3,
                  label: "Sub-category 1",
                  children: [
                    {
                      id: 4,
                      label: "Sub sub category",
                      children: [
                        { id: 5, label: "Invoice23124.pdf" },
                        { id: 6, label: "ProductList.xls" },
                      ],
                    },
                    { id: 7, label: "SalesReport.doc" },
                  ],
                },
              ],
            },
            {
              id: 8,
              label: "Default theme category",
              children: [
                { id: 9, label: "receipt.txt" },
                { id: 10, label: "theme.png" },
                { id: 11, label: "instructions.pdf" },
                {
                  id: 12,
                  label: "Sub-category 1",
                  children: [
                    { id: 13, label: "contract.doc" },
                    { id: 14, label: "design.jpg" },
                    {
                      id: 15,
                      label: "Sub sub category",
                      children: [
                        { id: 16, label: "notes.txt" },
                        { id: 17, label: "logo.png" },
                      ],
                    },
                  ],
                },
                { id: 18, label: "Sub category 2" },
              ],
            },
            {
              id: 19,
              label: "Backups",
              children: [{ id: 20, label: "backup.zip" }],
            },
            {
              id: 21,
              label: "Media",
              children: [
                {
                  id: 22,
                  label: "Audio Files",
                  children: [{ id: 23, label: "audio.mp3" }],
                },
                {
                  id: 24,
                  label: "Video Files",
                  children: [{ id: 25, label: "video.mov" }],
                },
                {
                  id: 26,
                  label: "Archives",
                  children: [{ id: 27, label: "archive.zip" }],
                },
              ],
            },
          ],
        },
      ],

      selectedFileType: "",
      dateFrom: "",
      dateTo: "",
      files: [
        // WooCommerce Files
        {
          name: "Invoice23124.pdf",
          folder: "WooCommerce files",
          dateAdded: "2023-01-15",
          size: "450 KB",
          session: "2023/2024",
          semester: "Semester 1"
        },
        {
          name: "ProductList.xls",
          folder: "WooCommerce files",
          dateAdded: "2023-02-10",
          size: "1.5 MB",
          session: "2023/2024",
          semester: "Semester 2"
        },
        {
          name: "SalesReport.doc",
          folder: "WooCommerce files",
          dateAdded: "2023-03-12",
          size: "800 KB",
          session: "2023/2024",
          semester: "Semester 3"
        },

        // Default Theme Category
        {
          name: "receipt.txt",
          folder: "Default theme category",
          dateAdded: "2024-02-17",
          size: "25 KB",
          session: "2024/2025",
          semester: "Semester 1"
        },
        {
          name: "theme.png",
          folder: "Default theme category",
          dateAdded: "2024-03-05",
          size: "2.5 MB",
          session: "2024/2025",
          semester: "Semester 2"
        },
        {
          name: "instructions.pdf",
          folder: "Default theme category",
          dateAdded: "2024-01-28",
          size: "900 KB",
          session: "2024/2025",
          semester: "Semester 3"
        },

        // Sub-Category Files
        {
          name: "contract.doc",
          folder: "Default theme category > Sub-category 1",
          dateAdded: "2025-02-01",
          size: "20.5 MB",
          session: "2025/2026",
          semester: "Semester 1"
        },
        {
          name: "design.jpg",
          folder: "Default theme category > Sub-category 1",
          dateAdded: "2025-03-09",
          size: "5 MB",
          session: "2025/2026",
          semester: "Semester 2"
        },

        // Sub-Sub-Category Files
        {
          name: "notes.txt",
          folder: "Default theme category > Sub-category 1 > Sub sub category",
          dateAdded: "2025-02-20",
          size: "15 KB",
          session: "2025/2026",
          semester: "Semester 3"
        },
        {
          name: "logo.png",
          folder: "Default theme category > Sub-category 1 > Sub sub category",
          dateAdded: "2025-03-20",
          size: "3.2 MB",
          session: "2025/2026",
          semester: "Semester 1"
        },

        // Additional Files in Another Folder
        {
          name: "backup.zip",
          folder: "Backups",
          dateAdded: "2025-03-18",
          size: "1.2 GB",
          session: "2025/2026",
          semester: "Semester 2"
        },
        {
          name: "audio.mp3",
          folder: "Media > Audio Files",
          dateAdded: "2024-02-25",
          size: "9 MB",
          session: "2024/2025",
          semester: "Semester 3"
        },
        {
          name: "video.mov",
          folder: "Media > Video Files",
          dateAdded: "2024-02-15",
          size: "1.5 GB",
          session: "2024/2025",
          semester: "Semester 1"
        },
        {
          name: "archive.zip",
          folder: "Media > Archives",
          dateAdded: "2024-03-01",
          size: "500 MB",
          session: "2024/2025",
          semester: "Semester 2"
        },
      ],
    };
  },
  computed: {
    filteredCategories() {
      const filterTree = (nodes, searchTerm) => {
        return nodes
          .map((node) => {
            const matches =
              node.label.toLowerCase().includes(searchTerm.toLowerCase());
            const filteredChildren = node.children
              ? filterTree(node.children, searchTerm)
              : [];

            // Include the node if it matches or if any of its children match
            if (matches || filteredChildren.length) {
              return {
                ...node,
                children: filteredChildren,
              };
            }

            // Otherwise, exclude the node
            return null;
          })
          .filter(Boolean); // Remove null entries
      };

      return this.categorySearch
        ? filterTree(this.folderTree, this.categorySearch)
        : this.folderTree;
    },
    filteredFiles() {
      return this.files.filter((file) => {
        const categoryMatch =
          !this.selectedCategory || this.selectedCategory.label === "All Categories" || file.folder.includes(this.selectedCategory.label);
        const searchMatch = !this.searchTerm || file.name.toLowerCase().includes(this.searchTerm.toLowerCase());
        const dateMatch =
          (!this.dateFrom || new Date(file.dateAdded) >= new Date(this.dateFrom)) &&
          (!this.dateTo || new Date(file.dateAdded) <= new Date(this.dateTo));
        const fileTypeMatch = !this.selectedFileType || file.name.endsWith(this.selectedFileType);
        const sessionMatch = !this.selectedSession || file.session === this.selectedSession;
        const semesterMatch = !this.selectedSemester || file.semester === this.selectedSemester;


        return categoryMatch && searchMatch && dateMatch && fileTypeMatch && sessionMatch && semesterMatch;
      });
    },
  },
  methods: {
    toggleDropdown() {
      this.isDropdownOpen = !this.isDropdownOpen;
    },
    toggleCategory(node) {
      const index = this.expandedNodes.indexOf(node.id);
      if (index > -1) {
        this.expandedNodes.splice(index, 1);
      } else {
        this.expandedNodes.push(node.id);
      }
    },
    isExpanded(nodeId) {
      return this.expandedNodes.includes(nodeId);
    },
    selectCategory(node) {
      this.selectedCategory = node;
      this.isDropdownOpen = false; // Close dropdown after selection
      console.log("Selected category:", this.selectedCategory.label);
    },

    performSearch() {
      console.log("Selected category:", this.selectedCategory);
      console.log("Search term:", this.searchTerm);
    },
  },
};
</script>

<style scoped>
.search-container {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 20px;
}

.btn.search-btn {
  background-color: black;
  color: white;
  padding: 10px 20px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 14px;
}

.search-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  background-color: #f4f4f4;
  padding: 10px;
  border-radius: 5px;
}

.search-input-wrapper {
  flex-grow: 1;
  position: relative;
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #888;
}

.search-input {
  padding: 10px 10px 10px 30px;
  width: 100%;
  border: 1px solid #ccc;
  border-radius: 5px;
  font-size: 14px;
}


.category-dropdown {
  flex-grow: 0;
}

.input-group {
  display: flex;
  align-items: center;
  gap: 5px;
}

.category-dropdown {
  position: relative;
}

.category-button {
  background: white;
  border: 1px solid #ccc;
  border-radius: 5px;
  padding: 10px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 200px;
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  width: 250px;
  max-height: 300px;
  overflow-y: auto;
  border: 1px solid #ccc;
  border-radius: 5px;
  background: white;
  z-index: 1000;
}

.category-search {
  padding: 8px;
  width: 100%;
  border: 1px solid #ccc;
  border-bottom: none;
}

.category-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.category-node {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 5px;
}

.sub-category-list {
  padding-left: 20px;
}

.category-child {
  padding: 5px 0;
  cursor: pointer;
}

.category-child:hover,
.category-node:hover {
  background-color: #f0f0f0;
}

.selected-category {
  font-weight: bold;
  color: #007bff;
}
</style>