<script setup>
    import InputText from 'primevue/inputtext';
    import Button from 'primevue/button';
    import Select from 'primevue/select';
    import Card from 'primevue/card';
    import { ref } from "vue";

    const username = ref('');
    const full_name = ref('');
    const email = ref('');
    const password = ref('');
    const faculty = ref(null);

    const faculties = ref([
        { name: 'Faculty of Computing', code: 'FC' },
        { name: 'Faculty of Science', code: 'FS' },
        { name: 'Faculty of Management', code: 'FM' },
        { name: 'Faculty of Education', code: 'FP' },
        { name: 'Faculty of Civil Engineering', code: 'FKA' }
    ]);

    const registerUser = async () => {
        try {
            const response = await fetch('http://127.0.0.1:3000/api/users/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    username: username.value,
                    full_name: full_name.value,
                    email: email.value,
                    password: password.value,
                    faculty: faculty.value
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('Success:', data);

            alert('Account created successfully!');

        } catch (error) {
            console.error('Error:', error);
            alert('Failed to create account. Please try again.');
        }
    }
</script>

<template>
    <div class="flex justify-center items-center min-h-screen bg-gray-100 p-4">
        <Card class="w-full max-w-md shadow-lg">
            <template #title>
                <h1 class="text-3xl font-bold text-center pb-4">Create your account</h1>
            </template>
            <template #content>
                <form @submit.prevent="registerUser" class="flex flex-col gap-4">
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
                        <label for="full_name">Full Name</label>
                        <InputText
                            id="full_name"
                            v-model="full_name"
                            required
                            class="w-full"
                        />
                    </div>
                    <div class="flex flex-col gap-2">
                        <label for="email">Email</label>
                        <InputText
                            id="email"
                            v-model="email"
                            type="email"
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
                    <div class="flex flex-col gap-2">
                        <label for="faculty">Faculty</label>
                        <Select
                            id="faculty"
                            v-model="faculty"
                            :options="faculties"
                            optionLabel="name"
                            optionValue="name"
                            placeholder="Select a faculty"
                            class="w-full"
                            required
                        />
                    </div>
                    <Button class="w-full mt-4" type="submit" label="Create account" />
                </form>
            </template>
        </Card>
    </div>
</template>

<style scoped>
</style>
