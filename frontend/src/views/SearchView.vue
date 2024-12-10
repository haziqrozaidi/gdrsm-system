<template>
    <div class="search-container"> 
      <div class="search-upload">
        <button class="btn upload-btn">Upload ▼</button>
        <input type="text" v-model="searchTerm" placeholder="Search files..." class="search-input">
        <button @click="performSearch" class="btn search-btn">🔍</button>
      </div>
  
      <div class="filters">
        <div class="filter">
          <label for="category-select" class="filter-label">Category</label>
          <select id="category-select" v-model="selectedCategory" class="filter-select">
            <option value="">All Categories</option>
            <option value="documents">Documents</option>
            <option value="images">Images</option>
            <option value="videos">Videos</option>
          </select>
        </div>
  
        <div class="filter">
          <label for="fileType" class="filter-label">File Type</label>
          <select id="fileType" v-model="selectedFileType" class="filter-select">
            <option value="">--Select type--</option>
            <option value=".pdf">PDF</option>
            <option value=".jpg">JPG</option>
            <option value=".png">PNG</option>
          </select>
        </div>
  
        <div class="filter-item">
          <label for="fileWeightFrom">File Weight From</label>
          <div class="input-group">
            <input type="number" id="fileWeightFrom" v-model="fileWeightFrom" placeholder="Weight" class="input-field" />
            <select v-model="weightUnitFrom" class="select-field">
              <option value="kg">Kg</option>
              <option value="lbs">Lbs</option>
            </select>
            <span class="to-label">To</span>
            <input type="number" id="fileWeightTo" v-model="fileWeightTo" placeholder="Weight" class="input-field" />
            <select v-model="weightUnitTo" class="select-field">
              <option value="kg">Kg</option>
              <option value="lbs">Lbs</option>
            </select>
          </div>
        </div>
  
        <div class="date-filter">
          <label class="filter-label">Creation Date From</label>
          <input type="date" v-model="dateFrom" class="filter-input">
          <label class="filter-label">To</label>
          <input type="date" v-model="dateTo" class="filter-input">
        </div>
  
        <div class="file-card-container">
          <div class="file-card" v-for="file in files" :key="file.name">
            <div class="file-icon">
              <img :src="getFileIcon(file.type)" alt="File Icon">
            </div>
            <div class="file-details">
              <h3>{{ file.name }}</h3>
              <p>Size: {{ file.size }}</p>
              <p>Hits: {{ file.hits }}</p>
              <p>Date added: {{ file.dateAdded }}</p>
            </div>
            <div class="file-actions">
              <button class="download-btn">Download</button>
              <button class="preview-btn">Preview</button>
            </div>
          </div>
        </div>
      </div>
    </div>

  </template>
  
  <script>
  export default {
    data() {
      return {
        searchTerm: '',
        selectedCategory: '',
        selectedFileType: '',
        fileWeightFrom: '',
        weightUnitFrom: 'kg',
        fileWeightTo: '',
        weightUnitTo: 'kg',
        dateFrom: '',
        dateTo: '',
        files: [
          { name: 'My resume', type: 'docx', size: '1.45 MB', hits: 803, dateAdded: '04-02-2021' },
          { name: 'Lesson proposal', type: 'pdf', size: '1.45 MB', hits: 803, dateAdded: '04-02-2021' },
          { name: 'Portrait image', type: 'jpg', size: '314.50 KB', hits: 222, dateAdded: '04-02-2021' },
          { name: 'Excel Sheet', type: 'xlsx', size: '314.50 KB', hits: 222, dateAdded: '04-02-2021' }
        ]
      };
    },
    methods: {
      performSearch() {
        console.log('Performing search with:', this.searchTerm, this.selectedCategory, this.selectedFileType, this.fileWeightFrom, this.weightUnitFrom, this.fileWeightTo, this.weightUnitTo, this.dateFrom, this.dateTo);
      },
      getFileIcon(type) {
        switch (type) {
          case 'docx': return 'path/to/docx-icon.png';
          case 'pdf': return 'path/to/pdf-icon.png';
          case 'jpg': return 'path/to/jpg-icon.png';
          case 'xlsx': return 'path/to/xlsx-icon.png';
          default: return 'path/to/default-icon.png';
        }
      }
    }
  }

  </script>
  
  <style scoped>
  .search-container {
    display: flex;
    flex-direction: column;
    padding: 20px;
    background-color: #f4f4f4;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }
  
  .search-upload {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 20px;
  }
  
  .btn {
    background-color: #007BFF;
    color: white;
    padding: 8px 16px;
    border: none;
    cursor: pointer;
    border-radius: 4px;
  }
  
  .search-input, .filter-input, .input-field, .select-field {
    padding: 8px;
    border: 2px solid #ccc;
    border-radius: 4px;
    flex-grow: 1;
  }
  
  .filter, .filter-item {
    display: flex;
    flex-direction: column;
    margin-bottom: 10px;
  }
  
  .filter-label, .to-label {
    margin-bottom: 5px;
  }
  
  .input-group {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  
  .date-filter {
    display: flex;
    gap: 10px;
    align-items: center;
  }

  .file-card-container {
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
  }
  
  .file-card {
    background-color: #f3f4f8;
    border-radius: 8px;
    padding: 15px;
    box-shadow: 0 4px 8px rgba(0,0,0,0.1);
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
  
  .file-icon img {
    width: 50px; /* Adjust size accordingly */
  }
  
  .file-details h3 {
    margin: 0;
    color: #333;
  }
  
  .file-details p {
    margin: 5px 0;
    color: #666;
  }

  .file-card:hover {
  transform: scale(1.05);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
}
  
  .download-btn, .preview-btn {
    background-color: #007bff;
    color: white;
    border: none;
    padding: 10px 15px;
    border-radius: 5px;
    cursor: pointer;
  }
  
  .download-btn:hover, .preview-btn:hover {
    background-color: #0056b3;
  }
  
  .file-actions {
    display: flex;
    gap: 10px;
  }
  </style>