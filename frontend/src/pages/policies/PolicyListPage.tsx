import { useQuery } from "@tanstack/react-query";

import { StatusBadge } from "../../components/shared/StatusBadge";
import { api } from "../../lib/api";
import { formatCurrency, formatDate } from "../../lib/format";

export function PolicyListPage() {
  const { data = [], isLoading } = useQuery({ queryKey: ["policies"], queryFn: api.policies });

  return (
    <section className="rounded-enterprise border border-zinc-200 bg-white shadow-panel">
      <div className="border-b border-zinc-200 p-4">
        <h1 className="text-lg font-semibold">Policies</h1>
        <p className="text-sm text-zinc-500">Active Latur crop stress portfolio</p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[980px] text-left text-sm">
          <thead className="border-b border-zinc-200 bg-zinc-50 text-xs uppercase text-zinc-500">
            <tr>
              <th className="px-4 py-3">Policy</th>
              <th className="px-4 py-3">Farmer</th>
              <th className="px-4 py-3">Plot</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Period</th>
              <th className="px-4 py-3">Exposure</th>
              <th className="px-4 py-3">Premium</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr><td className="px-4 py-4" colSpan={7}>Loading policies...</td></tr>
            ) : (
              data.map((policy) => (
                <tr key={policy.id} className="border-b border-zinc-100">
                  <td className="px-4 py-3 font-medium">{policy.policy_number}</td>
                  <td className="px-4 py-3">{policy.farmer_name}</td>
                  <td className="px-4 py-3">{policy.plot_code}</td>
                  <td className="px-4 py-3"><StatusBadge value={policy.status} /></td>
                  <td className="px-4 py-3">{formatDate(policy.policy_start)} - {formatDate(policy.policy_end)}</td>
                  <td className="px-4 py-3">{formatCurrency(policy.total_sum_insured)}</td>
                  <td className="px-4 py-3">{formatCurrency(policy.premium_amount)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
