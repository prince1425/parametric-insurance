import { useQuery } from "@tanstack/react-query";

import { StatusBadge } from "../../components/shared/StatusBadge";
import { api } from "../../lib/api";
import { formatCurrency, formatDate, formatPercent } from "../../lib/format";

export function PayoutHistoryPage() {
  const { data = [], isLoading } = useQuery({ queryKey: ["payouts"], queryFn: api.payouts });

  return (
    <section className="rounded-enterprise border border-zinc-200 bg-white shadow-panel">
      <div className="border-b border-zinc-200 p-4">
        <h1 className="text-lg font-semibold">Payout ledger</h1>
        <p className="text-sm text-zinc-500">Approved parametric payout records</p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[960px] text-left text-sm">
          <thead className="border-b border-zinc-200 bg-zinc-50 text-xs uppercase text-zinc-500">
            <tr>
              <th className="px-4 py-3">Payout</th>
              <th className="px-4 py-3">Policy</th>
              <th className="px-4 py-3">Farmer</th>
              <th className="px-4 py-3">Plot</th>
              <th className="px-4 py-3">Amount</th>
              <th className="px-4 py-3">Payout %</th>
              <th className="px-4 py-3">Payment</th>
              <th className="px-4 py-3">Created</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr><td className="px-4 py-4" colSpan={8}>Loading payouts...</td></tr>
            ) : (
              data.map((payout) => (
                <tr key={payout.id} className="border-b border-zinc-100">
                  <td className="px-4 py-3 font-medium">{payout.payout_number}</td>
                  <td className="px-4 py-3">{payout.policy_number}</td>
                  <td className="px-4 py-3">{payout.farmer_name}</td>
                  <td className="px-4 py-3">{payout.plot_code}</td>
                  <td className="px-4 py-3">{formatCurrency(payout.payout_amount)}</td>
                  <td className="px-4 py-3">{formatPercent(payout.payout_pct)}</td>
                  <td className="px-4 py-3"><StatusBadge value={payout.payment_status} /></td>
                  <td className="px-4 py-3">{formatDate(payout.created_at)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
