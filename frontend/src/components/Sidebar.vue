<script setup>
    import Menu from 'primevue/menu';
    import { ref } from 'vue';

    const items = ref([
        {
            label: 'Dashboard',
            icon: 'pi pi-home'
        },
        {
            label: 'Shared Resources',
            items: [
                {
                    label: 'Files',
                    icon: 'pi pi-file'
                },
                {
                    label: 'Folders',
                    icon: 'pi pi-folder'
                },
                {
                    label: 'Sharing',
                    icon: 'pi pi-users'
                }
            ]
        },
        {
            label: 'Documents',
            items: [
                {
                    label: 'New',
                    icon: 'pi pi-plus'
                },
                {
                    label: 'Search',
                    icon: 'pi pi-search'
                }
            ]
        },
        {
            label: 'Profile',
            items: [
                {
                    label: 'Settings',
                    icon: 'pi pi-cog'
                },
                {
                    label: 'Logout',
                    icon: 'pi pi-sign-out'
                }
            ]
        }
    ]);
</script>

<template>
    <Menu :model="items" />
</template>

<style scoped>
</style>
