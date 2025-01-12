<script setup>
import { ref, onMounted } from "vue";
import DataTable from "primevue/datatable";
import Column from "primevue/column";
import Button from "primevue/button";
import Dialog from "primevue/dialog";
import Sidebar from "../components/Sidebar.vue";
import Tag from "primevue/tag";

const users = ref([]);
const loading = ref(false);
const selectedUser = ref(null);
const newRole = ref(""); // Add this to track the selected new role (e.g., 'Admin')
const showChangeRoleDialog = ref(false);

const fetchUsers = async () => {
  loading.value = true;
  try {
    const response = await fetch("http://127.0.0.1:3000/api/admin/users", {
      method: "GET",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }

    users.value = await response.json();
  } catch (error) {
    console.error("Failed to fetch users:", error.message);
  } finally {
    loading.value = false;
  }
};

const openChangeRoleDialog = (user) => {
  if (user.role !== "Pensyarah") {
    alert('Only users with the role "Pensyarah" can have their roles changed.');
    return;
  }
  selectedUser.value = user;
  showChangeRoleDialog.value = true;
};

const confirmRoleChange = async () => {
  if (!selectedUser.value) return;

  if (selectedUser.value.role !== "Pensyarah") {
    alert("This user cannot be given admin role.");
    showChangeRoleDialog.value = false;
    return;
  }

  const confirm = window.confirm(
    `Are you sure you want to give "${selectedUser.value.full_name}" the "Admin" role?`
  );

  if (confirm) {
    try {
        const requestBody = {
        full_name: selectedUser.value.full_name,
        role: "Admin",
      };

      console.log("Request Body:", requestBody);
      const response = await fetch(
        `http://127.0.0.1:3000/api/admin/users/update-role`,
        {
          method: "PUT",
          credentials: "include",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(requestBody),
        }
      );

      if (!response.ok) {
        throw new Error(`Response status: ${response.status}`);
      }

      await fetchUsers();
      showChangeRoleDialog.value = false;
      selectedUser.value = null;
    } catch (error) {
      console.error("Failed to change user role:", error.message);
    }
  } else {
    showChangeRoleDialog.value = false;
  }
};

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
          <Column field="name" header="Name"></Column>
          <Column field="email" header="Email"></Column>
          <Column field="role" header="Role">
            <template #body="{ data }">
              <Tag :value="data.role" severity="info" rounded />
            </template>
          </Column>
          <Column header="Actions">
            <template #body="{ data }">
              <!-- Show button only for users with the "Pensyarah" role -->
              <Button
                v-if="data.role === 'Pensyarah'"
                icon="pi pi-user-edit"
                label="Change Role"
                outlined
                class="mr-2"
                @click="openChangeRoleDialog(data)"
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
              Are you sure you want to give
              <strong>{{ selectedUser?.full_name }}</strong> the "Admin" role?
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
      </div>
    </div>
  </div>
</template>
  
