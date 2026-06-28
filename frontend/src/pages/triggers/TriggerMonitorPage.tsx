import { useQuery } from "@tanstack/react-query";

import { StatusBadge } from "../../components/shared/StatusBadge";
import { api } from "../../lib/api";
import { formatDate, formatPercent } from "../../lib/format";

export function TriggerMonitorPage() {
  const { data = [], isLoading } = useQuery({ queryKey: ["triggers"], queryFn: api.triggers });

  return (
    <section className="rounded-enterprise border border-zinc-200 bg-white shadow-panel">
      <div className="border-b border-zinc-200 p-4">
        <h1 className="text-lg font-semibold">Trigger monitor</h1>
        <p className="text-sm text-zinc-500">NDVI anomaly decisions and review routing</p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[1060px] text-left text-sm">
          <thead className="border-b border-zinc-200 bg-zinc-50 text-xs uppercase text-zinc-500">
            <tr>
              <th className="px-4 py-3">Event</th>
              <th className="px-4 py-3">Date</th>
              <th className="px-4 py-3">Farmer</th>
              <th className="px-4 py-3">Plot</th>
              <th className="px-4 py-3">Band</th>
              <th className="px-4 py-3">NDVI anomaly</th>
              <th className="px-4 py-3">Payout</th>
              <th className="px-4 py-3">Approval</th>
              <th className="px-4 py-3">Reason</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr><td className="px-4 py-4" colSpan={9}>Loading trigger events...</td></tr>
            ) : (
              data.map((event) => (
                <tr key={event.event_key} className="border-b border-zinc-100 align-top">
                  <td className="px-4 py-3 font-medium">{event.event_key}</td>
                  <td className="px-4 py-3">{formatDate(event.trigger_date)}</td>
                  <td className="px-4 py-3">{event.farmer_name}</td>
                  <td className="px-4 py-3">{event.plot_code}</td>
                  <td className="px-4 py-3"><StatusBadge value={event.stress_band} /></td>
                  <td className="px-4 py-3">{formatPercent(event.ndvi_anomaly_pct)}</td>
                  <td className="px-4 py-3">{formatPercent(event.payout_pct)}</td>
                  <td className="px-4 py-3"><StatusBadge value={event.approval_status} /></td>
                  <td className="max-w-md px-4 py-3 text-zinc-600">{event.reason_detail}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
