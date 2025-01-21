<script setup>
    import { ref, onMounted, computed } from 'vue'
    import { FilterMatchMode } from '@primevue/core/api';
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import MultiSelect from 'primevue/multiselect'
    import Sidebar from '../components/Sidebar.vue'
    import Tag from 'primevue/tag'
    import IconField from 'primevue/iconfield'
    import InputIcon from 'primevue/inputicon'
    import InputText from 'primevue/inputtext'

    const filters = ref({
        'global': { value: null, matchMode: FilterMatchMode.CONTAINS },
        'combinedSession': { value: null, matchMode: FilterMatchMode.IN },
        'owner': { value: null, matchMode: FilterMatchMode.IN },
        'category_name': { value: [], matchMode: FilterMatchMode.IN } // Add this line
    })

    const resourcesWithCombinedSession = computed(() => {
        return sharedResources.value.map(resource => ({
            ...resource,
            combinedSession: `${resource.session}-${resource.semester}`
        }))
    })

    const ownersFilter = ref([])
    const categoryFilter = ref([])

    const sharedResources = ref([])
    const loading = ref(false)
    const resourceToDelete = ref(null)
    const showDeleteResourceDialog = ref(false)

    const openDeleteResourceDialog = (resource) => {
        resourceToDelete.value = resource
        showDeleteResourceDialog.value = true
    }

    const fetchSharedResources = async () => {
        loading.value = true
        try {
            const response = await fetch('http://127.0.0.1:3000/api/resources/shared', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            sharedResources.value = await response.json();

            ownersFilter.value = [...new Set(sharedResources.value.map(resource => resource.owner))]
            categoryFilter.value = [...new Set(sharedResources.value.map(resource => resource.category_name))]
        } catch (error) {
            console.error('Failed to fetch shared resources:', error.message);
        } finally {
            loading.value = false
        }
    }

    const deleteSharedResource = async () => {
        if (!resourceToDelete.value) return

        try {
            const response = await fetch('http://127.0.0.1:3000/api/resources/shared/delete', {
                method: 'DELETE',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    resource_id: resourceToDelete.value.resource_id
                })
            })

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`)
            }

            await fetchSharedResources()
            showDeleteResourceDialog.value = false
            resourceToDelete.value = null
        } catch (error) {
            console.error('Failed to delete shared resource:', error.message)
        }
    }

    const openResourceLink = (link) => {
        window.open(link, '_blank');
    }

    onMounted(() => {
        fetchSharedResources()
    })
</script>

<template>
    <div class="flex min-h-screen">
        <Sidebar />
        <div class="grow bg-gray-100 p-4">
            <div class="card">
                <div class="flex justify-between mb-4">
                    <h2 class="text-2xl font-bold">Shared with me</h2>
                    <div class="flex gap-4 items-center">
                        <IconField>
                            <InputIcon class="pi pi-search" />
                            <InputText 
                                v-model="filters['global'].value" 
                                placeholder="Search" 
                                class="w-full"
                            />
                        </IconField>
                    </div>
                </div>

                <DataTable
                    v-model:filters="filters"
                    filterDisplay="menu"
                    :globalFilterFields="[
                        'name', 
                        'category_name', 
                        'description', 
                        'owner', 
                        'combinedSession'
                    ]"
                    :value="resourcesWithCombinedSession"
                    :loading="loading"
                    emptyMessage="No shared resources"
                    stripedRows
                >
                    <Column field="name" header="Name"></Column>
                    <Column 
                        field="category_name" 
                        header="Category" 
                        :showFilterMatchModes="false"
                        :filterMenuStyle="{ width: '16rem' }"
                    >
                        <template #body="{ data }">
                            <Tag :value="data.category_name" severity="info" rounded />
                        </template>
                        <template #filter="{ filterModel }">
                            <MultiSelect
                                v-model="filterModel.value"
                                :options="categoryFilter"
                                placeholder="Select Categories"
                                class="p-column-filter"
                                :maxSelectedLabels="1"
                            />
                        </template>
                    </Column>
                    <Column field="description" header="Description"></Column>
                    <Column field="owner" header="Shared By" :showFilterMatchModes="false" :filterMenuStyle="{ width: '26rem' }">
                        <template #filter="{ filterModel }">
                            <MultiSelect
                                v-model="filterModel.value"
                                :options="ownersFilter"
                                placeholder="Select Owners"
                            />
                        </template>
                    </Column>
                    <Column field="date_shared" header="Date Shared"></Column>
                    <Column 
                        field="combinedSession" 
                        header="Session" 
                        :showFilterMatchModes="false"
                    >
                        <template #body="{ data }">
                            {{ data.combinedSession }}
                        </template>
                        <template #filter="{ filterModel }">
                            <MultiSelect
                                v-model="filterModel.value"
                                :options="['2023/2024-1', '2023/2024-2', '2024/2025-1', '2024/2025-2']"
                                placeholder="Select Sessions"
                                :maxSelectedLabels="1"
                            />
                        </template>
                    </Column>
                    <Column header="Actions">
                        <template #body="{ data }">
                            <Button
                                icon="pi pi-external-link"
                                outlined
                                rounded
                                severity="secondary"
                                class="mr-2"
                                @click="openResourceLink(data.link)"
                                title="Open Resource Link"
                            />
                            <Button
                                icon="pi pi-trash"
                                outlined
                                rounded
                                severity="danger"
                                @click="openDeleteResourceDialog(data)"
                            />
                        </template>
                    </Column>
                    <template #empty>
                    <div class="flex justify-center items-center flex-col p-6">
                        <i class="pi pi-inbox text-6xl text-gray-300 mb-4"></i>
                        <p class="text-xl text-gray-500 mb-2">No shared resources</p>
                        <p class="text-gray-400 mb-4 text-center">
                            Resources shared with you will appear here. 
                        </p>
                    </div>
                </template>
                </DataTable>

                <!-- Delete Shared Resource Dialog -->
                <Dialog
                    v-model:visible="showDeleteResourceDialog"
                    header="Confirm Delete"
                    :style="{ width: '30rem' }"
                    modal
                >
                    <div class="flex items-center">
                        <span class="text-gray-700">Are you sure you want to remove this shared resource?</span>
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
                                @click="deleteSharedResource"
                                class="p-button-danger"
                            />
                        </div>
                    </template>
                </Dialog>
            </div>
        </div>
    </div>
</template>
