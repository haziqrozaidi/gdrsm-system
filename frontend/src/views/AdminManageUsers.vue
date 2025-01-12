<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router'; // To handle redirection after role change
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import Sidebar from '../components/Sidebar.vue';
import Tag from 'primevue/tag';

const users = ref([]);
const loading = ref(false);
const selectedUser = ref(null);
const showChangeRoleDialog = ref(false);
const showDeleteUserDialog = ref(false);
const router = useRouter(); // To handle navigation

// Fetch users on component mount
const fetchUsers = async () => {
  loading.value = true;
  try {
    const response = await fetch('http://127.0.0.1:3000/api/admin/users', {
      method: 'GET',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }

    users.value = await response.json(); // Update the users array
  } catch (error) {
    console.error('Failed to fetch users:', error.message);
  } finally {
    loading.value = false;
  }
};

// Open the dialog to change the role
const openChangeRoleDialog = (user) => {
  if (user.role !== 'Pensyarah' && user.role !== 'Admin') {
    alert('Only users with the role "Pensyarah" or "Admin" can have their roles changed.');
    return;
  }
  selectedUser.value = user;
  showChangeRoleDialog.value = true;
  
};

// Confirm role change and update the role
const confirmRoleChange = async () => {
  if (!selectedUser.value) return;

  const newRole = selectedUser.value.role === 'Admin' ? 'Pensyarah' : 'Admin'; // Toggle role

  const confirm = window.confirm(`Are you sure you want to change "${selectedUser.value.full_name}"'s role to "${newRole}"?`);

  if (confirm) {
    try {
      const response = await fetch('http://127.0.0.1:3000/api/admin/users/update-role', {
        method: 'PUT',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          full_name: selectedUser.value.full_name,
          role: newRole,
        }),
      });
      await fetchUsers();

      // Close the dialog and reset the selected user
      showChangeRoleDialog.value = false;
      selectedUser.value = null;
      const result = await response.json();

      if (!response.ok || !result.success) {
        throw new Error(result.error || 'Failed to update role');
      }

      if (result.logged_out) {
        alert('Your role has been changed to Pensyarah, and you no longer have admin privileges.');
        router.push('/login'); // Redirect to login
        return;
      }
      // Re-fetch the users list to reflect the changes
      

    } catch (error) {
      console.error('Failed to change user role:', error.message);
    }
  } else {
    showChangeRoleDialog.value = false;
  }
};

const openDeleteUserDialog = async (user) => {
  selectedUser.value = user;

  try {
    const response = await fetch('http://127.0.0.1:3000/api/admin/users/check-dependencies', {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
          user_id: selectedUser.value.user_id,
        }),
    });
    if (!response.ok) {
      throw new Error('Failed to check dependencies');
    }

    const result = await response.json();
    if (result.hasDependencies) {
      alert(`Cannot delete "${user.full_name}". They have ${result.resourceCount} associated resource(s).`);
      return;
    }

    showDeleteUserDialog.value = true;
  } catch (error) {
    console.error('Error checking dependencies:', error.message);
  }
};

const confirmDeleteUser = async () => {
  if (!selectedUser.value) return;

  const confirm = window.confirm(`Are you sure you want to delete "${selectedUser.value.full_name}"?`);

  if (confirm) {
    try {
      const response = await fetch('http://127.0.0.1:3000/api/admin/users/delete', {
        method: 'DELETE',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_id: selectedUser.value.user_id,
        }),
      });

      if (!response.ok) {
        throw new Error(`Failed to delete user: ${response.status}`);
      }

      await fetchUsers();
      showDeleteUserDialog.value = false;
      selectedUser.value = null;
    } catch (error) {
      console.error('Failed to delete user:', error.message);
    }
  } else {
    showDeleteUserDialog.value = false;
  }
};
// On component mount, fetch the users
onMounted(() => {
  fetchUsers();
});
</script>

<template>
  <div class="flex min-h-screen">
    <Sidebar />
    <div class="grow bg-gray-100 p-4">
      <div class="card">
        <h2 class="text-2xl font-bold mb-4">Manage Users</h2>

        <DataTable :value="users" :loading="loading" stripedRows>
          <Column field="full_name" header="Name"></Column>
          <Column field="email" header="Email"></Column>
          <Column field="role" header="Role" sortable>
            <template #body="{ data }">
              <Tag :value="data.role" severity="info" rounded />
            </template>
          </Column>
          <Column header="Actions">
            <template #body="{ data }">
              <Button
                v-if="data.role === 'Pensyarah' || data.role === 'Admin'"
                icon="pi pi-user-edit"
                label="Change Role"
                outlined
                class="mr-2"
                @click="openChangeRoleDialog(data)"
              />
              <Button
                icon="pi pi-trash"
                label="Delete User"
                outlined
                class="mr-2"
                @click="openDeleteUserDialog(data)"
              />
            </template>
          </Column>
        </DataTable>

        <!-- Change Role Confirmation Dialog -->
        <Dialog
          v-model:visible="showChangeRoleDialog"
          header="Confirm Role Change"
          :style="{ width: '30rem' }"
          modal
        >
          <div class="flex flex-col space-y-4">
            <p class="text-gray-700">
              Are you sure you want to change <strong>{{ selectedUser?.full_name }}</strong>'s role to 
              <strong>{{ selectedUser?.role === 'Admin' ? 'Pensyarah' : 'Admin' }}</strong>?
            </p>
          </div>

          <template #footer>
            <div class="flex justify-end space-x-3">
              <Button
                label="Cancel"
                icon="pi pi-times"
                @click="showChangeRoleDialog = false"
                class="p-button-outlined p-button-secondary"
              />
              <Button
                label="Confirm"
                icon="pi pi-check"
                @click="confirmRoleChange"
                class="p-button-primary"
              />
            </div>
          </template>
        </Dialog>

        <!-- Delete User Confirmation Dialog -->
        <Dialog
          v-model:visible="showDeleteUserDialog"
          header="Confirm User Deletion"
          :style="{ width: '30rem' }"
          modal
        >
          <div class="flex flex-col space-y-4">
            <p class="text-gray-700">
              Are you sure you want to delete <strong>{{ selectedUser?.full_name }}</strong>?
            </p>
          </div>

          <template #footer>
            <div class="flex justify-end space-x-3">
              <Button
                label="Cancel"
                icon="pi pi-times"
                @click="showDeleteUserDialog = false"
                class="p-button-outlined p-button-secondary"
              />
              <Button
                label="Confirm"
                icon="pi pi-check"
                @click="confirmDeleteUser"
                class="p-button-danger"
              />
            </div>
          </template>
        </Dialog>
      </div>
    </div>
  </div>
</template>