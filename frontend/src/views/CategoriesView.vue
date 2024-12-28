<script setup>
    import { ref, onMounted } from 'vue'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import InputText from 'primevue/inputtext'
    import Textarea from 'primevue/textarea'
    import Sidebar from '../components/Sidebar.vue'

    const categories = ref([])
    const showAddCategoryDialog = ref(false)

    const category = ref({
        name: '',
        description: ''
    })

    const addCategory = async () => {
        try {
            const response = await fetch('http://127.0.0.1:3000/api/categories', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(category.value)
            })

            if (!response.ok) {
                throw new Error('Failed to add category')
            }

            await fetchCategories()
            showAddCategoryDialog.value = false
            category.value = { name: '', description: '' }
        } catch (error) {
            console.error('Error adding category:', error)
        }
    }

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

                <Dialog
                    v-model:visible="showAddCategoryDialog"
                    modal
                    header="Add New Category"
                    :style="{ width: '30rem' }"
                >
                    <div class="flex items-center gap-4 mb-4">
                        <label for="name" class="font-semibold w-24">Name</label>
                        <InputText
                            id="name"
                            v-model="category.name"
                            class="flex-auto"
                            autocomplete="off"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-4">
                        <label for="description" class="font-semibold w-24">Description</label>
                        <Textarea
                            id="description"
                            v-model="category.description"
                            class="flex-auto"
                            rows="3"
                        />
                    </div>

                    <div class="flex justify-end gap-2">
                        <Button
                            type="button"
                            label="Cancel"
                            severity="secondary"
                            @click="showAddCategoryDialog = false"
                        />
                        <Button
                            type="button"
                            label="Save"
                            @click="addCategory"
                        />
                    </div>
                </Dialog>
            </div>
        </div>
    </div>
</template>
