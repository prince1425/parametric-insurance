import clsx from "clsx";

const toneByValue: Record<string, string> = {
  no_stress: "bg-field/10 text-field ring-field/20",
  mild: "bg-monsoon/10 text-monsoon ring-monsoon/20",
  moderate: "bg-saffron/10 text-saffron ring-saffron/20",
  severe: "bg-alert/10 text-alert ring-alert/20",
  extreme: "bg-ink text-white ring-ink/20",
  active: "bg-field/10 text-field ring-field/20",
  paid: "bg-field/10 text-field ring-field/20",
  completed: "bg-field/10 text-field ring-field/20",
  auto_approved: "bg-field/10 text-field ring-field/20",
  under_review: "bg-saffron/10 text-saffron ring-saffron/20",
  pending_review: "bg-saffron/10 text-saffron ring-saffron/20",
  verified: "bg-field/10 text-field ring-field/20",
};

export function StatusBadge({ value }: { value: string | null | undefined }) {
  const key = String(value ?? "unknown");
  return (
    <span
      className={clsx(
        "inline-flex min-h-6 items-center rounded-enterprise px-2 text-xs font-semibold capitalize ring-1",
        toneByValue[key] ?? "bg-zinc-100 text-zinc-700 ring-zinc-200",
      )}
    >
      {key.replaceAll("_", " ")}
    </span>
  );
}
