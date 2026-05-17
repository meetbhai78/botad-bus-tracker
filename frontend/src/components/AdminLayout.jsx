import { NavLink, Outlet, useNavigate } from 'react-router-dom';

const nav = [
  { to: '/admin', end: true, label: 'Dashboard', icon: '📊' },
  { to: '/admin/stops', label: 'Bus stops', icon: '📍' },
  { to: '/admin/routes', label: 'Routes', icon: '🛣️' },
  { to: '/admin/timetable', label: 'Timetable', icon: '🕐' },
  { to: '/admin/users', label: 'Drivers & passengers', icon: '👥' },
];

export default function AdminLayout() {
  const navigate = useNavigate();

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('role');
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex">
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col shrink-0">
        <div className="p-5 border-b border-slate-100">
          <p className="text-xs font-semibold text-teal-600 uppercase tracking-wide">City bus · Botad</p>
          <h1 className="text-lg font-bold text-slate-900 mt-1">Admin Console</h1>
          <p className="text-xs text-slate-500 mt-1">Manage stops, routes & users</p>
        </div>
        <nav className="flex-1 p-3 space-y-1">
          {nav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition ${
                  isActive
                    ? 'bg-teal-50 text-teal-800'
                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                }`
              }
            >
              <span>{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="p-3 border-t border-slate-100 space-y-1">
          <a href="/" className="block px-3 py-2 text-sm text-slate-500 hover:text-teal-600">
            ← Passenger map
          </a>
          <button
            type="button"
            onClick={logout}
            className="w-full text-left px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg"
          >
            Log out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}
