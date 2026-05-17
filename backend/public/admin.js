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
    if (e.target.dataset.tab === 'drivers') loadDrivers();
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
          <td>
            <button class="btn danger" onclick="deleteBus('${bus._id}')">Delete</button>
          </td>
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
          <td>
            <button class="btn danger" onclick="deleteRoute('${route._id}')">Delete</button>
          </td>
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

// Save Bus
document.getElementById('busForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const busNumber = document.getElementById('busNumber').value;
  const busName = document.getElementById('busName').value;
  const capacity = document.getElementById('capacity').value;

  const res = await fetchWithAuth('/admin/buses', {
    method: 'POST',
    body: JSON.stringify({
      busNumber,
      busName,
      capacity: parseInt(capacity)
    })
  });

  if (res.success) {
    closeModal('busModal');
    loadBuses();
    document.getElementById('busForm').reset();
  } else {
    alert('Failed to add bus: ' + res.message);
  }
});

// Load Drivers
async function loadDrivers() {
  const data = await fetchWithAuth('/admin/drivers');
  if (data.success) {
    const tbody = document.querySelector('#driversTable tbody');
    tbody.innerHTML = '';
    data.drivers.forEach(driver => {
      tbody.innerHTML += `
        <tr>
          <td><strong>${driver.name}</strong></td>
          <td>${driver.phone}</td>
          <td>${driver.email || 'N/A'}</td>
          <td><span class="status active">Active</span></td>
        </tr>
      `;
    });
  }
}

// Save Driver
document.getElementById('driverForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const name = document.getElementById('driverName').value;
  const phone = document.getElementById('driverPhone').value;
  const password = document.getElementById('driverPassword').value;

  const res = await fetchWithAuth('/admin/drivers', {
    method: 'POST',
    body: JSON.stringify({ name, phone, password })
  });

  if (res.success) {
    closeModal('driverModal');
    loadDrivers();
    document.getElementById('driverForm').reset();
  } else {
    alert('Failed to add driver: ' + res.message);
  }
});

// Delete Bus
async function deleteBus(id) {
  if (confirm('Are you sure you want to delete this bus?')) {
    const res = await fetchWithAuth(`/admin/buses/${id}`, { method: 'DELETE' });
    if (res.success) loadBuses();
    else alert('Failed to delete bus: ' + res.message);
  }
}

// Delete Route
async function deleteRoute(id) {
  if (confirm('Are you sure you want to delete this route?')) {
    const res = await fetchWithAuth(`/admin/routes/${id}`, { method: 'DELETE' });
    if (res.success) loadRoutes();
    else alert('Failed to delete route: ' + res.message);
  }
}
