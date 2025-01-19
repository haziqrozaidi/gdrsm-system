<script setup>
    import { ref } from 'vue'
    import { onMounted } from 'vue'
    import { computed } from 'vue'
    import { FilterMatchMode } from '@primevue/core/api';
    import { useToast } from 'primevue/usetoast'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import InputText from 'primevue/inputtext'
    import Dropdown from 'primevue/dropdown'
    import Textarea from 'primevue/textarea';
    import Sidebar from '../components/Sidebar.vue'
    import MultiSelect from 'primevue/multiselect'
    import Tag from 'primevue/tag'
    import Toast from 'primevue/toast'
    import Chip from 'primevue/chip'

    const toast = useToast()

    const resources = ref([])
    const categories = ref([])
    const folders = ref([])
    const user = ref({})
    const users = ref([])
    const sharedUsers = ref([])
    const selectedUsers = ref([])
    const groups = ref([])
    const selectedGroups = ref([])
    const sharedGroups = ref([])
    const resourceToUpdate = ref(null)
    const resourceToDelete = ref(null)
    const resourceToShare = ref(null)
    const showAddResourceDialog = ref(false)
    const showUpdateResourceDialog = ref(false)
    const showDeleteResourceDialog = ref(false)
    const showShareResourceDialog = ref(false)

    const filters = ref({
        'global': { value: null, matchMode: FilterMatchMode.CONTAINS },
        'type': { value: null, matchMode: FilterMatchMode.IN },
        'session': { value: null, matchMode: FilterMatchMode.IN },
        'semester': { value: null, matchMode: FilterMatchMode.IN }
    })

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
        selectedGroups.value = []; // Reset selected groups
        fetchSharedUsers(resource.resource_id); // Fetch currently shared users
        fetchSharedGroups(resource.resource_id); // Fetch currently shared groups
        fetchGroups(); // Fetch available groups
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
        const url = user.value?.description === 'admin'
        ? 'http://127.0.0.1:3000/api/admin/resources'
        : 'http://127.0.0.1:3000/api/resources';

        try {
            const response = await fetch(url, {
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

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Resource Added Successfully',
                life: 3000
            })

        } catch (error) {
            console.error(error.message);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message,
                life: 3000
            })
        }
    }

    const updateResource = async () => {
        if (!resourceToUpdate.value) return

        const url = user.value?.description === 'admin'
            ? `http://127.0.0.1:3000/api/admin/resources/${resourceToUpdate.value.resource_id}`
            : `http://127.0.0.1:3000/api/resources/${resourceToUpdate.value.resource_id}`;
            
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

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Resource Updated Successfully',
                life: 3000
            })

        } catch (error) {
            console.error(error.message)
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message,
                life: 3000
            })
        }
    }

    const deleteResource = async () => {
        if (!resourceToDelete.value) return

        const url = user.value.description === 'admin'
            ? `http://127.0.0.1:3000/api/admin/resources/${resourceToDelete.value.resource_id}`
            : `http://127.0.0.1:3000/api/resources/${resourceToDelete.value.resource_id}`;

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

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Resource Deleted Successfully',
                life: 3000
            })

        } catch (error) {
            console.error(error.message)
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message,
                life: 3000
            })
        }
    }

    const shareResource = async () => {
        if (!resourceToShare.value) {
            console.error('No resource selected');
            return;
        }

        // Validate that at least one sharing option is selected
        if (selectedUsers.value.length === 0 && selectedGroups.value.length === 0) {
            toast.add({
                severity: 'warn',
                summary: 'Warning',
                detail: 'Please select users or groups to share with',
                life: 3000
            });
            return;
        }

        try {
            // Prepare the sharing payload
            const sharePayload = {
                resource_id: resourceToShare.value.resource_id,
                user_ids: selectedUsers.value,
                group_ids: selectedGroups.value
            };

            const url = user.value?.description === 'admin'
                ? 'http://127.0.0.1:3000/api/admin/resources/share-with-groups-and-users'
                : 'http://127.0.0.1:3000/api/resources/share-with-groups-and-users';

            const response = await fetch(url, {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(sharePayload)
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Sharing failed');
            }

            // Update the resource's sharing status
            const updatedResource = resources.value.find(r => r.resource_id === resourceToShare.value.resource_id);
            if (updatedResource) {
                updatedResource.isShared = true;
            }

            // Success handling
            console.log('Resource shared successfully');
            showShareResourceDialog.value = false;
            resourceToShare.value = null;
            selectedUsers.value = [];
            selectedGroups.value = [];

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Resource Shared Successfully',
                life: 3000
            });

        } catch (error) {
            console.error('Share resource error:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message,
                life: 3000
            });
        }
    }

    const fetchResources = async () => {
        const url = user.value.description === 'admin' 
            ? 'http://127.0.0.1:3000/api/admin/resources'
            : 'http://127.0.0.1:3000/api/resources';

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

            const fetchedResources = await response.json();
            
            // For each resource, fetch its sharing status
            resources.value = await Promise.all(fetchedResources.map(async (resource) => {
                const [sharedUsers, sharedGroups] = await Promise.all([
                    fetchResourceSharedUsers(resource.resource_id),
                    fetchResourceSharedGroups(resource.resource_id)
                ]);
                
                return {
                    ...resource,
                    isShared: sharedUsers.length > 0 || sharedGroups.length > 0
                };
            }));
        } catch (error) {
            console.error(error.message);
        }
    }

    const fetchResourceSharedUsers = async (resourceId) => {
        const url = user.value?.description === 'admin'
            ? `http://127.0.0.1:3000/api/admin/resources/${resourceId}/shared-users`
            : `http://127.0.0.1:3000/api/resources/${resourceId}/shared-users`;
        
        try {
            const response = await fetch(url, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });
            
            if (!response.ok) {
                return [];
            }
            
            return await response.json();
        } catch (error) {
            console.error('Error fetching shared users:', error);
            return [];
        }
    }

    const fetchResourceSharedGroups = async (resourceId) => {
        const url = user.value?.description === 'admin'
            ? `http://127.0.0.1:3000/api/admin/resources/${resourceId}/shared-groups`
            : `http://127.0.0.1:3000/api/resources/${resourceId}/shared-groups`;
        
        try {
            const response = await fetch(url, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });
            
            if (!response.ok) {
                return [];
            }
            
            return await response.json();
        } catch (error) {
            console.error('Error fetching shared groups:', error);
            return [];
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
        const url = user.value.description === 'admin' 
            ? 'http://127.0.0.1:3000/api/admin/folders'
            : 'http://127.0.0.1:3000/api/folders';

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

    const fetchGroups = async () => {
        const url = user.value?.description === 'admin' 
            ? 'http://127.0.0.1:3000/api/admin/groups'
            : 'http://127.0.0.1:3000/api/groups';

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

            // Filter groups to only include those with membership_status "Created"
            groups.value = (await response.json()).filter(group => group.membership_status === 'Created');
        } catch (error) {
            console.error('Failed to fetch groups:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'Failed to fetch groups',
                life: 3000
            });
        }
    }

    const fetchSharedUsers = async (resourceId) => {
        const url = user.value?.description === 'admin'
            ? `http://127.0.0.1:3000/api/admin/resources/${resourceId}/shared-users`
            : `http://127.0.0.1:3000/api/resources/${resourceId}/shared-users`;

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

            sharedUsers.value = await response.json();
        } catch (error) {
            console.error('Failed to fetch shared users:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'Failed to fetch shared users',
                life: 3000
            });
        }
    }

    const fetchSharedGroups = async (resourceId) => {
        const url = user.value?.description === 'admin'
            ? `http://127.0.0.1:3000/api/admin/resources/${resourceId}/shared-groups`
            : `http://127.0.0.1:3000/api/resources/${resourceId}/shared-groups`;

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

            sharedGroups.value = await response.json();
        } catch (error) {
            console.error('Failed to fetch shared groups:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'Failed to fetch shared groups',
                life: 3000
            });
        }
    }

    const unshareResource = async (userId) => {
        if (!resourceToShare.value) {
            console.error('No resource selected');
            return;
        }

        try {
            const url = user.value?.description === 'admin'
                ? 'http://127.0.0.1:3000/api/admin/resources/unshare'
                : 'http://127.0.0.1:3000/api/resources/unshare';

            const response = await fetch(url, {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    resource_id: resourceToShare.value.resource_id,
                    user_id: userId
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Unsharing failed');
            }

            // Check if resource still has any shares
            const [remainingUsers, remainingGroups] = await Promise.all([
                fetchResourceSharedUsers(resourceToShare.value.resource_id),
                fetchResourceSharedGroups(resourceToShare.value.resource_id)
            ]);
            
            // Update the resource's sharing status
            const updatedResource = resources.value.find(r => r.resource_id === resourceToShare.value.resource_id);
            if (updatedResource) {
                updatedResource.isShared = remainingUsers.length > 0 || remainingGroups.length > 0;
            }

            // Refresh shared users list
            await fetchSharedUsers(resourceToShare.value.resource_id);

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Resource Unshared Successfully',
                life: 3000
            });

        } catch (error) {
            console.error('Unshare resource error:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message,
                life: 3000
            });
        }
    }

    const unshareResourceFromGroup = async (groupId) => {
        if (!resourceToShare.value) {
            console.error('No resource selected');
            return;
        }

        try {
            const url = user.value?.description === 'admin'
                ? 'http://127.0.0.1:3000/api/admin/resources/unshare-group'
                : 'http://127.0.0.1:3000/api/resources/unshare-group';

            const response = await fetch(url, {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    resource_id: resourceToShare.value.resource_id,
                    group_id: groupId
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Unsharing failed');
            }

            // Check if resource still has any shares
            const [remainingUsers, remainingGroups] = await Promise.all([
                fetchResourceSharedUsers(resourceToShare.value.resource_id),
                fetchResourceSharedGroups(resourceToShare.value.resource_id)
            ]);
            
            // Update the resource's sharing status
            const updatedResource = resources.value.find(r => r.resource_id === resourceToShare.value.resource_id);
            if (updatedResource) {
                updatedResource.isShared = remainingUsers.length > 0 || remainingGroups.length > 0;
            }

            // Refresh shared groups list
            await fetchSharedGroups(resourceToShare.value.resource_id);

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Resource Unshared from Group Successfully',
                life: 3000
            });

        } catch (error) {
            console.error('Unshare resource from group error:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message,
                life: 3000
            });
        }
    }

    const openResourceLink = (link) => {
        window.open(link, '_blank');
    }

    onMounted(() => {
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

        fetchResources();
        fetchCategories();
        fetchFolders();
        fetchUsers();
        fetchGroups();
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

                <DataTable
                    v-model:filters="filters"
                    filterDisplay="menu"
                    :globalFilterFields="['type', 'session', 'semester']"
                    :value="resources"
                    stripedRows
                    paginator :rows="5" :rowsPerPageOptions="[5, 10, 20, 50]"
                >
                    <Column field="name" header="Name"></Column>
                    <Column header="Category">
                        <template #body="{ data }">
                            <Tag :value="data.category_name" severity="info" rounded />
                        </template>
                    </Column>
                    <Column field="description" header="Description"></Column>
                    <Column field="owner" header="Owner"></Column>
                    <Column field="date_created" header="Date Added"></Column>
                    <Column field="session" header="Session" :showFilterMatchModes="false">
                        <template #body="{ data }">
                            {{ data.session }}-{{ data.semester }}
                        </template>
                        <template #filter="{ filterModel }">
                            <MultiSelect
                                v-model="filterModel.value"
                                :options="['2023/2024-1', '2023/2024-2', '2024/2025-1', '2024/2025-2']"
                                placeholder="Select Sessions"
                            />
                        </template>
                    </Column>
                    <Column header="Actions">
                        <template #body="{ data }">
                            <div class="flex gap-2">
                                <Button
                                    icon="pi pi-external-link"
                                    outlined
                                    rounded
                                    severity="secondary"
                                    @click="openResourceLink(data.link)"
                                    title="Open Resource Link"
                                />
                                <Button
                                    icon="pi pi-pencil"
                                    outlined
                                    rounded
                                    severity="secondary"
                                    @click="openEditResourceDialog(data)"
                                />
                                <Button
                                    icon="pi pi-share-alt"
                                    outlined
                                    rounded
                                    :severity="data.isShared ? 'success' : 'secondary'"
                                    @click="openShareResourceDialog(data)"
                                />
                                <Button
                                    icon="pi pi-trash"
                                    outlined
                                    rounded
                                    severity="danger"
                                    @click="openDeleteResourceDialog(data)"
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
                            :maxSelectedLabels="1"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="groups" class="font-semibold w-24">Select Groups</label>
                        <MultiSelect
                            id="groups"
                            v-model="selectedGroups"
                            :options="groups"
                            optionLabel="name"
                            optionValue="group_id"
                            placeholder="Select Groups to Share With"
                            display="chip"
                            class="flex-auto"
                            filter
                            :maxSelectedLabels="1"
                        />
                    </div>

                    <div v-if="sharedUsers.length > 0" class="mb-4">
                        <h4 class="text-md font-semibold mb-2">Currently Shared With:</h4>
                        <div class="flex flex-wrap gap-2">
                            <Chip
                                v-for="user in sharedUsers"
                                :key="user.user_id"
                                :label="user.email"
                                removable
                                @remove="unshareResource(user.user_id)"
                            />
                        </div>
                    </div>

                    <div v-if="sharedGroups.length > 0" class="mb-4">
                        <h4 class="text-md font-semibold mb-2">Currently Shared With Groups:</h4>
                        <div class="flex flex-wrap gap-2">
                            <Chip
                                v-for="group in sharedGroups"
                                :key="group.group_id"
                                :label="group.name"
                                removable
                                @remove="unshareResourceFromGroup(group.group_id)"
                            />
                        </div>
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
                            :disabled="selectedUsers.length === 0 && selectedGroups.length === 0"
                        />
                    </div>
                </Dialog>
            </div>
        </div>
    </div>
</template>
