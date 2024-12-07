<script setup>
    import Menu from 'primevue/menu';
    import { ref } from 'vue';
    import { useRouter } from 'vue-router';

    const router = useRouter();

    const items = ref([
        {
            label: 'Home',
            items: [
                {
                    label: 'Dashboard',
                    icon: 'pi pi-home',
                    route: '/dashboard'
                }
            ]
        },
        {
            label: 'Shared Resources',
            items: [
                {
                    label: 'Files',
                    icon: 'pi pi-file',
                    route: '/files'
                },
                {
                    label: 'Folders',
                    icon: 'pi pi-folder',
                    route: '/folders'
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
    <Menu :model="items">
        <template #item="{ item, props }">
            <router-link v-if="item.route" v-slot="{ href, navigate }" :to="item.route" custom>
                <a v-ripple :href="href" v-bind="props.action" @click="navigate">
                    <span :class="item.icon" />
                    <span class="ml-2">{{ item.label }}</span>
                </a>
            </router-link>
            <a v-else v-ripple :href="item.url" :target="item.target" v-bind="props.action">
                <span :class="item.icon" />
                <span class="ml-2">{{ item.label }}</span>
            </a>
        </template>
    </Menu>
</template>

<style scoped>
</style>
