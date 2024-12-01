<script setup>
    import { ref } from 'vue'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import InputText from 'primevue/inputtext'
    import Dropdown from 'primevue/dropdown'
    import Sidebar from '../components/Sidebar.vue'

    // File types dropdown options
    const fileTypes = ref([
        { name: 'PDF', code: 'PDF' },
        { name: 'DOCX', code: 'DOCX' },
        { name: 'PPTX', code: 'PPTX' },
        { name: 'CSV', code: 'CSV' },
        { name: 'Other', code: 'OTHER' }
    ])

    const files = ref([
        {
            id: 1,
            name: 'Assignment 1',
            type: 'PDF',
            size: '2.5 MB',
            uploadDate: '2023-06-15',
            sharedBy: 'Dr. John Doe',
            shareDate: '2023-06-16'
        },
        {
            id: 2,
            name: 'Lecture Notes',
            type: 'DOCX',
            size: '1.2 MB',
            uploadDate: '2023-06-10',
            sharedBy: 'Prof. Jane Smith',
            shareDate: '2023-06-12'
        },
        {
            id: 3,
            name: 'Machine Learning Dataset',
            type: 'CSV',
            size: '50.7 MB',
            uploadDate: '2023-06-05',
            sharedBy: 'Dr. Alan Turing',
            shareDate: '2023-06-08'
        },
        {
            id: 4,
            name: 'Research Proposal',
            type: 'PPTX',
            size: '15.3 MB',
            uploadDate: '2023-05-30',
            sharedBy: 'Dr. Marie Curie',
            shareDate: '2023-06-02'
        },
        {
            id: 5,
            name: 'Network Security Slides',
            type: 'PDF',
            size: '8.7 MB',
            uploadDate: '2023-06-20',
            sharedBy: 'Prof. Dennis Ritchie',
            shareDate: '2023-06-22'
        },
        {
            id: 6,
            name: 'Database Design Report',
            type: 'DOCX',
            size: '4.5 MB',
            uploadDate: '2023-06-18',
            sharedBy: 'Dr. Grace Hopper',
            shareDate: '2023-06-19'
        },
        {
            id: 7,
            name: 'AI Ethics Paper',
            type: 'PDF',
            size: '6.2 MB',
            uploadDate: '2023-06-12',
            sharedBy: 'Prof. Andrew Ng',
            shareDate: '2023-06-14'
        },
        {
            id: 8,
            name: 'Cloud Computing Notes',
            type: 'PPTX',
            size: '12.1 MB',
            uploadDate: '2023-06-08',
            sharedBy: 'Dr. Werner Vogels',
            shareDate: '2023-06-10'
        },
        {
            id: 9,
            name: 'Software Engineering Guidelines',
            type: 'PDF',
            size: '3.8 MB',
            uploadDate: '2023-06-16',
            sharedBy: 'Prof. Martin Fowler',
            shareDate: '2023-06-17'
        }
    ])

    // Modal state
    const visible = ref(false)
    const isEditMode = ref(false)
    const currentFile = ref({
        name: '',
        type: null,
        size: '',
        googleDriveLink: '',
    })

    // Modal open handlers
    const openAddModal = () => {
        isEditMode.value = false
        currentFile.value = {
            name: '',
            type: null,
            size: '',
            googleDriveLink: '',
        }
        visible.value = true
    }

    const openEditModal = (file) => {
        isEditMode.value = true
        currentFile.value = { ...file }
        visible.value = true
    }

    // Save file handler
    const saveFile = () => {
        if (isEditMode.value) {
            // Update existing file
            const index = files.value.findIndex(f => f.id === currentFile.value.id)
            files.value[index] = {
                ...currentFile.value,
                shareDate: new Date().toISOString().split('T')[0],
                sharedBy: 'Current User' // In real app, use actual logged-in user
            }
        } else {
            // Add new file
            const newFile = {
                ...currentFile.value,
                id: files.value.length + 1,
                uploadDate: new Date().toISOString().split('T')[0],
                shareDate: new Date().toISOString().split('T')[0],
                sharedBy: 'Current User' // In real app, use actual logged-in user
            }
            files.value.push(newFile)
        }
        visible.value = false
    }

    // Delete file handler
    const deleteFile = (file) => {
        files.value = files.value.filter(f => f.id !== file.id)
    }
</script>

<template>
    <div class="flex min-h-screen">
        <Sidebar />
        <div class="grow bg-gray-100 p-4">
            <div class="card">
                <div class="flex justify-between mb-4">
                    <h2 class="text-2xl font-bold">File Management</h2>
                    <Button
                        label="Add New File"
                        icon="pi pi-plus"
                        @click="openAddModal"
                    />
                </div>

                <DataTable :value="files" stripedRows>
                    <Column field="name" header="Name"></Column>
                    <Column field="type" header="Type"></Column>
                    <Column field="size" header="Size"></Column>
                    <Column field="uploadDate" header="Upload Date"></Column>
                    <Column field="sharedBy" header="Shared By"></Column>
                    <Column field="shareDate" header="Share Date"></Column>
                    <Column header="Actions">
                        <template #body="{ data }">
                            <div class="flex gap-2">
                                <Button
                                    icon="pi pi-pencil"
                                    class="p-button-info p-button-sm"
                                    @click="openEditModal(data)"
                                />
                                <Button
                                    icon="pi pi-trash"
                                    class="p-button-danger p-button-sm"
                                    @click="deleteFile(data)"
                                />
                            </div>
                        </template>
                    </Column>
                </DataTable>

                <!-- File Modal -->
                <Dialog
                    v-model:visible="visible"
                    :header="isEditMode ? 'Edit File' : 'Add New File'"
                    modal
                    class="w-full max-w-[500px]"
                >
                    <div class="grid grid-cols-1 gap-4 p-4">
                        <div class="flex flex-col">
                            <label class="mb-2 font-semibold">File Name</label>
                            <InputText
                                v-model="currentFile.name"
                                placeholder="Enter file name"
                                class="w-full"
                            />
                        </div>

                        <div class="flex flex-col">
                            <label class="mb-2 font-semibold">File Type</label>
                            <Dropdown
                                v-model="currentFile.type"
                                :options="fileTypes"
                                optionLabel="name"
                                optionValue="code"
                                placeholder="Select file type"
                                class="w-full"
                            />
                        </div>

                        <div class="flex flex-col">
                            <label class="mb-2 font-semibold">File Size (optional)</label>
                            <InputText
                                v-model="currentFile.size"
                                placeholder="Enter file size (e.g., 2.5 MB)"
                                class="w-full"
                            />
                        </div>

                        <div class="flex flex-col">
                            <label class="mb-2 font-semibold">Google Drive Link</label>
                            <InputText
                                v-model="currentFile.googleDriveLink"
                                placeholder="Paste Google Drive share link"
                                class="w-full"
                            />
                            <small class="text-xs text-gray-500 mt-1">
                                Ensure you've set the correct sharing permissions for the file
                            </small>
                        </div>

                        <div class="flex justify-end mt-4">
                            <Button
                                :label="isEditMode ? 'Update' : 'Add'"
                                @click="saveFile"
                                class="p-button-primary"
                            />
                        </div>
                    </div>
                </Dialog>
            </div>
        </div>
    </div>
</template>
