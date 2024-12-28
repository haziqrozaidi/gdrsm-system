<script setup>
    import { ref, onMounted } from 'vue'
    import { useToast } from 'primevue/usetoast'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import InputText from 'primevue/inputtext'
    import Textarea from 'primevue/textarea'
    import Sidebar from '../components/Sidebar.vue'

    const toast = useToast()

    const categories = ref([])
    const showAddCategoryDialog = ref(false)
    const showUpdateCategoryDialog = ref(false)
    const showDeleteCategoryDialog = ref(false)
    const categoryToUpdate = ref(null)
    const categoryToDelete = ref(null)

    const category = ref({
        name: '',
        description: ''
    })

    const openUpdateCategoryDialog = (cat) => {
        categoryToUpdate.value = cat
        category.value = {
            name: cat.name,
            description: cat.description
        }
        showUpdateCategoryDialog.value = true
    }

    const openDeleteCategoryDialog = (cat) => {
        categoryToDelete.value = cat
        showDeleteCategoryDialog.value = true
    }

    const closeUpdateCategoryDialog = () => {
        category.value = {
            name: '',
            description: ''
        }
        categoryToUpdate.value = null
        showUpdateCategoryDialog.value = false
    }

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

    const updateCategory = async () => {
        try {
            const response = await fetch(`http://127.0.0.1:3000/api/categories/${categoryToUpdate.value.category_id}`, {
                method: 'PUT',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(category.value)
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error || 'Failed to update category')
            }

            await fetchCategories()
            showUpdateCategoryDialog.value = false
            category.value = { name: '', description: '' }
            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Category updated successfully',
                life: 3000
            })
        } catch (error) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message,
                life: 3000
            })
        }
    }

    const deleteCategory = async () => {
        try {
            if (!categoryToDelete.value) return

            const response = await fetch(`http://127.0.0.1:3000/api/categories/${categoryToDelete.value.category_id}`, {
                method: 'DELETE',
                credentials: 'include'
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error)
            }

            await fetchCategories()
            showDeleteCategoryDialog.value = false
            categoryToDelete.value = null

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Category deleted successfully',
                life: 3000
            })
        } catch (error) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message,
                life: 3000
            })
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
                                    @click="openUpdateCategoryDialog(data)"
                                />
                                <Button
                                    icon="pi pi-trash"
                                    class="p-button-danger p-button-sm"
                                    @click="openDeleteCategoryDialog(data)"
                                />
                            </div>
                        </template>
                    </Column>
                </DataTable>

                <!-- Add Category Modal -->
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

                <!-- Update Category Modal -->
                <Dialog
                    v-model:visible="showUpdateCategoryDialog"
                    modal
                    header="Update Category"
                    :style="{ width: '30rem' }"
                    @hide="closeUpdateCategoryDialog"
                >
                    <div class="flex flex-col gap-4">
                        <div>
                            <label for="updateName" class="block mb-2">Name</label>
                            <InputText
                                id="updateName"
                                v-model="category.name"
                                class="w-full"
                                placeholder="Enter category name"
                            />
                        </div>

                        <div>
                            <label for="updateDescription" class="block mb-2">Description</label>
                            <Textarea
                                id="updateDescription"
                                v-model="category.description"
                                class="w-full"
                                rows="3"
                                placeholder="Enter category description"
                            />
                        </div>

                        <div class="flex justify-end gap-2">
                            <Button
                                type="button"
                                label="Cancel"
                                severity="secondary"
                                @click="showUpdateCategoryDialog = false"
                            />
                            <Button
                                type="button"
                                label="Update"
                                @click="updateCategory"
                            />
                        </div>
                    </div>
                </Dialog>

                <!-- Delete Category Modal -->
                <Dialog
                    v-model:visible="showDeleteCategoryDialog"
                    header="Confirm Delete"
                    :style="{ width: '30rem' }"
                    modal
                >
                    <div class="flex items-center">
                        <span class="text-gray-700">Are you sure you want to delete this category?</span>
                    </div>

                    <template #footer>
                        <div class="flex justify-end space-x-3">
                            <Button
                                label="Cancel"
                                icon="pi pi-times"
                                @click="showDeleteCategoryDialog = false"
                                class="p-button-outlined p-button-secondary"
                            />
                            <Button
                                label="Delete"
                                icon="pi pi-trash"
                                @click="deleteCategory"
                                class="p-button-danger"
                            />
                        </div>
                    </template>
                </Dialog>
            </div>
        </div>
    </div>
</template>
