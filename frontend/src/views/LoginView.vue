<script setup>
    import InputText from 'primevue/inputtext';
    import Button from 'primevue/button';
    import Card from 'primevue/card';
    import { ref } from "vue";
    import { RouterLink } from 'vue-router'

    const username = ref('');
    const password = ref('');
</script>

<template>
    <div class="flex justify-center items-center min-h-screen bg-gray-100 p-4">
        <Card class="w-full max-w-md shadow-lg p-6 pb-0">
            <template #title>
                <h1 class="text-3xl font-bold text-center pb-4">Sign in to your account</h1>
            </template>
            <template #content>
                <form class="flex flex-col gap-4">
                    <div class="flex flex-col gap-2">
                        <label for="username">Username</label>
                        <InputText
                            id="username"
                            v-model="username"
                            required
                            class="w-full"
                        />
                    </div>
                    <div class="flex flex-col gap-2">
                        <label for="password">Password</label>
                        <InputText
                            id="password"
                            v-model="password"
                            type="password"
                            required
                            class="w-full"
                        />
                    </div>
                    <Button class="w-full mt-4" type="submit" label="Sign in" />
                    <p class="text-center">Don't have an account? <RouterLink to="/register" class="text-black hover:underline font-semibold duration-300">Sign up</RouterLink></p>
                </form>
            </template>
        </Card>
    </div>
</template>

<style scoped>
</style>
