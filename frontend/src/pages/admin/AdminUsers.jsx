import { useEffect, useState } from 'react';
import { adminApi } from '../../services/api';

export default function AdminUsers() {
  const [tab, setTab] = useState('drivers');
  const [drivers, setDrivers] = useState([]);
  const [passengers, setPassengers] = useState([]);
  const [driverForm, setDriverForm] = useState({ name: '', phone: '', password: 'driver123' });
  const [msg, setMsg] = useState('');

  const load = () => {
    adminApi.drivers().then((r) => setDrivers(r.data.drivers || []));
    adminApi.passengers().then((r) => setPassengers(r.data.passengers || []));
  };

  useEffect(() => {
    load();
  }, []);

  const addDriver = async (e) => {
    e.preventDefault();
    setMsg('');
    try {
      await adminApi.createDriver(driverForm);
      setMsg('Driver added');
      setDriverForm({ name: '', phone: '', password: 'driver123' });
      load();
    } catch (err) {
      setMsg(err.response?.data?.message || 'Failed');
    }
  };

  return (
    <div className="p-8 max-w-5xl">
      <h2 className="text-2xl font-bold text-slate-900">Drivers & passengers</h2>
      <p className="text-slate-500 text-sm mt-1">Manage who can drive buses and who uses the passenger app.</p>

      <div className="flex gap-2 mt-6">
        {['drivers', 'passengers'].map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => setTab(t)}
            className={`px-4 py-2 rounded-lg text-sm font-medium capitalize ${
              tab === t ? 'bg-teal-600 text-white' : 'bg-white border text-slate-600'
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {tab === 'drivers' && (
        <>
          <form onSubmit={addDriver} className="mt-6 bg-white rounded-2xl border p-6 grid md:grid-cols-3 gap-4">
            <input
              placeholder="Driver name"
              value={driverForm.name}
              onChange={(e) => setDriverForm({ ...driverForm, name: e.target.value })}
              className="border rounded-lg px-3 py-2"
              required
            />
            <input
              placeholder="Phone"
              value={driverForm.phone}
              onChange={(e) => setDriverForm({ ...driverForm, phone: e.target.value })}
              className="border rounded-lg px-3 py-2"
              required
            />
            <input
              placeholder="Password"
              value={driverForm.password}
              onChange={(e) => setDriverForm({ ...driverForm, password: e.target.value })}
              className="border rounded-lg px-3 py-2"
              required
            />
            <button type="submit" className="bg-teal-600 text-white px-4 py-2 rounded-lg font-medium md:col-span-3">
              Add driver
            </button>
            {msg && <p className="text-sm text-teal-700 md:col-span-3">{msg}</p>}
          </form>
          <UserTable rows={drivers} columns={['name', 'phone', 'createdAt']} />
        </>
      )}

      {tab === 'passengers' && (
        <div className="mt-6">
          <p className="text-sm text-slate-500 mb-4">
            Passengers register in the mobile app. You can view their accounts here.
          </p>
          <UserTable rows={passengers} columns={['name', 'phone', 'email', 'createdAt']} />
        </div>
      )}
    </div>
  );
}

function UserTable({ rows, columns }) {
  return (
    <div className="bg-white rounded-2xl border overflow-hidden">
      <table className="w-full text-sm">
        <thead className="bg-slate-50 text-left">
          <tr>
            {columns.map((c) => (
              <th key={c} className="p-3 capitalize">
                {c.replace('createdAt', 'Joined')}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((u) => (
            <tr key={u._id || u.id} className="border-t">
              {columns.map((c) => (
                <td key={c} className="p-3">
                  {c === 'createdAt' && u[c]
                    ? new Date(u[c]).toLocaleDateString()
                    : u[c] || '—'}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
