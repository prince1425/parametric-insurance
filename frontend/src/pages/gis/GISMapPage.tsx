import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Circle, Layers, MapPinned } from "lucide-react";
import { GeoJSON, MapContainer, TileLayer } from "react-leaflet";
import type { Layer } from "leaflet";

import { StatusBadge } from "../../components/shared/StatusBadge";
import { api } from "../../lib/api";
import { formatCurrency, formatPercent } from "../../lib/format";

const bandColor: Record<string, string> = {
  no_stress: "#2f7d5d",
  mild: "#2f6f9f",
  moderate: "#b4652a",
  severe: "#b23b3b",
  extreme: "#17211f",
};

export function GISMapPage() {
  const { data, isLoading } = useQuery({ queryKey: ["plot-geojson"], queryFn: api.plotGeojson });
  const [selected, setSelected] = useState<Record<string, unknown> | null>(null);

  const boundsCenter = useMemo<[number, number]>(() => [18.26, 76.61], []);

  return (
    <div className="grid gap-5 xl:grid-cols-[1fr_360px]">
      <section className="overflow-hidden rounded-enterprise border border-zinc-200 bg-white shadow-panel">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-zinc-200 p-4">
          <div>
            <h1 className="text-lg font-semibold">GIS risk map</h1>
            <p className="text-sm text-zinc-500">PostGIS sample plot layer by stress band</p>
          </div>
          <div className="flex items-center gap-2 text-sm text-zinc-600">
            <Layers size={17} />
            {data?.features.length ?? 0} plots
          </div>
        </div>
        <div className="h-[calc(100vh-180px)] min-h-[520px]">
          {isLoading || !data ? (
            <div className="flex h-full items-center justify-center text-zinc-500">Loading map layer...</div>
          ) : (
            <MapContainer center={boundsCenter} zoom={10} className="h-full w-full" scrollWheelZoom>
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              <GeoJSON
                key={`geojson-${data.features.length}-${selected?.plot_code}`}
                data={data}
                style={(feature) => {
                  const band = String(feature?.properties?.stress_band ?? "no_stress");
                  const isSelected = selected?.plot_code === feature?.properties?.plot_code;
                  return {
                    color: isSelected ? "#18181b" : (bandColor[band] ?? "#71717a"),
                    fillColor: bandColor[band] ?? "#71717a",
                    weight: isSelected ? 4 : 2,
                    fillOpacity: isSelected ? 0.6 : 0.28,
                  };
                }}
                onEachFeature={(feature, layer: Layer) => {
                  layer.bindTooltip(String(feature.properties?.plot_code ?? "Plot"), { sticky: true });
                  layer.on("click", () => {
                    setSelected(feature.properties ?? null);
                  });
                }}
              />
            </MapContainer>
          )}
        </div>
      </section>

      <aside className="space-y-5">
        <div className="rounded-enterprise border border-zinc-200 bg-white p-4 shadow-panel">
          <div className="mb-4 flex items-center gap-2">
            <MapPinned size={18} className="text-field" />
            <h2 className="text-base font-semibold">Selected plot</h2>
          </div>
          {selected ? (
            <dl className="space-y-3 text-sm">
              <div><dt className="text-zinc-500">Plot</dt><dd className="font-semibold">{String(selected.plot_code)}</dd></div>
              <div><dt className="text-zinc-500">Farmer</dt><dd>{String(selected.farmer_name)}</dd></div>
              <div><dt className="text-zinc-500">Village</dt><dd>{String(selected.village_name)}</dd></div>
              <div className="flex items-center justify-between"><dt className="text-zinc-500">Stress</dt><dd><StatusBadge value={String(selected.stress_band)} /></dd></div>
              <div><dt className="text-zinc-500">Payout</dt><dd>{formatPercent(String(selected.payout_pct))}</dd></div>
              <div><dt className="text-zinc-500">Amount</dt><dd>{formatCurrency(String(selected.payout_amount ?? 0))}</dd></div>
              <div><dt className="text-zinc-500">Reason</dt><dd className="break-words">{String(selected.reason_code)}</dd></div>
            </dl>
          ) : (
            <div className="rounded-enterprise bg-paper p-4 text-sm text-zinc-500">No plot selected</div>
          )}
        </div>

        <div className="rounded-enterprise border border-zinc-200 bg-white p-4 shadow-panel">
          <h2 className="mb-3 text-base font-semibold">Layer legend</h2>
          <div className="space-y-2">
            {Object.entries(bandColor).map(([band, color]) => (
              <div key={band} className="flex items-center justify-between text-sm">
                <span className="flex items-center gap-2 capitalize">
                  <Circle size={12} fill={color} color={color} />
                  {band.replaceAll("_", " ")}
                </span>
                <span className="text-zinc-500">NDVI</span>
              </div>
            ))}
          </div>
        </div>
      </aside>
    </div>
  );
}
