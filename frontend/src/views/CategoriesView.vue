<script setup>
    import { ref, onMounted } from 'vue'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Sidebar from '../components/Sidebar.vue'

    const categories = ref([])

    const fetchCategories = async () => {
        try {
            const response = await fetch('http://127.0.0.1:3000/api/categories', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json'
                }
            })

            if (!response.ok) {
                throw new Error('Failed to fetch categories')
            }

            categories.value = await response.json()
        } catch (error) {
            console.error('Error fetching categories:', error)
        }
    }

    onMounted(fetchCategories)
</script>

<template>
    <div class="flex min-h-screen">
        <Sidebar />
        <div class="grow bg-gray-100 p-4">
            <div class="card">
                <div class="flex justify-between mb-4">
                    <h2 class="text-2xl font-bold">Categories Management</h2>
                    <Button
                        label="Add Category"
                        icon="pi pi-plus"
                        @click="showAddCategoryDialog = true"
                    />
                </div>

                <DataTable :value="categories" stripedRows>
                    <Column field="name" header="Name"></Column>
                    <Column field="description" header="Description"></Column>
                    <Column field="date_created" header="Date Created"></Column>
                    <Column header="Actions">
                        <template #body="{ data }">
                            <div class="flex gap-2">
                                <Button
                                    icon="pi pi-pencil"
                                    class="p-button-info p-button-sm"
                                />
                                <Button
                                    icon="pi pi-trash"
                                    class="p-button-danger p-button-sm"
                                />
                            </div>
                        </template>
                    </Column>
                </DataTable>
            </div>
        </div>
    </div>
</template>
