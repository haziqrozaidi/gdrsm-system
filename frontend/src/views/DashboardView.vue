<script setup>
    import Button from 'primevue/button';
    import Card from 'primevue/card';
    import Sidebar from '../components/Sidebar.vue'
</script>

<template>
    <div class="flex min-h-screen">
        <Sidebar />
        <div class="grow bg-gray-100 p-4">
            <div class="container mx-auto">
                <h1 class="text-2xl font-bold mb-6 text-gray-800">Dashboard</h1>
                
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <!-- Quick Stats Cards -->
                    <Card class="shadow-md">
                        <template #title>Total Shared Resources</template>
                        <template #content>
                            <div class="text-3xl font-bold text-blue-600">42</div>
                            <div class="text-sm text-gray-500">Resources shared across courses</div>
                        </template>
                    </Card>

                    <Card class="shadow-md">
                        <template #title>Recent Uploads</template>
                        <template #content>
                            <div class="text-3xl font-bold text-green-600">17</div>
                            <div class="text-sm text-gray-500">New resources this week</div>
                        </template>
                    </Card>

                    <Card class="shadow-md">
                        <template #title>Active Collaborations</template>
                        <template #content>
                            <div class="text-3xl font-bold text-purple-600">6</div>
                            <div class="text-sm text-gray-500">Ongoing shared projects</div>
                        </template>
                    </Card>
                </div>

                <!-- Quick Actions -->
                <div class="mt-8">
                    <h2 class="text-xl font-semibold mb-4 text-gray-700">Quick Actions</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Button 
                            label="Upload New Resource" 
                            icon="pi pi-upload" 
                            class="p-button-primary w-full"
                        />
                        <Button 
                            label="Create Shared Folder" 
                            icon="pi pi-folder-plus" 
                            class="p-button-secondary w-full"
                        />
                    </div>
                </div>

                <!-- Recent Activity -->
                <div class="mt-8">
                    <h2 class="text-xl font-semibold mb-4 text-gray-700">Recent Activity</h2>
                    <Card>
                        <template #content>
                            <ul class="divide-y divide-gray-200">
                                <li class="py-3 flex justify-between items-center">
                                    <div>
                                        <span class="font-medium text-gray-800">Assignment Materials</span>
                                        <span class="block text-sm text-gray-500">Uploaded by John Doe</span>
                                    </div>
                                    <span class="text-sm text-gray-500">2 hours ago</span>
                                </li>
                                <li class="py-3 flex justify-between items-center">
                                    <div>
                                        <span class="font-medium text-gray-800">Research Paper</span>
                                        <span class="block text-sm text-gray-500">Shared by Jane Smith</span>
                                    </div>
                                    <span class="text-sm text-gray-500">Yesterday</span>
                                </li>
                            </ul>
                        </template>
                    </Card>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
</style>
