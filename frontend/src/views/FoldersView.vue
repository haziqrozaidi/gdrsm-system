<script setup>
    import { ref, reactive, computed } from 'vue'
    import InputText from 'primevue/inputtext'
    import Dialog from 'primevue/dialog'
    import { useToast } from 'primevue/usetoast'
    import Sidebar from '../components/Sidebar.vue'
    import Button from 'primevue/button'
    import Card from 'primevue/card'
    import Toast from 'primevue/toast'

    // Toast service
    const toast = useToast()

    // File type icons mapping
    const fileIcons = {
        pdf: 'pi-file-pdf',
        doc: 'pi-file-word',
        docx: 'pi-file-word',
        xls: 'pi-file-excel',
        xlsx: 'pi-file-excel',
        jpg: 'pi-image',
        jpeg: 'pi-image',
        png: 'pi-image',
        txt: 'pi-file',
        default: 'pi-file'
    }

    // Reactive state for folders
    const folders = ref([
        {
            id: 1,
            name: 'Project Documents',
            description: 'Important project-related files',
            fileCount: 3,
            lastUpdated: '2023-06-15',
            files: [
                { 
                    id: 1, 
                    name: 'Project_Proposal.pdf', 
                    type: 'pdf', 
                    size: '2.5 MB', 
                    uploaded: '2023-06-10' 
                },
                { 
                    id: 2, 
                    name: 'Budget_Breakdown.xlsx', 
                    type: 'xlsx', 
                    size: '1.2 MB', 
                    uploaded: '2023-06-12' 
                },
                { 
                    id: 3, 
                    name: 'Meeting_Notes.docx', 
                    type: 'docx', 
                    size: '0.5 MB', 
                    uploaded: '2023-06-15' 
                }
            ]
        },
        {
            id: 2,
            name: 'Research Papers',
            description: 'Academic research documents',
            fileCount: 2,
            lastUpdated: '2023-06-10',
            files: [
                { 
                    id: 1, 
                    name: 'Literature_Review.pdf', 
                    type: 'pdf', 
                    size: '3.7 MB', 
                    uploaded: '2023-06-05' 
                },
                { 
                    id: 2, 
                    name: 'Research_Methodology.docx', 
                    type: 'docx', 
                    size: '1.8 MB', 
                    uploaded: '2023-06-10' 
                }
            ]
        },
        {
            id: 3,
            name: 'Financial Reports',
            description: 'Quarterly and annual financial documents',
            fileCount: 4,
            lastUpdated: '2023-06-20',
            files: [
                { 
                    id: 1, 
                    name: 'Q2_Financial_Report.xlsx', 
                    type: 'xlsx', 
                    size: '2.3 MB', 
                    uploaded: '2023-06-18' 
                },
                { 
                    id: 2, 
                    name: 'Annual_Budget_Summary.pdf', 
                    type: 'pdf', 
                    size: '4.1 MB', 
                    uploaded: '2023-06-20' 
                },
                { 
                    id: 3, 
                    name: 'Expense_Tracker.xlsx', 
                    type: 'xlsx', 
                    size: '1.5 MB', 
                    uploaded: '2023-06-15' 
                },
                { 
                    id: 4, 
                    name: 'Investment_Strategy.docx', 
                    type: 'docx', 
                    size: '0.9 MB', 
                    uploaded: '2023-06-12' 
                }
            ]
        },
        {
            id: 4,
            name: 'Marketing Materials',
            description: 'Branding and promotional content',
            fileCount: 3,
            lastUpdated: '2023-06-25',
            files: [
                { 
                    id: 1, 
                    name: 'Brand_Guidelines.pdf', 
                    type: 'pdf', 
                    size: '5.2 MB', 
                    uploaded: '2023-06-22' 
                },
                { 
                    id: 2, 
                    name: 'Social_Media_Designs.jpg', 
                    type: 'jpg', 
                    size: '3.6 MB', 
                    uploaded: '2023-06-24' 
                },
                { 
                    id: 3, 
                    name: 'Marketing_Campaign_Plan.docx', 
                    type: 'docx', 
                    size: '1.1 MB', 
                    uploaded: '2023-06-25' 
                }
            ]
        },
        {
            id: 5,
            name: 'Human Resources',
            description: 'Employee records and HR documents',
            fileCount: 5,
            lastUpdated: '2023-06-22',
            files: [
                { 
                    id: 1, 
                    name: 'Employee_Handbook.pdf', 
                    type: 'pdf', 
                    size: '3.9 MB', 
                    uploaded: '2023-06-20' 
                },
                { 
                    id: 2, 
                    name: 'Performance_Review_Template.docx', 
                    type: 'docx', 
                    size: '0.7 MB', 
                    uploaded: '2023-06-21' 
                },
                { 
                    id: 3, 
                    name: 'Recruitment_Policy.pdf', 
                    type: 'pdf', 
                    size: '2.1 MB', 
                    uploaded: '2023-06-22' 
                },
                { 
                    id: 4, 
                    name: 'Training_Schedule.xlsx', 
                    type: 'xlsx', 
                    size: '1.4 MB', 
                    uploaded: '2023-06-18' 
                },
                { 
                    id: 5, 
                    name: 'Compensation_Structure.docx', 
                    type: 'docx', 
                    size: '1.2 MB', 
                    uploaded: '2023-06-15' 
                }
            ]
        },
        {
            id: 6,
            name: 'IT Infrastructure',
            description: 'Technical documentation and network diagrams',
            fileCount: 4,
            lastUpdated: '2023-06-23',
            files: [
                { 
                    id: 1, 
                    name: 'Network_Topology.pdf', 
                    type: 'pdf', 
                    size: '4.5 MB', 
                    uploaded: '2023-06-21' 
                },
                { 
                    id: 2, 
                    name: 'Server_Configuration.docx', 
                    type: 'docx', 
                    size: '2.2 MB', 
                    uploaded: '2023-06-22' 
                },
                { 
                    id: 3, 
                    name: 'Security_Protocols.pdf', 
                    type: 'pdf', 
                    size: '3.3 MB', 
                    uploaded: '2023-06-23' 
                },
                { 
                    id: 4, 
                    name: 'Backup_Schedule.xlsx', 
                    type: 'xlsx', 
                    size: '0.6 MB', 
                    uploaded: '2023-06-20' 
                }
            ]
        }
    ])

    // State for dialogs and forms
    const state = reactive({
        newFolder: {
            name: '',
            description: ''
        },
        editFolder: {
            id: null,
            name: '',
            description: ''
        },
        selectedFolder: null,
        dialogs: {
            newFolder: false,
            editFolder: false,
            folderContent: false
        },
        errors: {
            folderName: ''
        }
    })

    // Computed properties
    const sortedFolders = computed(() => {
        return [...folders.value].sort((a, b) => 
            new Date(b.lastUpdated) - new Date(a.lastUpdated)
        )
    })

    // Utility Functions
    const generateUniqueId = () => {
        return folders.value.length > 0 
            ? Math.max(...folders.value.map(f => f.id)) + 1 
            : 1
    }

    const getCurrentDate = () => {
        return new Date().toISOString().split('T')[0]
    }

    // Validation Functions
    const validateFolderName = (name) => {
        if (!name || name.trim() === '') {
            return 'Folder name is required'
        }
        
        const isDuplicate = folders.value.some(
            folder => folder.name.toLowerCase() === name.toLowerCase()
        )
        
        return isDuplicate ? 'A folder with this name already exists' : ''
    }

    // Folder Operations
    const openNewFolderDialog = () => {
        state.newFolder = { name: '', description: '' }
        state.errors.folderName = ''
        state.dialogs.newFolder = true
    }

    const createFolder = () => {
        const nameError = validateFolderName(state.newFolder.name)
        
        if (nameError) {
            state.errors.folderName = nameError
            return
        }

        const newFolder = {
            id: generateUniqueId(),
            name: state.newFolder.name,
            description: state.newFolder.description,
            fileCount: 0,
            lastUpdated: getCurrentDate(),
            files: []
        }

        folders.value.push(newFolder)
        
        toast.add({
            severity: 'success',
            summary: 'Folder Created',
            detail: `Folder "${newFolder.name}" has been created`,
            life: 3000
        })

        state.dialogs.newFolder = false
    }

    const editFolderAction = (folder) => {
        state.editFolder = { 
            id: folder.id, 
            name: folder.name, 
            description: folder.description || '' 
        }
        state.dialogs.editFolder = true
    }

    const updateFolder = () => {
        const nameError = validateFolderName(state.editFolder.name)
        
        if (nameError && nameError !== 'A folder with this name already exists') {
            state.errors.folderName = nameError
            return
        }

        const folderIndex = folders.value.findIndex(f => f.id === state.editFolder.id)
        
        if (folderIndex !== -1) {
            folders.value[folderIndex].name = state.editFolder.name
            folders.value[folderIndex].description = state.editFolder.description
            folders.value[folderIndex].lastUpdated = getCurrentDate()

            toast.add({
                severity: 'success',
                summary: 'Folder Updated',
                detail: `Folder updated successfully`,
                life: 3000
            })

            state.dialogs.editFolder = false
        }
    }

    const deleteFolder = (folder) => {
        folders.value = folders.value.filter(f => f.id !== folder.id)
        
        toast.add({
            severity: 'warn',
            summary: 'Folder Deleted',
            detail: `Folder "${folder.name}" has been deleted`,
            life: 3000
        })
    }

    const viewFolderContent = (folder) => {
        state.selectedFolder = folder
        state.dialogs.folderContent = true
    }

    const getFileIcon = (fileType) => {
        return fileIcons[fileType.toLowerCase()] || fileIcons.default
    }

    const downloadFile = (file) => {
        toast.add({
            severity: 'info',
            summary: 'Download',
            detail: `Downloading ${file.name}`,
            life: 3000
        })
    }

    const deleteFile = (folder, file) => {
        if (state.selectedFolder) {
            state.selectedFolder.files = state.selectedFolder.files.filter(f => f.id !== file.id)
            state.selectedFolder.fileCount--

            toast.add({
                severity: 'warn',
                summary: 'File Deleted',
                detail: `${file.name} has been deleted`,
                life: 3000
            })
        }
    }
</script>

<template>
    <div class="flex min-h-screen">
        <Sidebar />
        <div class="grow bg-gray-100 p-4">
            <div class="container mx-auto">
                <!-- Header -->
                <div class="mb-6 flex justify-between items-center">
                    <h1 class="text-2xl font-bold text-gray-800">My Folders</h1>
                    <Button 
                        label="Create New Folder" 
                        icon="pi pi-plus" 
                        class="p-button-primary"
                        @click="openNewFolderDialog"
                    />
                </div>

                <!-- Folders Grid -->
                <div v-if="sortedFolders.length" class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <Card 
                        v-for="folder in sortedFolders" 
                        :key="folder.id" 
                        class="hover:shadow-lg transition-shadow cursor-pointer"
                        @click="viewFolderContent(folder)"
                    >
                        <template #title>
                            <div class="flex justify-between items-center">
                                <span>{{ folder.name }}</span>
                                <div class="space-x-2">
                                    <Button 
                                        icon="pi pi-pencil" 
                                        class="p-button-text p-button-sm" 
                                        @click.stop="editFolderAction(folder)"
                                    />
                                    <Button 
                                        icon="pi pi-trash" 
                                        class="p-button-text p-button-sm p-button-danger" 
                                        @click.stop="deleteFolder(folder)"
                                    />
                                </div>
                            </div>
                        </template>
                        <template #content>
                            <div class="flex items-center space-x-2">
                                <i class="pi pi-folder text-xl text-blue-500"></i>
                                <div>
                                    <p class="text-sm text-gray-600">
                                        Files: {{ folder.fileCount }}
                                    </p>
                                    <p class="text-xs text-gray-500">
                                        Last updated: {{ folder.lastUpdated }}
                                    </p>
                                    <p v-if="folder.description" class="text-xs text-gray-500 mt-1">
                                        {{ folder.description }}
                                    </p>
                                </div>
                            </div>
                        </template>
                    </Card>
                </div>

                <!-- Empty State -->
                <div 
                    v-else
                    class="text-center text-gray-500 mt-10"
                >
                    No folders found. Create your first folder!
                </div>

                <!-- New Folder Dialog -->
                <Dialog 
                    v-model:visible="state.dialogs.newFolder" 
                    header="Create New Folder" 
                    :style="{ width: '450px' }"
                >
                    <div class="p-fluid">
                        <div class="field">
                            <label for="folderName" class="block text-900">Folder Name</label>
                            <InputText 
                                id="folderName"
                                v-model="state.newFolder.name" 
                                :class="{'p-invalid': state.errors.folderName}"
                            />
                            <small 
                                v-if="state.errors.folderName" 
                                class="p-error block"
                            >
                                {{ state.errors.folderName }}
                            </small>
                        </div>

                        <div class="field mt-4">
                            <label for="folderDescription" class="block text-900">Description (Optional)</label>
                            <InputText 
                                id="folderDescription"
                                v-model="state.newFolder.description" 
                                placeholder="Enter folder description"
                            />
                        </div>
                    </div>

                    <template #footer>
                        <Button 
                            label="Cancel" 
                            icon="pi pi-times" 
                            class="p-button-text" 
                            @click="state.dialogs.newFolder = false"
                        />
                        <Button 
                            label="Create" 
                            icon="pi pi-check" 
                            class="p-button-primary" 
                            @click="createFolder"
                        />
                    </template>
                </Dialog>

                <!-- Edit Folder Dialog -->
                <Dialog 
                    v-model:visible="state.dialogs.editFolder" 
                    header="Edit Folder" 
                    :style="{ width: '450px' }"
                >
                    <div class="p-fluid">
                        <div class="field">
                            <label for="editFolderName" class="block text-900">Folder Name</label>
                            <InputText 
                                id="editFolderName"
                                v-model="state.editFolder.name" 
                                :class="{'p-invalid': state.errors.folderName}"
                            />
                            <small 
                                v-if="state.errors.folderName" 
                                class="p-error block"
                            >
                                {{ state.errors.folderName }}
                            </small>
                        </div>

                        <div class="field mt-4">
                            <label for="editFolderDescription" class="block text-900">Description (Optional)</label>
                            <InputText 
                                id="editFolderDescription"
                                v-model="state.editFolder.description" 
                                placeholder="Enter folder description"
                            />
                        </div>
                    </div>

                    <template #footer>
                        <Button 
                            label="Cancel" 
                            icon="pi pi-times" 
                            class="p-button-text" 
                            @click="state.dialogs.editFolder = false"
                        />
                        <Button 
                            label="Save" 
                            icon="pi pi-check" 
                            class="p-button-primary" 
                            @click="updateFolder"
                        />
                    </template>
                </Dialog>

                <!-- Folder Content Dialog -->
                <Dialog 
                    v-model:visible="state.dialogs.folderContent" 
                    :header="state.selectedFolder ? state.selectedFolder.name : 'Folder Content'"
                    :style="{ width: '700px' }"
                    maximizable
                >
                    <div v-if="state.selectedFolder">
                        <div class="mb-4 flex justify-between items-center">
                            <div>
                                <h2 class="text-xl font-semibold">
                                    Files ({{ state.selectedFolder.fileCount }})
                                </h2>
                                <p v-if="state.selectedFolder.description" class="text-sm text-gray-500">
                                    {{ state.selectedFolder.description }}
                                </p>
                            </div>
                            <Button 
                                label="Upload File" 
                                icon="pi pi-upload" 
                                class="p-button-success"
                            />
                        </div>

                        <div v-if="state.selectedFolder.files.length" class="grid gap-3">
                            <div 
                                v-for="file in state.selectedFolder.files" 
                                :key="file.id" 
                                class="flex justify-between items-center p-3 bg-gray-100 rounded-lg hover:bg-gray-200 transition"
                            >
                                <div class="flex items-center space-x-3">
                                    <i 
                                        :class="['pi', getFileIcon(file.type), 'text-2xl', 
                                        file.type === 'pdf' ? 'text-red-500' : 
                                        file.type === 'doc' || file.type === 'docx' ? 'text-blue-500' : 
                                        file.type === 'xls' || file.type === 'xlsx' ? 'text-green-500' : 
                                        'text-gray-500'
                                        ]"
                                    ></i>
                                    <div>
                                        <p class="font-medium">{{ file.name }}</p>
                                        <p class="text-xs text-gray-500">
                                            {{ file.size }} | Uploaded: {{ file.uploaded }}
                                        </p>
                                    </div>
                                </div>
                                <div class="space-x-2">
                                    <Button 
                                        icon="pi pi-download" 
                                        class="p-button-text p-button-sm" 
                                        @click="downloadFile(file)"
                                    />
                                    <Button 
                                        icon="pi pi-trash" 
                                        class="p-button-text p-button-sm p-button-danger" 
                                        @click="deleteFile(state.selectedFolder, file)"
                                    />
                                </div>
                            </div>
                        </div>
                        <div v-else class="text-center text-gray-500 mt-4">
                            No files in this folder
                        </div>
                    </div>
                </Dialog>

                <Toast />
            </div>
        </div>
    </div>
</template>

<style scoped>
</style>
