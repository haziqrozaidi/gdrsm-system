<script setup>
    import { ref, onMounted } from 'vue'
    import Sidebar from '../components/Sidebar.vue'
    import DataTable from 'primevue/datatable'
    import Column from 'primevue/column'
    import Button from 'primevue/button'
    import Dialog from 'primevue/dialog'
    import InputText from 'primevue/inputtext'
    import Textarea from 'primevue/textarea'
    import TabView from 'primevue/tabview'
    import TabPanel from 'primevue/tabpanel'
    import Tag from 'primevue/tag'

    const user = ref({})
    const groups = ref([])
    const showCreateGroupDialog = ref(false)
    const selectedGroup = ref(null)
    const groupResources = ref([])
    const groupMembers = ref([])

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

    const fetchGroupDetails = async (groupId) => {
        try {
            // Fetch group resources
            const resourcesResponse = await fetch(`http://127.0.0.1:3000/api/groups/${groupId}/resources`, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!resourcesResponse.ok) {
                throw new Error(`Resources response status: ${resourcesResponse.status}`);
            }

            groupResources.value = await resourcesResponse.json();

            // Fetch group members
            const membersResponse = await fetch(`http://127.0.0.1:3000/api/groups/${groupId}/members`, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!membersResponse.ok) {
                throw new Error(`Members response status: ${membersResponse.status}`);
            }

            groupMembers.value = await membersResponse.json();
        } catch (error) {
            console.error('Failed to fetch group details:', error.message);
        }
    }

    const createGroup = async () => {
        try {
            const response = await fetch('http://127.0.0.1:3000/api/groups', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    name: group.value.name,
                    description: group.value.description
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Group creation failed');
            }

            const newGroup = await response.json();
            console.log('Group created successfully:', newGroup);

            // Reset the group form
            group.value = {
                name: '',
                description: ''
            };

            // Close the dialog
            showCreateGroupDialog.value = false;

            // Refresh the groups list
            await fetchUserGroups();

        } catch (error) {
            console.error('Failed to create group:', error.message);
        }
    }

    const closeCreateGroupDialog = () => {
        group.value = {
            name: '',
            description: ''
        };
        showCreateGroupDialog.value = false;
    }

    const onRowSelect = (event) => {
        selectedGroup.value = event.data;
        fetchGroupDetails(event.data.group_id);
    }

    const backToGroupList = () => {
        selectedGroup.value = null;
    }

    const openResourceLink = (link) => {
        window.open(link, '_blank');
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
                <div v-if="!selectedGroup" class="flex justify-between mb-4">
                    <h2 class="text-2xl font-bold">Group Management</h2>
                    <Button
                        label="Create New Group"
                        icon="pi pi-plus"
                        @click="showCreateGroupDialog = true"
                    />
                </div>

                <div v-if="!selectedGroup">
                    <DataTable
                        :value="groups"
                        stripedRows
                        selectionMode="single"
                        @row-select="onRowSelect"
                    >
                        <Column field="name" header="Group Name"></Column>
                        <Column field="membership_status" header="Category">
                            <template #body="{ data }">
                                <Tag
                                    :value="data.membership_status"
                                    :severity="data.membership_status === 'Created' ? 'success' : 'info'"
                                    rounded
                                />
                            </template>
                        </Column>
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

                <div v-else>
                    <div class="flex justify-between mb-4">
                        <h2 class="text-2xl font-bold">
                            {{ selectedGroup.name }} Details
                        </h2>
                        <Button
                            label="Back to Groups"
                            icon="pi pi-arrow-left"
                            @click="backToGroupList"
                        />
                    </div>

                    <TabView>
                        <TabPanel header="Resources">
                            <DataTable :value="groupResources" stripedRows>
                                <Column field="name" header="Name"></Column>
                                <Column header="Category">
                                    <template #body="{ data }">
                                        <Tag :value="data.category_name" severity="info" rounded />
                                    </template>
                                </Column>
                                <Column field="description" header="Description"></Column>
                                <Column field="owner" header="Owner"></Column>
                                <Column field="date_created" header="Date Added"></Column>
                                <Column header="Session">
                                    <template #body="{ data }">
                                        {{ data.session }}-{{ data.semester }}
                                    </template>
                                </Column>
                                <Column header="Link">
                                    <template #body="{ data }">
                                        <Button
                                            icon="pi pi-external-link"
                                            class="p-button-text p-button-sm"
                                            @click="openResourceLink(data.link)"
                                        />
                                    </template>
                                </Column>
                            </DataTable>
                        </TabPanel>
                        <TabPanel header="Members">
                            <DataTable :value="groupMembers" stripedRows>
                                <Column field="full_name" header="Full Name"></Column>
                                <Column field="role" header="Role"></Column>
                                <Column field="email" header="Email"></Column>
                                <Column field="username" header="Username"></Column>
                                <Column field="date_joined" header="Joined Date"></Column>
                            </DataTable>
                        </TabPanel>
                    </TabView>
                </div>

                <!-- Create Group Dialog -->
                <Dialog
                    v-model:visible="showCreateGroupDialog"
                    modal
                    header="Create New Group"
                    :style="{ width: '30rem' }"
                     @hide="closeCreateGroupDialog"
                >
                    <div class="flex items-center gap-4 mb-4">
                        <label for="groupName" class="font-semibold w-24">Group Name</label>
                        <InputText
                            id="groupName"
                            v-model="group.name"
                            class="flex-auto"
                            autocomplete="off"
                            placeholder="Enter group name"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-8">
                        <label for="groupDescription" class="font-semibold w-24">Description</label>
                        <Textarea
                            id="groupDescription"
                            v-model="group.description"
                            class="flex-auto"
                            rows="3"
                            placeholder="Enter group description"
                        />
                    </div>

                    <div class="flex justify-end gap-2">
                        <Button
                            type="button"
                            label="Cancel"
                            severity="secondary"
                            @click="closeCreateGroupDialog"
                        />
                        <Button
                            type="button"
                            label="Create"
                            @click="createGroup"
                            :disabled="!group.name"
                        />
                    </div>
                </Dialog>
            </div>
        </div>
    </div>
</template>
