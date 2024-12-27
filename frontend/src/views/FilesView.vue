<script setup>
    import { ref } from 'vue'
    import { onMounted } from 'vue'
    import { computed } from 'vue'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import InputText from 'primevue/inputtext'
    import Dropdown from 'primevue/dropdown'
    import Textarea from 'primevue/textarea';
    import Sidebar from '../components/Sidebar.vue'
    import MultiSelect from 'primevue/multiselect'

    const resources = ref([])
    const categories = ref([])
    const folders = ref([])
    const user = ref({})
    const users = ref([])
    const selectedUsers = ref([])
    const resourceToUpdate = ref(null)
    const resourceToDelete = ref(null)
    const resourceToShare = ref(null)
    const showAddResourceDialog = ref(false)
    const showUpdateResourceDialog = ref(false)
    const showDeleteResourceDialog = ref(false)
    const showShareResourceDialog = ref(false)

    const categoryOptions = computed(() => {
        return categories.value.map(category => ({
            name: category.name,
            category_id: category.category_id
        }))
    })

    const folderOptions = computed(() => {
        return folders.value.map(folder => ({
            name: folder.name,
            folder_id: folder.folder_id
        }))
    })

    const resource = ref({
        name: '',
        type: '',
        description: '',
        owner: computed(() => user.value.email),
        link: '',
        session: '',
        semester: '',
        folder: '',
        category: ''
    })

    const openEditResourceDialog = (res) => {
        resourceToUpdate.value = { ...res }
        resource.value = {
            name: res.name,
            type: res.type,
            description: res.description,
            owner: user.value.email,
            link: res.link,
            session: res.session,
            semester: res.semester,
            folder: res.folder_id,
            category: res.category_id
        }
        showUpdateResourceDialog.value = true
    }

    const openDeleteResourceDialog = (resource) => {
        resourceToDelete.value = resource
        showDeleteResourceDialog.value = true
    }

    const openShareResourceDialog = (resource) => {
        resourceToShare.value = resource;
        selectedUsers.value = []; // Reset selected users
        showShareResourceDialog.value = true;
    }

    const closeEditResourceDialog = () => {
        resource.value = {
            name: '',
            type: '',
            description: '',
            owner: computed(() => user.value.email),
            link: '',
            session: '',
            semester: '',
            folder: '',
            category: ''
        }
        resourceToUpdate.value = null
        showUpdateResourceDialog.value = false
    }

    const addResource = async () => {
        const url = 'http://127.0.0.1:3000/api/resources';
        try {
            const response = await fetch('http://127.0.0.1:3000/api/resources', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(resource.value)
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            const data = await response.json();
            console.log('Success:', data);

            await fetchResources();

            resource.value = {
                ...resource.value,
                name: '',
                type: '',
                description: '',
                link: '',
                session: '',
                semester: '',
                folder: '',
                category: ''
            };

            showAddResourceDialog.value = false

        } catch (error) {
            console.error(error.message);
        }
    }

    const updateResource = async () => {
        if (!resourceToUpdate.value) return

        const url = `http://127.0.0.1:3000/api/resources/${resourceToUpdate.value.resource_id}`
        try {
            const response = await fetch(url, {
                method: 'PUT',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(resource.value)
            })

            if (!response.ok) {
                const errorData = await response.json()
                throw new Error(errorData.error || 'Update failed')
            }

            await fetchResources()

            // Reset form and close dialog
            resource.value = {
                name: '',
                type: '',
                description: '',
                link: '',
                session: '',
                semester: '',
                folder: '',
                category: ''
            }

            showUpdateResourceDialog.value = false
            resourceToUpdate.value = null

        } catch (error) {
            console.error(error.message)
        }
    }

    const deleteResource = async () => {
        if (!resourceToDelete.value) return

        const url = `http://127.0.0.1:3000/api/resources/${resourceToDelete.value.resource_id}`
        try {
            const response = await fetch(url, {
                method: 'DELETE',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            })

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`)
            }

            await fetchResources()
            showDeleteResourceDialog.value = false
            resourceToDelete.value = null
        } catch (error) {
            console.error(error.message)
        }
    }

    const shareResource = async () => {
        if (!resourceToShare.value) {
            console.error('No resource selected');
            return;
        }

        // Log for debugging
        console.log('Selected User IDs:', selectedUsers.value);
        console.log('All Users:', users.value);

        // The selected users are already user IDs, so no need for mapping
        const validUserIds = selectedUsers.value.filter(id => 
            id !== null && id !== undefined
        );

        if (validUserIds.length === 0) {
            console.error('No valid users selected');
            return;
        }

        try {
            const response = await fetch('http://127.0.0.1:3000/api/resources/share', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    resource_id: resourceToShare.value.resource_id,
                    user_ids: validUserIds
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Sharing failed');
            }

            // Success handling
            console.log('Resource shared successfully');
            showShareResourceDialog.value = false;
            resourceToShare.value = null;
            selectedUsers.value = [];

        } catch (error) {
            console.error('Share resource error:', error.message);
        }
    }

    const fetchResources = async () => {
        const url = 'http://127.0.0.1:3000/api/resources';
        try {
            const response = await fetch(url, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            resources.value = await response.json();
        } catch (error) {
            console.error(error.message);
        }
    }

    const fetchCategories = async () => {
        const url = 'http://127.0.0.1:3000/api/categories';

        try {
            const response = await fetch(url, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            categories.value = await response.json();
        } catch (error) {
            console.log(error.message);
        }
    }

    const fetchFolders = async () => {
        const url = 'http://127.0.0.1:3000/api/folders';

        try {
            const response = await fetch(url, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            folders.value = await response.json();
        } catch (error) {
            console.log(error.message);
        }
    }

    const fetchUsers = async () => {
        const url = 'http://127.0.0.1:3000/api/users';
        try {
            const response = await fetch(url, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            const allUsers = await response.json();
            
            users.value = allUsers.filter(u => u.email !== user.value.email);
        } catch (error) {
            console.error('Failed to fetch users:', error.message);
        }
    }

    onMounted(() => {
        fetchResources();
        fetchCategories();
        fetchFolders();
        fetchUsers();

        // Retrieve user from sessionStorage
        const userString = sessionStorage.getItem('user')

        if (userString) {
            try {
                // Parse the JSON string
                user.value = JSON.parse(userString)
            } catch (error) {
                console.error('Error parsing user from sessionStorage:', error)
            }
        }
    })
</script>

<template>
    <div class="flex min-h-screen">
        <Sidebar />
        <div class="grow bg-gray-100 p-4">
            <div class="card">
                <div class="flex justify-between mb-4">
                    <h2 class="text-2xl font-bold">Resource Management</h2>
                    <Button
                        label="Add New Resource"
                        icon="pi pi-plus"
                        @click="showAddResourceDialog = true"
                    />
                </div>

                <DataTable :value="resources" stripedRows>
                    <Column field="name" header="Name"></Column>
                    <Column field="type" header="Type"></Column>
                    <Column field="description" header="Description"></Column>
                    <Column field="owner" header="Owner"></Column>
                    <Column field="link" header="Link"></Column>
                    <Column field="date_created" header="Date Added"></Column>
                    <Column field="session" header="Session"></Column>
                    <Column field="semester" header="Semester"></Column>
                    <Column header="Actions">
                        <template #body="{ data }">
                            <div class="flex gap-2">
                                <Button
                                    icon="pi pi-pencil"
                                    class="p-button-info p-button-sm"
                                    @click="openEditResourceDialog(data)"
                                />
                                <Button
                                    icon="pi pi-trash"
                                    class="p-button-danger p-button-sm"
                                    @click="openDeleteResourceDialog(data)"
                                />
                                <Button
                                    icon="pi pi-share-alt"
                                    class="p-button-success p-button-sm"
                                    @click="openShareResourceDialog(data)"
                                />
                            </div>
                        </template>
                    </Column>
                </DataTable>

                <!-- Add Resource Modal -->
                <Dialog v-model:visible="showAddResourceDialog" modal header="Add New Resource" :style="{ width: '30rem' }">
                    <div class="flex items-center gap-4 mb-4">
                        <label for="name" class="font-semibold w-24">Name</label>
                        <InputText id="name" v-model="resource.name" class="flex-auto" autocomplete="off" />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="type" class="font-semibold w-24">Type</label>
                        <Dropdown
                            id="type"
                            v-model="resource.type"
                            :options="['File', 'Folder']"
                            class="flex-auto"
                            placeholder="Select Type"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="description" class="font-semibold w-24">Description</label>
                        <Textarea id="description" v-model="resource.description" class="flex-auto" rows="3" />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="owner" class="font-semibold w-24">Owner</label>
                        <InputText id="owner" v-model="resource.owner" type="email" class="flex-auto" autocomplete="off" disabled />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="link" class="font-semibold w-24">Link</label>
                        <InputText id="link" v-model="resource.link" class="flex-auto" autocomplete="off" />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="session" class="font-semibold w-24">Session</label>
                        <Dropdown
                            id="session"
                            v-model="resource.session"
                            :options="['2023/2024', '2024/2025', '2025/2026']"
                            class="flex-auto"
                            placeholder="Select Session"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="semester" class="font-semibold w-24">Semester</label>
                        <Dropdown
                            id="semester"
                            v-model="resource.semester"
                            :options="['1', '2', '3']"
                            class="flex-auto"
                            placeholder="Select Semester"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="folder" class="font-semibold w-24">Folder</label>
                        <Dropdown
                            id="folder"
                            v-model="resource.folder"
                            :options="folderOptions"
                            optionLabel="name"
                            optionValue="folder_id"
                            class="flex-auto"
                            placeholder="Select Folder"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-8">
                        <label for="category" class="font-semibold w-24">Category</label>
                        <Dropdown
                            id="category"
                            v-model="resource.category"
                            :options="categoryOptions"
                            optionLabel="name"
                            optionValue="category_id"
                            class="flex-auto"
                            placeholder="Select Category"
                        />
                    </div>

                    <div class="flex justify-end gap-2">
                        <Button type="button" label="Cancel" severity="secondary" @click="showAddResourceDialog = false"></Button>
                        <Button type="button" label="Save" @click="addResource"></Button>
                    </div>
                </Dialog>

                <!-- Update Resource Modal -->
                <Dialog v-model:visible="showUpdateResourceDialog" modal header="Edit Resource" :style="{ width: '30rem' }" @hide="closeEditResourceDialog">
                    <div class="flex items-center gap-4 mb-4">
                        <label for="name" class="font-semibold w-24">Name</label>
                        <InputText id="name" v-model="resource.name" class="flex-auto" autocomplete="off" />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="type" class="font-semibold w-24">Type</label>
                        <Dropdown
                            id="type"
                            v-model="resource.type"
                            :options="['File', 'Folder']"
                            class="flex-auto"
                            placeholder="Select Type"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="description" class="font-semibold w-24">Description</label>
                        <Textarea id="description" v-model="resource.description" class="flex-auto" rows="3" />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="owner" class="font-semibold w-24">Owner</label>
                        <InputText id="owner" v-model="resource.owner" type="email" class="flex-auto" autocomplete="off" disabled />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="link" class="font-semibold w-24">Link</label>
                        <InputText id="link" v-model="resource.link" class="flex-auto" autocomplete="off" />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="session" class="font-semibold w-24">Session</label>
                        <Dropdown
                            id="session"
                            v-model="resource.session"
                            :options="['2023/2024', '2024/2025', '2025/2026']"
                            class="flex-auto"
                            placeholder="Select Session"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="semester" class="font-semibold w-24">Semester</label>
                        <Dropdown
                            id="semester"
                            v-model="resource.semester"
                            :options="['1', '2', '3']"
                            class="flex-auto"
                            placeholder="Select Semester"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="folder" class="font-semibold w-24">Folder</label>
                        <Dropdown
                            id="folder"
                            v-model="resource.folder"
                            :options="folderOptions"
                            optionLabel="name"
                            optionValue="folder_id"
                            class="flex-auto"
                            placeholder="Select Folder"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-8">
                        <label for="category" class="font-semibold w-24">Category</label>
                        <Dropdown
                            id="category"
                            v-model="resource.category"
                            :options="categoryOptions"
                            optionLabel="name"
                            optionValue="category_id"
                            class="flex-auto"
                            placeholder="Select Category"
                        />
                    </div>

                    <div class="flex justify-end gap-2">
                        <Button type="button" label="Cancel" severity="secondary" @click="showUpdateResourceDialog = false"></Button>
                        <Button type="button" label="Update" @click="updateResource"></Button>
                    </div>
                </Dialog>

                <!-- Delete Resource Modal -->
                <Dialog
                    v-model:visible="showDeleteResourceDialog"
                    header="Confirm Delete"
                    :style="{ width: '30rem' }"
                    modal
                >
                    <div class="flex items-center">
                        <span class="text-gray-700">Are you sure you want to delete this resource?</span>
                    </div>

                    <template #footer>
                        <div class="flex justify-end space-x-3">
                            <Button
                                label="Cancel"
                                icon="pi pi-times"
                                @click="showDeleteResourceDialog = false"
                                class="p-button-outlined p-button-secondary"
                            />
                            <Button
                                label="Delete"
                                icon="pi pi-trash"
                                @click="deleteResource"
                                class="p-button-danger"
                            />
                        </div>
                    </template>
                </Dialog>

                <!-- Share Resource Dialog -->
                <Dialog 
                    v-model:visible="showShareResourceDialog" 
                    modal 
                    header="Share Resource" 
                    :style="{ width: '35rem' }"
                >
                    <div class="mb-4">
                        <h3 class="text-lg font-semibold">
                            Share: {{ resourceToShare ? resourceToShare.name : 'Resource' }}
                        </h3>
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="users" class="font-semibold w-24">Select Users</label>
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
                        />

                    </div>

                    <div class="flex justify-end gap-2">
                        <Button 
                            type="button" 
                            label="Cancel" 
                            severity="secondary" 
                            @click="showShareResourceDialog = false"
                        />
                        <Button 
                            type="button" 
                            label="Share" 
                            @click="shareResource"
                            :disabled="selectedUsers.length === 0"
                        />
                    </div>
                </Dialog>
            </div>
        </div>
    </div>
</template>
