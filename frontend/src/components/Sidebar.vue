<script setup>
    import { ref } from 'vue';
    import { onMounted } from 'vue';
    import { useRouter } from 'vue-router';
    import Menu from 'primevue/menu';
    import Avatar from 'primevue/avatar';

    const router = useRouter();
    const userName = ref('');
    const userDescription = ref('');

    const logout = async () => {
        try {
            const response = await fetch('http://127.0.0.1:3000/api/users/logout', {
                method: 'POST',
                credentials: 'include'
            });

            if (response.ok) {
                sessionStorage.removeItem("user");
                router.push('/login');
            }
        } catch (error) {
            console.error("Logout failed", error);
        }
    }

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
                    label: 'Resources',
                    icon: 'pi pi-file',
                    route: '/files'
                },
                {
                    label: 'Folders',
                    icon: 'pi pi-folder',
                    route: '/folders'
                },
                {
                    label: 'Categories',
                    icon: 'pi pi-tag',
                    route: '/categories'
                },
                {
                    label: 'Sharing',
                    icon: 'pi pi-share-alt',
                    route: '/sharing'
                },
                {
                    label: 'Groups',
                    icon: 'pi pi-users',
                    route: '/groups'
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
                    icon: 'pi pi-search',
                    route:'/search'
                }
            ]
        },
        {
            label: 'Profile',
            items: [
                {
                    label: 'Settings',
                    icon: 'pi pi-cog',
                    route:'/setting'
                },
                {
                    label: 'Logout',
                    icon: 'pi pi-sign-out',
                    command: logout
                }
            ]
        }
    ]);

    onMounted(() => {
        const userString = sessionStorage.getItem('user');
        if (userString) {
            try {
                const user = JSON.parse(userString);
                userName.value = user.login_name || 'User';
                userDescription.value = user.description || 'Role';
            } catch (error) {
                console.error('Error parsing user data:', error);
                userName.value = 'User';
                userDescription.value = 'Role';
            }
        }
    });
</script>

<template>
    <Menu :model="items">
        <template #start>
            <button
                v-ripple
                class="relative overflow-hidden w-full border-0 bg-transparent flex items-center p-2 pl-4 hover:bg-surface-100 dark:hover:bg-surface-800 rounded-none cursor-pointer transition-colors duration-200"
            >
                <Avatar
                    icon="pi pi-user"
                    class="mr-2"
                    shape="circle"
                />
                <span class="inline-flex flex-col items-start">
                    <span class="font-bold">{{ userName }}</span>
                    <span class="text-sm">{{ userDescription }}</span>
                </span>
            </button>
        </template>
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
