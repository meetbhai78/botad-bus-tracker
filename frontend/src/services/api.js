import axios from 'axios';

const API_URL = import.meta.env.VITE_BACKEND_URL || '';

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

export const stopApi = {
  getAll: () => api.get('/stops'),
};

export const timetableApi = {
  getAll: (routeId) => api.get('/timetable', { params: routeId ? { routeId } : {} }),
  search: (from, to) => api.get('/timetable/search', { params: { from, to } }),
};

export const adminApi = {
  dashboard: () => api.get('/admin/dashboard'),
  buses: () => api.get('/admin/buses'),
  createBus: (data) => api.post('/admin/buses', data),
  updateBus: (id, data) => api.put(`/admin/buses/${id}`, data),
  deleteBus: (id) => api.delete(`/admin/buses/${id}`),
  drivers: () => api.get('/admin/drivers'),
  createDriver: (data) => api.post('/admin/drivers', data),
  passengers: () => api.get('/admin/passengers'),
  routes: () => api.get('/admin/routes'),
  createRoute: (data) => api.post('/admin/routes', data),
  updateRoute: (id, data) => api.put(`/admin/routes/${id}`, data),
  deleteRoute: (id) => api.delete(`/admin/routes/${id}`),
  stops: () => api.get('/admin/stops'),
  createStop: (data) => api.post('/admin/stops', data),
  updateStop: (id, data) => api.put(`/admin/stops/${id}`, data),
  deleteStop: (id) => api.delete(`/admin/stops/${id}`),
  timetable: () => api.get('/admin/timetable'),
  createTimetable: (data) => api.post('/admin/timetable', data),
  updateTimetable: (id, data) => api.put(`/admin/timetable/${id}`, data),
  deleteTimetable: (id) => api.delete(`/admin/timetable/${id}`),
  dailyReport: () => api.get('/admin/reports/daily'),
  getEmergencyAlert: () => api.get('/admin/emergency-alert'),
  updateEmergencyAlert: (data) => api.post('/admin/emergency-alert', data),
};

export default api;
