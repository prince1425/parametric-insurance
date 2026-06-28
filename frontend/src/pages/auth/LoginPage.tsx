import { FormEvent, useState } from "react";
import { Navigate } from "react-router-dom";
import { Loader2 } from "lucide-react";

import InnoMickLogo from "../../assets/innomick-logo.svg";
import { useAuth } from "../../store/auth";

export function LoginPage() {
  const { login, token } = useAuth();
  const [email, setEmail] = useState("admin@agrishield.local");
  const [password, setPassword] = useState("demo123");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (token) return <Navigate to="/" replace />;

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await login(email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to login");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-screen bg-paper lg:grid-cols-[1.1fr_0.9fr]">
      <section className="relative hidden overflow-hidden bg-ink lg:block">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_25%_25%,rgba(47,125,93,0.28),transparent_32%),linear-gradient(135deg,rgba(47,111,159,0.32),transparent_42%)]" />
        <div className="relative flex h-full flex-col justify-between p-10 text-white">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center overflow-hidden">
              <img src={InnoMickLogo} alt="InnoMick Logo" className="h-full w-full object-contain filter brightness-0 invert" />
            </div>
            <div>
              <p className="font-bold text-lg tracking-tight">InnoMick</p>
              <p className="text-sm text-white/60">Parametric insurance platform</p>
            </div>
          </div>
          <div className="max-w-xl">
            <p className="text-sm font-semibold uppercase tracking-normal text-field">Latur operations</p>
            <h1 className="mt-4 text-5xl font-semibold leading-tight">
              Crop stress decisions with traceable satellite evidence.
            </h1>
            <p className="mt-5 text-lg leading-8 text-white/70">
              NDVI anomalies, policy exposure, review queues, and payout ledgers in one underwriting console.
            </p>
          </div>
          <div className="grid grid-cols-3 gap-3 text-sm text-white/70">
            <div className="rounded-enterprise border border-white/10 p-3">5 sample plots</div>
            <div className="rounded-enterprise border border-white/10 p-3">3 trigger rules</div>
            <div className="rounded-enterprise border border-white/10 p-3">PostGIS layers</div>
          </div>
        </div>
      </section>
      <section className="flex items-center justify-center p-6 bg-zinc-50/50">
        <form onSubmit={submit} className="w-full max-w-md rounded-2xl border border-zinc-200/60 bg-white/70 p-8 shadow-xl backdrop-blur-xl transition-all hover:shadow-2xl">
          <div className="mb-8">
            <p className="text-xs font-bold uppercase tracking-wider text-field">Secure access</p>
            <h2 className="mt-2 text-3xl font-bold tracking-tight text-ink">Operations console</h2>
          </div>
          <label className="block text-sm font-medium text-zinc-700">
            Email
            <input
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="mt-2 h-12 w-full rounded-xl border border-zinc-300 px-4 text-sm outline-none transition-all focus:border-field focus:ring-4 focus:ring-field/20"
            />
          </label>
          <label className="mt-5 block text-sm font-medium text-zinc-700">
            Password
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="mt-2 h-12 w-full rounded-xl border border-zinc-300 px-4 text-sm outline-none transition-all focus:border-field focus:ring-4 focus:ring-field/20"
            />
          </label>
          {error && <p className="mt-5 rounded-xl bg-alert/10 p-4 text-sm font-medium text-alert">{error}</p>}
          <button
            type="submit"
            className="mt-8 flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-ink text-sm font-bold text-white shadow-lg transition-all hover:-translate-y-0.5 hover:bg-ink/90 hover:shadow-xl active:translate-y-0"
          >
            {loading && <Loader2 size={18} className="animate-spin" />}
            Sign in
          </button>
        </form>
      </section>
    </div>
  );
}
