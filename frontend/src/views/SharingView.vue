<script setup>
    import { ref, onMounted } from 'vue'
    import { FilterMatchMode } from '@primevue/core/api';
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import MultiSelect from 'primevue/multiselect'
    import Sidebar from '../components/Sidebar.vue'

    const filters = ref({
        'global': { value: null, matchMode: FilterMatchMode.CONTAINS },
        'session': { value: null, matchMode: FilterMatchMode.IN },
        'semester': { value: null, matchMode: FilterMatchMode.IN },
        'owner': { value: null, matchMode: FilterMatchMode.IN }
    })

    const ownersFilter = ref([])

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
                </div>

                <DataTable
                    v-model:filters="filters"
                    filterDisplay="menu"
                    :globalFilterFields="['session', 'semester', 'owner']"
                    :value="sharedResources"
                    :loading="loading"
                    emptyMessage="No shared resources"
                    stripedRows
                >
                    <Column field="name" header="Name"></Column>
                    <Column field="description" header="Description"></Column>
                    <Column field="link" header="Link"></Column>
                    <Column field="session" header="Session" :showFilterMatchModes="false">
                        <template #filter="{ filterModel }">
                            <MultiSelect
                                v-model="filterModel.value"
                                :options="['2023/2024', '2024/2025', '2025/2026']"
                                placeholder="Select Sessions"
                            />
                        </template>
                    </Column>
                    <Column field="semester" header="Semester" :showFilterMatchModes="false">
                        <template #filter="{ filterModel }">
                            <MultiSelect
                                v-model="filterModel.value"
                                :options="['1', '2', '3']"
                                placeholder="Select Semesters"
                            />
                        </template>
                    </Column>
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
                    <Column header="Actions">
                        <template #body="{ data }">
                            <Button
                                icon="pi pi-trash"
                                class="p-button-danger p-button-sm"
                                @click="openDeleteResourceDialog(data)"
                            />
                        </template>
                    </Column>
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
