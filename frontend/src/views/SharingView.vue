<script setup>
    import { ref, onMounted } from 'vue'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Sidebar from '../components/Sidebar.vue'

    const sharedResources = ref([])
    const loading = ref(false)

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
        } catch (error) {
            console.error('Failed to fetch shared resources:', error.message);
        } finally {
            loading.value = false
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
                    :value="sharedResources"
                    :loading="loading"
                    emptyMessage="No shared resources"
                    stripedRows
                >
                    <Column field="name" header="Name"></Column>
                    <Column field="description" header="Description"></Column>
                    <Column field="link" header="Link"></Column>
                    <Column field="session" header="Session"></Column>
                    <Column field="semester" header="Semester"></Column>
                    <Column field="owner" header="Shared By"></Column>
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
            </div>
        </div>
    </div>
</template>
