import { Bell, FileText, Gauge, Home, Landmark, LogOut, Map, Satellite } from "lucide-react";
import { NavLink, Outlet } from "react-router-dom";
import InnoMickLogo from "../../assets/innomick-logo.svg";
import clsx from "clsx";

import { useAuth } from "../../store/auth";

const navItems = [
  { to: "/", label: "Dashboard", icon: Home },
  { to: "/gis", label: "GIS", icon: Map },
  { to: "/policies", label: "Policies", icon: FileText },
  { to: "/triggers", label: "Triggers", icon: Gauge },
  { to: "/payouts", label: "Payouts", icon: Landmark },
];

export function AppShell() {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen bg-paper text-ink">
      <aside className="fixed inset-y-0 left-0 z-20 hidden w-64 border-r border-zinc-200 bg-white lg:block">
        <div className="flex h-20 items-center gap-3 border-b border-zinc-200/60 px-6 bg-white/50 backdrop-blur-md">
          <div className="flex h-10 w-10 items-center justify-center overflow-hidden transition-transform duration-300 hover:scale-105">
            <img src={InnoMickLogo} alt="InnoMick Logo" className="h-full w-full object-contain" />
          </div>
          <div>
            <p className="text-sm font-bold tracking-tight text-ink">InnoMick</p>
            <p className="text-xs text-zinc-500">Parametric operations</p>
          </div>
        </div>
        <nav className="space-y-1 px-3 py-4">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                clsx(
                  "group flex h-11 items-center gap-3 rounded-enterprise px-4 text-sm font-medium transition-all duration-300",
                  isActive
                    ? "bg-field text-white shadow-lg shadow-field/30 ring-1 ring-field/50"
                    : "text-zinc-600 hover:bg-zinc-50 hover:text-ink hover:translate-x-1"
                )
              }
            >
              <item.icon size={18} className="transition-transform duration-300 group-hover:scale-110" />
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>
      <div className="lg:pl-64">
        <header className="sticky top-0 z-10 flex h-20 items-center justify-between border-b border-zinc-200/60 bg-white/80 px-4 backdrop-blur-xl lg:px-8">
          <div>
            <p className="text-sm font-semibold text-ink">Latur Crop Stress Cover</p>
            <p className="text-xs text-zinc-500">Demo portfolio connected to PostgreSQL</p>
          </div>
          <div className="flex items-center gap-4">
            <button onClick={() => alert("Notifications panel coming soon")} className="flex h-10 w-10 items-center justify-center rounded-enterprise border border-zinc-200 bg-white text-zinc-600 shadow-sm transition-all hover:border-zinc-300 hover:bg-zinc-50 hover:text-ink hover:shadow">
              <Bell size={18} className="transition-transform hover:rotate-12" />
            </button>
            <button onClick={() => alert("Sentinel API simulation started...")} className="hidden h-9 items-center gap-2 rounded-enterprise border border-zinc-200 bg-white px-3 text-sm text-zinc-700 sm:flex">
              <Satellite size={16} />
              Sentinel mock
            </button>
            <div className="hidden text-right sm:block">
              <p className="text-sm font-semibold">{user?.full_name}</p>
              <p className="text-xs text-zinc-500">{user?.roles?.[0] ?? "operator"}</p>
            </div>
            <button
              onClick={logout}
              className="flex h-10 w-10 items-center justify-center rounded-enterprise bg-ink text-white shadow-md transition-all hover:bg-ink/90 hover:shadow-lg active:scale-95"
              title="Logout"
            >
              <LogOut size={18} className="transition-transform group-hover:-translate-x-0.5" />
            </button>
          </div>
        </header>
        <main className="p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
