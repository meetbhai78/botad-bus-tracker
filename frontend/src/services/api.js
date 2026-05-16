import axios from 'axios';

const API_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5000';

const api = axios.create({ baseURL: `${API_URL}/api` });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export const authApi = {
  login: (phone, password) => api.post('/auth/login', { phone, password }),
  register: (data) => api.post('/auth/register', data),
  me: () => api.get('/auth/me'),
};

export const busApi = {
  getAll: () => api.get('/buses'),
  getNearby: (lat, lng) => api.get('/buses/nearby', { params: { lat, lng } }),
};

export const routeApi = {
  getAll: () => api.get('/routes'),
};

export const adminApi = {
  dashboard: () => api.get('/admin/dashboard'),
  buses: () => api.get('/admin/buses'),
  dailyReport: () => api.get('/admin/reports/daily'),
};

export default api;
