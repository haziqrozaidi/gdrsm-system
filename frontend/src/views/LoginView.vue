<script setup>
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
import Card from 'primevue/card';
import { ref } from "vue";
import { useRouter } from "vue-router";

const username = ref('12085'); // Default username for testing
const password = ref('S808323'); // Default password for testing
const router = useRouter();
const session = ref(null);

const handleLogin = async () => {
    console.log(`Attempting login with: ${username.value}, ${password.value}`);

    const url = `http://web.fc.utm.my/ttms/web_man_webservice_json.cgi?entity=authentication&login=${username.value}&password=${password.value}`;
    console.log(`API Call: ${url}`);

    try {
        const response = await fetch(url);
        const jsonResponse = await response.json();

        if (jsonResponse && jsonResponse.length > 0) {
            session.value = jsonResponse[0];
            console.log("Login successful:", session.value);

            // Save session in sessionStorage
            sessionStorage.setItem("utmwebfc_session", JSON.stringify(session.value));

            // Redirect or update UI as needed
            alert(`Welcome, ${session.value.full_name}`);
        } else {
            console.log("Invalid login or empty response:", jsonResponse);
            alert("Invalid username or password.");
        }
    } catch (error) {
        console.error("Error during login:", error);
        alert("An error occurred. Please try again.");
    }
};
</script>

<template>
<div class="flex justify-center items-center min-h-screen bg-gray-100 p-4">
    <Card class="w-full max-w-md shadow-lg p-6 pb-0">
        <template #title>
            <h1 class="text-3xl font-bold text-center pb-4">Sign in to your account</h1>
        </template>
        <template #content>
            <form class="flex flex-col gap-4" @submit.prevent="handleLogin">
                <div class="flex flex-col gap-2">
                    <label for="username">Username</label>
                    <InputText id="username" v-model="username" required class="w-full" />
                </div>
                <div class="flex flex-col gap-2">
                    <label for="password">Password</label>
                    <InputText id="password" v-model="password" type="password" required class="w-full" />
                </div>
                <Button class="w-full mt-4" label="Sign in" @click="handleLogin" />
                <p class="text-center">
                    Don't have an account? 
                    <RouterLink to="/register" class="text-black hover:underline font-semibold duration-300">Sign up</RouterLink>
                </p>
            </form>
        </template>
    </Card>
</div>
</template>
