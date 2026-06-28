import type { LucideIcon } from "lucide-react";

export function KpiCard({
  label,
  value,
  icon: Icon,
  detail,
}: {
  label: string;
  value: string;
  detail: string;
  icon: LucideIcon;
}) {
  return (
    <div className="rounded-enterprise border border-zinc-200 bg-white p-4 shadow-panel">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-normal text-zinc-500">{label}</p>
          <p className="mt-2 text-2xl font-semibold text-ink">{value}</p>
        </div>
        <div className="flex h-10 w-10 items-center justify-center rounded-enterprise bg-paper text-field">
          <Icon size={20} />
        </div>
      </div>
      <p className="mt-3 text-sm text-zinc-500">{detail}</p>
    </div>
  );
}
