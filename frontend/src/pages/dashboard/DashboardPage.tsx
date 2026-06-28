import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, IndianRupee, MapPinned, ShieldCheck, CloudRain, Wind, Activity, Waves, MountainSnow, CheckCircle2 } from "lucide-react";
import { Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { api } from "../../lib/api";
import { formatCurrency, formatNumber } from "../../lib/format";
import { KpiCard } from "../../components/shared/KpiCard";
import { StatusBadge } from "../../components/shared/StatusBadge";

const stressColors: Record<string, string> = {
  no_stress: "#2f7d5d",
  mild: "#2f6f9f",
  moderate: "#b4652a",
  severe: "#b23b3b",
  extreme: "#17211f",
};

export function DashboardPage() {
  const { data, isLoading } = useQuery({ queryKey: ["dashboard"], queryFn: api.dashboard });
  
  // Simulator State
  const [activeScenario, setActiveScenario] = useState<"rainfall" | "earthquake" | "flood">("rainfall");
  const [rainfall, setRainfall] = useState<number>(120);
  const [magnitude, setMagnitude] = useState<number>(6.5);
  const [distance, setDistance] = useState<number>(8);
  const [waterLevel, setWaterLevel] = useState<number>(11);

  if (isLoading || !data) {
    return <div className="h-[70vh] rounded-enterprise border border-zinc-200 bg-white p-6">Loading portfolio...</div>;
  }

  const summary = data.summary;

  // Simulator Calculation Logic (Based on POC Documentation)
  let damagePct = 0;
  
  if (activeScenario === "rainfall") {
    // Rainfall: Less rainfall -> crop stress. Optimal is ~150mm.
    if (rainfall < 60) damagePct = 80;
    else if (rainfall < 100) damagePct = 40;
    else if (rainfall > 250) damagePct = 30; // Heavy flood damage
    else damagePct = 0;
  } else if (activeScenario === "earthquake") {
    // Earthquake: Closer distance + higher magnitude = higher payout
    if (magnitude >= 7.0 && distance <= 10) damagePct = 100;
    else if (magnitude >= 6.0 && distance <= 8) damagePct = 50;
    else if (magnitude >= 5.5 && distance <= 4) damagePct = 20;
    else damagePct = 0;
  } else if (activeScenario === "flood") {
    // Flood: Water level crosses thresholds
    if (waterLevel >= 13) damagePct = 60;
    else if (waterLevel >= 12) damagePct = 30;
    else damagePct = 0;
  }

  const simulatedPayout = Number(summary.exposure_amount || 0) * (damagePct / 100);

  return (
    <div className="space-y-5">
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <KpiCard label="Active exposure" value={formatCurrency(summary.exposure_amount)} detail={`${formatNumber(summary.active_policies)} active policies`} icon={ShieldCheck} />
        <KpiCard label="Insured plots" value={formatNumber(summary.plots)} detail={`${formatNumber(summary.farmers)} verified farmers`} icon={MapPinned} />
        <KpiCard label="Review cases" value={formatNumber(summary.review_cases)} detail={`${formatNumber(summary.trigger_events)} trigger events`} icon={AlertTriangle} />
        <KpiCard label="Paid payouts" value={formatCurrency(summary.paid_amount)} detail={`${formatNumber(summary.completed_payouts)} completed payments`} icon={IndianRupee} />
      </section>

      <section className="grid gap-5 xl:grid-cols-[0.9fr_1.1fr]">
        <div className="rounded-enterprise border border-zinc-200 bg-white p-4 shadow-panel">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h2 className="text-base font-semibold">Stress distribution</h2>
              <p className="text-sm text-zinc-500">Latest trigger events by band</p>
            </div>
          </div>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={data.stress_distribution} dataKey="count" nameKey="stress_band" innerRadius={70} outerRadius={105} paddingAngle={3}>
                  {data.stress_distribution.map((entry) => (
                    <Cell key={entry.stress_band} fill={stressColors[entry.stress_band] ?? "#71717a"} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="rounded-enterprise border border-zinc-200 bg-white p-4 shadow-panel">
          <div className="mb-4">
            <h2 className="text-base font-semibold">Payout ledger trend</h2>
            <p className="text-sm text-zinc-500">Completed payouts by month</p>
          </div>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.payout_distribution}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="month" tickLine={false} axisLine={false} />
                <YAxis tickLine={false} axisLine={false} />
                <Tooltip formatter={(value) => formatCurrency(String(value))} />
                <Bar dataKey="payout_amount" fill="#2f7d5d" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </section>

      {/* Admin Scenario Simulator */}
      <section className="rounded-enterprise border border-zinc-200 bg-white shadow-panel overflow-hidden">
        <div className="border-b border-zinc-200 bg-zinc-50/50 p-4">
          <h2 className="text-base font-semibold text-ink flex items-center gap-2">
            <Activity size={18} className="text-field" />
            Admin Scenario Simulator
          </h2>
          <p className="text-sm text-zinc-500">Select a parametric scenario to project portfolio damage and payouts.</p>
        </div>
        
        {/* Scenario Tabs */}
        <div className="flex border-b border-zinc-200 bg-zinc-50 px-4 pt-4 gap-6">
          <button 
            onClick={() => setActiveScenario("rainfall")}
            className={`pb-3 text-sm font-medium border-b-2 transition-colors ${activeScenario === "rainfall" ? "border-field text-field" : "border-transparent text-zinc-500 hover:text-ink"}`}
          >
            <CloudRain size={16} className="inline mr-2" /> Rainfall (Agriculture)
          </button>
          <button 
            onClick={() => setActiveScenario("earthquake")}
            className={`pb-3 text-sm font-medium border-b-2 transition-colors ${activeScenario === "earthquake" ? "border-field text-field" : "border-transparent text-zinc-500 hover:text-ink"}`}
          >
            <MountainSnow size={16} className="inline mr-2" /> Earthquake (Property)
          </button>
          <button 
            onClick={() => setActiveScenario("flood")}
            className={`pb-3 text-sm font-medium border-b-2 transition-colors ${activeScenario === "flood" ? "border-field text-field" : "border-transparent text-zinc-500 hover:text-ink"}`}
          >
            <Waves size={16} className="inline mr-2" /> Flood (Disaster)
          </button>
        </div>

        <div className="p-6 grid gap-8 md:grid-cols-2 xl:grid-cols-[1.2fr_0.8fr]">
          <div className="space-y-6">
            
            {activeScenario === "rainfall" && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <label className="text-sm font-medium text-zinc-700 flex items-center gap-2">
                    <CloudRain size={16} className="text-blue-500" />
                    Accumulated Rainfall (mm)
                  </label>
                  <span className="text-sm font-bold">{rainfall} mm</span>
                </div>
                <input 
                  type="range" min="0" max="300" step="10"
                  value={rainfall} onChange={(e) => setRainfall(Number(e.target.value))}
                  className="w-full accent-blue-500"
                />
                <div className="flex justify-between text-xs text-zinc-400">
                  <span>Drought (&lt;60mm)</span>
                  <span>Optimal</span>
                  <span>Heavy Flood (&gt;250mm)</span>
                </div>
              </div>
            )}

            {activeScenario === "earthquake" && (
              <>
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <label className="text-sm font-medium text-zinc-700">Magnitude</label>
                    <span className="text-sm font-bold">{magnitude.toFixed(1)}</span>
                  </div>
                  <input 
                    type="range" min="4.0" max="8.0" step="0.5"
                    value={magnitude} onChange={(e) => setMagnitude(Number(e.target.value))}
                    className="w-full accent-orange-500"
                  />
                  <div className="flex justify-between text-xs text-zinc-400">
                    <span>Light (4.0)</span>
                    <span>Severe (7.0+)</span>
                  </div>
                </div>
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <label className="text-sm font-medium text-zinc-700">Distance from Epicenter (km)</label>
                    <span className="text-sm font-bold">{distance} km</span>
                  </div>
                  <input 
                    type="range" min="0" max="20" step="2"
                    value={distance} onChange={(e) => setDistance(Number(e.target.value))}
                    className="w-full accent-orange-500"
                  />
                  <div className="flex justify-between text-xs text-zinc-400">
                    <span>Ground Zero (0km)</span>
                    <span>Safe (&gt;14km)</span>
                  </div>
                </div>
              </>
            )}

            {activeScenario === "flood" && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <label className="text-sm font-medium text-zinc-700 flex items-center gap-2">
                    <Waves size={16} className="text-cyan-500" />
                    Gauge Water Level (m)
                  </label>
                  <span className="text-sm font-bold">{waterLevel} m</span>
                </div>
                <input 
                  type="range" min="5" max="15" step="1"
                  value={waterLevel} onChange={(e) => setWaterLevel(Number(e.target.value))}
                  className="w-full accent-cyan-500"
                />
                <div className="flex justify-between text-xs text-zinc-400">
                  <span>Normal (5m)</span>
                  <span>Alert (12m)</span>
                  <span>Danger (13m+)</span>
                </div>
              </div>
            )}

          </div>

          <div className="rounded-xl bg-field/5 border border-field/20 p-6 flex flex-col justify-center shadow-inner">
            <h3 className="text-sm font-semibold text-zinc-700 mb-4 flex items-center gap-2">
              <CheckCircle2 size={16} className="text-field" /> Trigger Eligibility
            </h3>
            
            <p className="text-sm text-zinc-500 mb-1">Projected Impact Area</p>
            <div className="flex items-end justify-between mb-4">
              <span className="text-4xl font-bold text-ink">{damagePct.toFixed(1)}%</span>
              <span className={`text-sm font-bold px-2 py-1 rounded ${damagePct >= 50 ? 'bg-alert/10 text-alert' : damagePct > 0 ? 'bg-orange-500/10 text-orange-600' : 'bg-field/10 text-field'}`}>
                {damagePct >= 50 ? 'High Risk' : damagePct > 0 ? 'Moderate' : 'No Trigger'}
              </span>
            </div>
            
            <div className="h-px bg-zinc-200 w-full my-4" />
            
            <p className="text-sm text-zinc-500 mb-1">Estimated Instant Payout</p>
            <p className="text-3xl font-bold text-field">{formatCurrency(simulatedPayout)}</p>
          </div>
        </div>
      </section>

      <section className="rounded-enterprise border border-zinc-200 bg-white shadow-panel">
        <div className="border-b border-zinc-200 p-4">
          <h2 className="text-base font-semibold">Underwriter queue</h2>
          <p className="text-sm text-zinc-500">Basis-risk and review-gated trigger events</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px] text-left text-sm">
            <thead className="border-b border-zinc-200 bg-zinc-50 text-xs uppercase text-zinc-500">
              <tr>
                <th className="px-4 py-3">Event</th>
                <th className="px-4 py-3">Farmer</th>
                <th className="px-4 py-3">Plot</th>
                <th className="px-4 py-3">Stress</th>
                <th className="px-4 py-3">Estimated payout</th>
                <th className="px-4 py-3">Reason</th>
              </tr>
            </thead>
            <tbody>
              {data.approval_queue.map((row) => (
                <tr key={row.event_key} className="border-b border-zinc-100">
                  <td className="px-4 py-3 font-medium">{row.event_key}</td>
                  <td className="px-4 py-3">{row.farmer_name}</td>
                  <td className="px-4 py-3">{row.plot_code}</td>
                  <td className="px-4 py-3"><StatusBadge value={row.stress_band} /></td>
                  <td className="px-4 py-3">{formatCurrency(row.estimated_payout_amount)}</td>
                  <td className="px-4 py-3 text-zinc-600">{row.basis_risk_reason ?? row.review_reason}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
