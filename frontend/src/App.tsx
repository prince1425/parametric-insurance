import { Navigate, Route, Routes } from "react-router-dom";

import { AppShell } from "./components/layout/AppShell";
import { useAuth } from "./store/auth";
import { LoginPage } from "./pages/auth/LoginPage";
import { DashboardPage } from "./pages/dashboard/DashboardPage";
import { GISMapPage } from "./pages/gis/GISMapPage";
import { PolicyListPage } from "./pages/policies/PolicyListPage";
import { TriggerMonitorPage } from "./pages/triggers/TriggerMonitorPage";
import { PayoutHistoryPage } from "./pages/payouts/PayoutHistoryPage";

function ProtectedShell() {
  const { token } = useAuth();
  if (!token) return <Navigate to="/login" replace />;
  return <AppShell />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedShell />}>
        <Route index element={<DashboardPage />} />
        <Route path="/gis" element={<GISMapPage />} />
        <Route path="/policies" element={<PolicyListPage />} />
        <Route path="/triggers" element={<TriggerMonitorPage />} />
        <Route path="/payouts" element={<PayoutHistoryPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
