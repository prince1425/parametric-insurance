export function formatCurrency(value: number | string | null | undefined) {
  const numeric = Number(value ?? 0);
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(numeric);
}

export function formatNumber(value: number | string | null | undefined) {
  return new Intl.NumberFormat("en-IN").format(Number(value ?? 0));
}

export function formatPercent(value: number | string | null | undefined) {
  return `${Number(value ?? 0).toFixed(1)}%`;
}

export function formatDate(value: string | null | undefined) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("en-IN", { day: "2-digit", month: "short", year: "numeric" }).format(
    new Date(value),
  );
}
