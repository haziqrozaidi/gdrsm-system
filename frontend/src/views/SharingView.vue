<script setup>
    import { ref } from 'vue'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Sidebar from '../components/Sidebar.vue'

    const sharedResources = ref([])
    const loading = ref(false)
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
