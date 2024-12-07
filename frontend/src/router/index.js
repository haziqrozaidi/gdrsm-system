import { createRouter, createWebHistory } from 'vue-router'

import HomeView from '../views/HomeView.vue'
import RegisterView from '../views/RegisterView.vue'
import LoginView from '../views/LoginView.vue'
import DashboardView from '../views/DashboardView.vue'
import FilesView from '../views/FilesView.vue'
import FoldersView from '../views/FoldersView.vue'

const routes = [
  {
    path: '/',
    name: 'home',
    component: HomeView
  },
  {
    path: '/register',
    name: 'register',
    component: RegisterView
  },
  {
    path: '/login',
    name: 'login',
    component: LoginView
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: DashboardView
  },
  {
    path: '/files',
    name: 'files',
    component: FilesView
  },
  {
    path: '/folders',
    name: 'folders',
    component: FoldersView
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
