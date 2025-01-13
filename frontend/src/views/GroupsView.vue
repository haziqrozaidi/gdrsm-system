<script setup>
    import { ref, onMounted } from 'vue'
    import { useConfirm } from "primevue/useconfirm";
    import { useToast } from "primevue/usetoast";
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
    import ConfirmDialog from 'primevue/confirmdialog'
    import Toast from 'primevue/toast'
    import MultiSelect from 'primevue/multiselect'

    const confirm = useConfirm();
    const toast = useToast();

    const user = ref({})
    const groups = ref([])
    const showCreateGroupDialog = ref(false)
    const showShareResourceDialog = ref(false)
    const showEditGroupDialog = ref(false)
    const selectedGroup = ref(null)
    const selectedResourcesToShare = ref([])
    const groupResources = ref([])
    const groupMembers = ref([])
    const userOwnedResources = ref([])
    const availableUsers = ref([])
    const selectedUsersToAdd = ref([])
    const showAddMembersDialog = ref(false)


    const group = ref({
        name: '',
        description: ''
    })

    const editingGroup = ref({
        group_id: null,
        name: '',
        description: ''
    })

    const openEditGroupDialog = (group) => {
        editingGroup.value = {
            group_id: group.group_id,
            name: group.name,
            description: group.description
        }
        showEditGroupDialog.value = true
    }

    const closeEditGroupDialog = () => {
        showEditGroupDialog.value = false
        editingGroup.value = {
            group_id: null,
            name: '',
            description: ''
        }
    }

    const openShareResourceDialog = () => {
        fetchUserOwnedResources();
        showShareResourceDialog.value = true;
    }

    const closeShareResourceDialog = () => {
        showShareResourceDialog.value = false;
        selectedResourcesToShare.value = [];
    }

    const openAddMembersDialog = () => {
        fetchAvailableUsers();
        showAddMembersDialog.value = true;
    }

    const closeAddMembersDialog = () => {
        showAddMembersDialog.value = false;
        selectedUsersToAdd.value = [];
    }

    const fetchUserGroups = async () => {
        try {
            const url = user.value?.description === 'admin'
                ? 'http://127.0.0.1:3000/api/admin/groups'
                : 'http://127.0.0.1:3000/api/groups';

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

            groups.value = await response.json();
        } catch (error) {
            console.error('Failed to fetch groups:', error.message);
        }
    }

    const fetchGroupDetails = async (groupId) => {
        try {
            // Fetch group resources
            const url = user.value?.description === 'admin'
                ? `http://127.0.0.1:3000/api/admin/groups/${groupId}/resources`
                : `http://127.0.0.1:3000/api/groups/${groupId}/resources`;

            const resourcesResponse = await fetch(url, {
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

            const url2 = user.value?.description === 'admin'
                ? `http://127.0.0.1:3000/api/admin/groups/${groupId}/members`
                : `http://127.0.0.1:3000/api/groups/${groupId}/members`;

            // Fetch group members
            const membersResponse = await fetch(url2, {
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

    const leaveGroup = async (groupId) => {
        try {
            const response = await fetch(`http://127.0.0.1:3000/api/groups/${groupId}/leave`, {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Leaving group failed');
            }

            // Refresh the groups list
            await fetchUserGroups();

            toast.add({
                severity: 'success',
                summary: 'Group Left',
                detail: 'You have successfully left the group',
                life: 3000
            });
        } catch (error) {
            console.error('Failed to leave group:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Leave Failed',
                detail: error.message,
                life: 3000
            });
        }
    }

    const confirmLeaveGroup = (groupId) => {
        confirm.require({
            message: 'Are you sure you want to leave this group?',
            header: 'Confirm Group Leaving',
            icon: 'pi pi-info-circle',
            rejectProps: {
                label: 'Cancel',
                severity: 'secondary',
                outlined: true
            },
            acceptProps: {
                label: 'Leave',
                severity: 'warning'
            },
            accept: () => leaveGroup(groupId),
            reject: () => {
                toast.add({
                    severity: 'info',
                    summary: 'Cancelled',
                    detail: 'Group leaving cancelled',
                    life: 3000
                });
            }
        });
    }

    const deleteGroup = async (groupId) => {
        try {
            const url = user.value?.description === 'admin'
                ? `http://127.0.0.1:3000/api/admin/groups/${groupId}`
                : `http://127.0.0.1:3000/api/groups/${groupId}`;
            const response = await fetch(url, {
                method: 'DELETE',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Group deletion failed');
            }

            // Refresh the groups list
            await fetchUserGroups();

            toast.add({
                severity: 'success',
                summary: 'Group Deleted',
                detail: 'Group has been successfully deleted',
                life: 3000
            });
        } catch (error) {
            console.error('Failed to delete group:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Deletion Failed',
                detail: error.message,
                life: 3000
            });
        }
    }

    const confirmDeleteGroup = (groupId) => {
        confirm.require({
            message: 'Are you sure you want to delete this group?',
            header: 'Confirm Group Deletion',
            icon: 'pi pi-exclamation-triangle',
            rejectProps: {
                label: 'Cancel',
                severity: 'secondary',
                outlined: true
            },
            acceptProps: {
                label: 'Delete',
                severity: 'danger'
            },
            accept: () => deleteGroup(groupId),
            reject: () => {
                toast.add({
                    severity: 'info',
                    summary: 'Cancelled',
                    detail: 'Group deletion cancelled',
                    life: 3000
                });
            }
        });
    }

    const updateGroup = async () => {
        try {
            const url = user.value?.description === 'admin'
                ? `http://127.0.0.1:3000/api/admin/groups/${editingGroup.value.group_id}`
                : `http://127.0.0.1:3000/api/groups/${editingGroup.value.group_id}`;

            const response = await fetch(url, {
                method: 'PUT',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    name: editingGroup.value.name,
                    description: editingGroup.value.description
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Group update failed');
            }

            // Close the dialog
            showEditGroupDialog.value = false;

            // Refresh the groups list
            await fetchUserGroups();

            // Show success toast
            toast.add({
                severity: 'success',
                summary: 'Group Updated',
                detail: 'Group has been successfully updated',
                life: 3000
            });
        } catch (error) {
            console.error('Failed to update group:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Update Failed',
                detail: error.message,
                life: 3000
            });
        }
    }

    const fetchUserOwnedResources = async () => {
        try {
            const response = await fetch('http://127.0.0.1:3000/api/resources', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            userOwnedResources.value = await response.json();
        } catch (error) {
            console.error('Failed to fetch owned resources:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Fetch Failed',
                detail: 'Could not fetch your resources',
                life: 3000
            });
        }
    }

    const shareResourcesWithGroup = async () => {
        if (!selectedGroup.value || selectedResourcesToShare.value.length === 0) {
            toast.add({
                severity: 'warn',
                summary: 'Invalid Selection',
                detail: 'Please select resources to share',
                life: 3000
            });
            return;
        }

        try {
            const response = await fetch('http://127.0.0.1:3000/api/groups/resources/share', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    group_id: selectedGroup.value.group_id,
                    resource_ids: selectedResourcesToShare.value.map(r => r.resource_id)
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Resource sharing failed');
            }

            // Refresh group resources
            await fetchGroupDetails(selectedGroup.value.group_id);

            // Reset dialog
            showShareResourceDialog.value = false;
            selectedResourcesToShare.value = [];

            toast.add({
                severity: 'success',
                summary: 'Resources Shared',
                detail: 'Resources successfully shared with the group',
                life: 3000
            });
        } catch (error) {
            console.error('Failed to share resources:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Sharing Failed',
                detail: error.message,
                life: 3000
            });
        }
    }

    const deleteGroupResource = async (resourceId) => {
        try {
            const response = await fetch(`http://127.0.0.1:3000/api/groups/${selectedGroup.value.group_id}/resources/delete`, {
                method: 'DELETE',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ resource_id: resourceId })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Resource deletion failed');
            }

            // Refresh group resources
            await fetchGroupDetails(selectedGroup.value.group_id);

            toast.add({
                severity: 'success',
                summary: 'Resource Removed',
                detail: 'Resource has been removed from the group',
                life: 3000
            });
        } catch (error) {
            console.error('Failed to delete resource from group:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Deletion Failed',
                detail: error.message,
                life: 3000
            });
        }
    }

    const confirmDeleteGroupResource = (resourceId) => {
        confirm.require({
            message: 'Are you sure you want to remove this resource from the group?',
            header: 'Confirm Resource Removal',
            icon: 'pi pi-exclamation-triangle',
            rejectProps: {
                label: 'Cancel',
                severity: 'secondary',
                outlined: true
            },
            acceptProps: {
                label: 'Remove',
                severity: 'danger'
            },
            accept: () => deleteGroupResource(resourceId),
            reject: () => {
                toast.add({
                    severity: 'info',
                    summary: 'Cancelled',
                    detail: 'Resource removal cancelled',
                    life: 3000
                });
            }
        });
    }

    const fetchAvailableUsers = async () => {
        try {
            const response = await fetch('http://127.0.0.1:3000/api/users', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`Response status: ${response.status}`);
            }

            availableUsers.value = await response.json();
        } catch (error) {
            console.error('Failed to fetch available users:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Fetch Failed',
                detail: 'Could not fetch available users',
                life: 3000
            });
        }
    }

    const addGroupMembers = async () => {
        if (!selectedGroup.value || selectedUsersToAdd.value.length === 0) {
            toast.add({
                severity: 'warn',
                summary: 'Invalid Selection',
                detail: 'Please select users to add',
                life: 3000
            });
            return;
        }

        try {
            const url = user.value?.description === 'admin'
                ? `http://127.0.0.1:3000/api/admin/groups/${selectedGroup.value.group_id}/members`
                : `http://127.0.0.1:3000/api/groups/${selectedGroup.value.group_id}/members`;

            const response = await fetch(url, {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    user_ids: selectedUsersToAdd.value.map(u => u.user_id)
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Adding members failed');
            }

            // Refresh group members
            await fetchGroupDetails(selectedGroup.value.group_id);

            // Reset dialog
            showAddMembersDialog.value = false;
            selectedUsersToAdd.value = [];

            toast.add({
                severity: 'success',
                summary: 'Members Added',
                detail: 'Users successfully added to the group',
                life: 3000
            });
        } catch (error) {
            console.error('Failed to add members:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Adding Failed',
                detail: error.message,
                life: 3000
            });
        }
    }

    const removeGroupMember = async (userId) => {
        if (!selectedGroup.value) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'No group selected',
                life: 3000
            });
            return;
        }

        try {
            const url = user.value?.description === 'admin'
                ? `http://127.0.0.1:3000/api/admin/groups/${selectedGroup.value.group_id}/members`
                : `http://127.0.0.1:3000/api/groups/${selectedGroup.value.group_id}/members`;

            const response = await fetch(url, {
                method: 'DELETE',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ user_id: userId })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Member removal failed');
            }

            // Refresh group members
            await fetchGroupDetails(selectedGroup.value.group_id);

            toast.add({
                severity: 'success',
                summary: 'Member Removed',
                detail: 'User has been removed from the group',
                life: 3000
            });
        } catch (error) {
            console.error('Failed to remove group member:', error.message);
            toast.add({
                severity: 'error',
                summary: 'Removal Failed',
                detail: error.message,
                life: 3000
            });
        }
    }

    const confirmRemoveGroupMember = (userId) => {
        confirm.require({
            message: 'Are you sure you want to remove this member from the group?',
            header: 'Confirm Member Removal',
            icon: 'pi pi-exclamation-triangle',
            rejectProps: {
                label: 'Cancel',
                severity: 'secondary',
                outlined: true
            },
            acceptProps: {
                label: 'Remove',
                severity: 'danger'
            },
            accept: () => removeGroupMember(userId),
            reject: () => {
                toast.add({
                    severity: 'info',
                    summary: 'Cancelled',
                    detail: 'Member removal cancelled',
                    life: 3000
                });
            }
        });
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
    <Toast />
    <ConfirmDialog></ConfirmDialog>
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
                        <Column field="membership_status" header="Owner/Category">
                            <template #body="{ data }">
                                <Tag
                                    v-if="user?.description !== 'admin'"
                                    :value="data.membership_status"
                                    :severity="data.membership_status === 'Created' ? 'success' : 'info'"
                                    rounded
                                />
                                <span v-else>
                                    {{ data.owner_email }}
                                </span>
                            </template>
                        </Column>
                        <Column field="description" header="Description"></Column>
                        <Column field="date_created" header="Date Created"></Column>
                        <Column header="Actions">
                            <template #body="{ data }">
                                <Button
                                    v-if="data.membership_status === 'Created'"
                                    icon="pi pi-pencil"
                                    outlined
                                    rounded
                                    severity="secondary"
                                    class="mr-2"
                                    @click="openEditGroupDialog(data)"
                                />
                                <Button
                                    v-if="data.membership_status === 'Created'"
                                    icon="pi pi-trash"
                                    outlined
                                    rounded
                                    severity="danger"
                                    class="mr-2"
                                    @click="confirmDeleteGroup(data.group_id)"
                                />
                                <Button
                                    v-else-if="data.membership_status === 'Invited'"
                                    icon="pi pi-sign-out"
                                    outlined
                                    rounded
                                    severity="danger"
                                    @click="confirmLeaveGroup(data.group_id)"
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
                            <div class="flex justify-end mb-3" v-if="selectedGroup.membership_status === 'Created'">
                                <Button
                                    label="Share Resources"
                                    icon="pi pi-share-alt"
                                    @click="openShareResourceDialog"
                                />
                            </div>
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
                                            v-if="selectedGroup.membership_status === 'Created'"
                                            icon="pi pi-trash"
                                            outlined
                                            rounded
                                            severity="danger"
                                            @click="confirmDeleteGroupResource(data.resource_id)"
                                            title="Remove Resource from Group"
                                        />
                                    </template>
                                </Column>
                            </DataTable>
                        </TabPanel>
                        <TabPanel header="Members">
                            <div class="flex justify-end mb-3" v-if="selectedGroup.membership_status === 'Created'">
                                <Button
                                    label="Add Members"
                                    icon="pi pi-plus"
                                    @click="openAddMembersDialog"
                                />
                            </div>
                            <DataTable :value="groupMembers" stripedRows :sortField="'is_owner'" :sortOrder="-1">
                                <Column field="full_name" header="Full Name"></Column>
                                <Column field="role" header="Role"></Column>
                                <Column field="email" header="Email"></Column>
                                <Column field="username" header="Username"></Column>
                                <Column field="date_joined" header="Joined Date"></Column>
                                <Column header="Actions" v-if="selectedGroup.membership_status === 'Created'">
                                    <template #body="{ data }">
                                        <Button
                                            v-if="!data.is_owner && data.user_id !== user.user_id"
                                            icon="pi pi-trash"
                                            outlined
                                            rounded
                                            severity="danger"
                                            @click="confirmRemoveGroupMember(data.user_id)"
                                            title="Remove Member from Group"
                                        />
                                        <Button
                                            v-else
                                            icon="pi pi-trash"
                                            outlined
                                            rounded
                                            severity="danger"
                                            class="invisible"
                                        />
                                    </template>
                                </Column>
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

                <!-- Edit Group Dialog -->
                <Dialog
                    v-model:visible="showEditGroupDialog"
                    modal
                    header="Edit Group"
                    :style="{ width: '30rem' }"
                    @hide="closeEditGroupDialog"
                >
                    <div class="flex items-center gap-4 mb-4">
                        <label for="editGroupName" class="font-semibold w-24">Group Name</label>
                        <InputText
                            id="editGroupName"
                            v-model="editingGroup.name"
                            class="flex-auto"
                            autocomplete="off"
                            placeholder="Enter group name"
                        />
                    </div>

                    <div class="flex items-center gap-4 mb-8">
                        <label for="editGroupDescription" class="font-semibold w-24">Description</label>
                        <Textarea
                            id="editGroupDescription"
                            v-model="editingGroup.description"
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
                            @click="closeEditGroupDialog"
                        />
                        <Button
                            type="button"
                            label="Update"
                            @click="updateGroup"
                            :disabled="!editingGroup.name"
                        />
                    </div>
                </Dialog>

                <!-- Share Resources Dialog -->
                <Dialog
                    v-model:visible="showShareResourceDialog"
                    modal
                    header="Share Resources with Group"
                    :style="{ width: '40rem' }"
                    @hide="closeShareResourceDialog"
                >
                    <div class="mb-4">
                        <label for="resourceMultiSelect" class="font-semibold block mb-2">
                            Select Resources to Share
                        </label>
                        <MultiSelect
                            id="resourceMultiSelect"
                            v-model="selectedResourcesToShare"
                            :options="userOwnedResources"
                            optionLabel="name"
                            placeholder="Select Resources"
                            display="chip"
                            class="w-full"
                        />
                    </div>

                    <div class="flex justify-end gap-2">
                        <Button
                            type="button"
                            label="Cancel"
                            severity="secondary"
                            @click="closeShareResourceDialog"
                        />
                        <Button
                            type="button"
                            label="Share"
                            @click="shareResourcesWithGroup"
                            :disabled="selectedResourcesToShare.length === 0"
                        />
                    </div>
                </Dialog>

                <!-- Add Members Dialog -->
                <Dialog
                    v-model:visible="showAddMembersDialog"
                    modal
                    header="Add Members to Group"
                    :style="{ width: '40rem' }"
                    @hide="closeAddMembersDialog"
                >
                    <div class="mb-4">
                        <label for="userMultiSelect" class="font-semibold block mb-2">
                            Select Users to Add
                        </label>
                        <MultiSelect
                            id="userMultiSelect"
                            v-model="selectedUsersToAdd"
                            :options="availableUsers.filter(user =>
                                !groupMembers.some(member => member.user_id === user.user_id)
                            )"
                            optionLabel="full_name"
                            placeholder="Select Users"
                            display="chip"
                            class="w-full"
                        />
                    </div>

                    <div class="flex justify-end gap-2">
                        <Button
                            type="button"
                            label="Cancel"
                            severity="secondary"
                            @click="closeAddMembersDialog"
                        />
                        <Button
                            type="button"
                            label="Add"
                            @click="addGroupMembers"
                            :disabled="selectedUsersToAdd.length === 0"
                        />
                    </div>
                </Dialog>
            </div>
        </div>
    </div>
</template>
