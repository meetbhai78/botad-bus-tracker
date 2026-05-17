const API_URL = '/api';
let token = localStorage.getItem('adminToken');

// Initialize
if (token) {
  showDashboard();
}

// Navigation
document.querySelectorAll('.nav-btn').forEach(btn => {
  btn.addEventListener('click', (e) => {
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    
    e.target.classList.add('active');
    document.getElementById(e.target.dataset.tab).classList.add('active');
    
    if (e.target.dataset.tab === 'overview') loadDashboardStats();
    if (e.target.dataset.tab === 'buses') loadBuses();
    if (e.target.dataset.tab === 'routes') loadRoutes();
  });
});

// Login
document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const phone = document.getElementById('phone').value;
  const password = document.getElementById('password').value;
  
  try {
    const res = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone, password, role: 'admin' })
    });
    const data = await res.json();
    if (data.success) {
      token = data.token;
      localStorage.setItem('adminToken', token);
      showDashboard();
    } else {
      alert('Login failed: ' + data.message);
    }
  } catch (err) {
    alert('Error connecting to server');
  }
});

function showDashboard() {
  document.getElementById('loginScreen').classList.remove('active');
  document.getElementById('dashboardScreen').classList.add('active');
  loadDashboardStats();
}

function logout() {
  localStorage.removeItem('adminToken');
  token = null;
  document.getElementById('dashboardScreen').classList.remove('active');
  document.getElementById('loginScreen').classList.add('active');
}

// Modals
function showModal(id) {
  document.getElementById(id).classList.add('active');
}
function closeModal(id) {
  document.getElementById(id).classList.remove('active');
}

// API Calls
async function fetchWithAuth(url, options = {}) {
  options.headers = {
    ...options.headers,
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
  const res = await fetch(API_URL + url, options);
  if (res.status === 401) logout();
  return res.json();
}

async function loadDashboardStats() {
  const data = await fetchWithAuth('/admin/dashboard');
  if (data.success) {
    document.getElementById('stat-activeBuses').innerText = data.stats.activeBuses;
    document.getElementById('stat-routes').innerText = data.stats.routes;
    document.getElementById('stat-passengers').innerText = data.stats.passengersToday;
    document.getElementById('stat-revenue').innerText = '₹' + data.stats.revenue;
  }
}

async function loadBuses() {
  const data = await fetchWithAuth('/admin/buses');
  if (data.success) {
    const tbody = document.querySelector('#busesTable tbody');
    tbody.innerHTML = '';
    data.buses.forEach(bus => {
      tbody.innerHTML += `
        <tr>
          <td><strong>${bus.busNumber}</strong><br><small>${bus.busName}</small></td>
          <td>${bus.capacity}</td>
          <td><span class="status ${bus.status}">${bus.status}</span></td>
          <td>${bus.driver ? bus.driver.name : 'Unassigned'}</td>
          <td>${bus.route ? bus.route.routeName : 'Unassigned'}</td>
        </tr>
      `;
    });
  }
}

async function loadRoutes() {
  const data = await fetchWithAuth('/routes');
  if (data.success) {
    const tbody = document.querySelector('#routesTable tbody');
    tbody.innerHTML = '';
    data.routes.forEach(route => {
      tbody.innerHTML += `
        <tr>
          <td><strong>${route.routeNumber}</strong></td>
          <td>${route.routeName}</td>
          <td>${route.stops.length} stops</td>
          <td>${route.totalDistance || 0} km</td>
          <td>${route.totalTime || 0} mins</td>
        </tr>
      `;
    });
  }
}

// Save Route
document.getElementById('routeForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const routeNumber = document.getElementById('routeNumber').value;
  const routeName = document.getElementById('routeName').value;
  const stopsStr = document.getElementById('routeStops').value;
  
  const stops = stopsStr.split(',').map((name, i) => ({
    name: name.trim(),
    lat: 22.1647 + (i * 0.001), // mock lat for now
    lng: 71.6661 + (i * 0.001), // mock lng for now
    order: i + 1,
    estimatedTime: i * 5
  }));

  const res = await fetchWithAuth('/routes', {
    method: 'POST',
    body: JSON.stringify({
      routeNumber,
      routeName,
      stops,
      totalDistance: stops.length * 2,
      totalTime: stops.length * 5
    })
  });

  if (res.success) {
    closeModal('routeModal');
    loadRoutes();
    document.getElementById('routeForm').reset();
  } else {
    alert('Failed to save route: ' + res.message);
  }
});
