const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8000/api/v1";

export type User = {
  id: string;
  email: string;
  full_name: string;
  roles: string[];
};

export type LoginResponse = {
  access_token: string;
  token_type: string;
  user: User;
};

export type DashboardResponse = {
  summary: Record<string, number | string>;
  stress_distribution: Array<{ stress_band: string; count: number }>;
  payout_distribution: Array<{ month: string; payout_count: number; payout_amount: string }>;
  approval_queue: TriggerApproval[];
};

export type Farmer = {
  farmer_id: string;
  farmer_code: string;
  full_name: string;
  mobile_number: string;
  kyc_status: string;
  plot_count: number;
  policy_count: number;
  total_sum_insured: string;
  total_premium_amount: string;
  total_payout_amount: string;
};

export type Policy = {
  id: string;
  policy_number: string;
  status: string;
  season: string;
  policy_year: number;
  policy_start: string;
  policy_end: string;
  total_sum_insured: string;
  premium_amount: string;
  premium_status: string;
  farmer_code: string;
  farmer_name: string;
  plot_code: string;
  policy_type: string;
};

export type TriggerEvent = {
  id: number;
  event_key: string;
  trigger_date: string;
  trigger_type: string;
  stress_band: string;
  payout_pct: string;
  ndvi_anomaly_pct: string;
  rainfall_anomaly_pct: string;
  reason_code: string;
  reason_detail: string;
  crop_confidence_pct: string;
  review_flag: boolean;
  review_reason: string | null;
  approval_status: string;
  plot_code: string;
  farmer_code: string;
  farmer_name: string;
};

export type TriggerApproval = TriggerEvent & {
  estimated_payout_amount: string;
  basis_risk_reason: string | null;
  basis_risk_severity: string | null;
};

export type Payout = {
  id: string;
  payout_number: string;
  sum_insured: string;
  payout_pct: string;
  payout_amount: string;
  currency: string;
  payment_status: string;
  created_at: string;
  policy_number: string;
  farmer_code: string;
  farmer_name: string;
  plot_code: string;
  reason_code: string;
};

export type PlotFeatureCollection = GeoJSON.FeatureCollection<GeoJSON.Geometry, Record<string, unknown>>;

export type NdviResponse = {
  plot: Record<string, unknown>;
  series: Array<{
    plot_id: number;
    observed_at: string;
    ndvi_value: string;
    quality: string;
    is_interpolated: boolean;
    metadata: Record<string, unknown>;
    source_key: string;
  }>;
};

function getToken() {
  return localStorage.getItem("agrishield_token");
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(errorBody || response.statusText);
  }
  return response.json() as Promise<T>;
}

export const api = {
  login(email: string, password: string) {
    return request<LoginResponse>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
  },
  me() {
    return request<User>("/auth/me");
  },
  dashboard() {
    return request<DashboardResponse>("/dashboard/summary");
  },
  farmers() {
    return request<Farmer[]>("/farmers");
  },
  policies() {
    return request<Policy[]>("/policies");
  },
  triggers() {
    return request<TriggerEvent[]>("/triggers");
  },
  payouts() {
    return request<Payout[]>("/payouts");
  },
  plotGeojson() {
    return request<PlotFeatureCollection>("/gis/plots");
  },
  ndvi(plotId: number) {
    return request<NdviResponse>(`/observations/ndvi/${plotId}`);
  },
};
