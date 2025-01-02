<script setup>
import { ref, onMounted } from 'vue'
    import Sidebar from '../components/Sidebar.vue'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import InputText from 'primevue/inputtext'
    import Textarea from 'primevue/textarea'

    const user = ref({})
    const groups = ref([])
    const showCreateGroupDialog = ref(false)

    const group = ref({
        name: '',
        description: ''
    })

    const fetchUserGroups = async () => {
        try {
            const response = await fetch('http://127.0.0.1:3000/api/groups', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            groups.value = await response.json();
        } catch (error) {
            console.error('Failed to fetch groups:', error.message);
        }
    }

    onMounted(() => {
        const userString = sessionStorage.getItem('user')
        if (userString) {
            try {
                user.value = JSON.parse(userString)
                fetchUserGroups();
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
                    <h2 class="text-2xl font-bold">Group Management</h2>
                    <Button
                        label="Create New Group"
                        icon="pi pi-plus"
                        @click="showCreateGroupDialog = true"
                    />
                </div>

                <DataTable
                    :value="groups"
                    stripedRows
                >
                    <Column field="name" header="Group Name"></Column>
                    <Column field="description" header="Description"></Column>
                    <Column field="date_created" header="Date Created"></Column>
                    <Column header="Actions">
                        <template #body="{ data }">
                            <Button
                                icon="pi pi-sign-out"
                                class="p-button-danger p-button-sm"
                                @click="leaveGroup(data.group_id)"
                            />
                        </template>
                    </Column>
                </DataTable>
            </div>
        </div>
    </div>
</template>
