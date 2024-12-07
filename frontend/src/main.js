import 'primeicons/primeicons.css'
import './style.css'

import { createApp } from 'vue'
import PrimeVue from 'primevue/config';
import router from './router'
import ToastService from 'primevue/toastservice';

import App from './App.vue'
import Noir from './presets/Noir.js';

const app = createApp(App);

app.use(PrimeVue, {
    theme: {
        preset: Noir
    }
});

app.use(router)

app.use(ToastService);

app.mount('#app')
