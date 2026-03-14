import { useEffect, useId, useMemo, useRef, useState } from "react";

type ColorItem = {
  name: string;
  hex: string;
};

type Props = {
  label: string;
  value: string;
  onChange: (hex: string) => void;
  brandColors: readonly ColorItem[];
  popularColors: readonly ColorItem[];
  allowWhite?: boolean;
};

export function ColorDropdown({
  label,
  value,
  onChange,
  brandColors,
  popularColors,
  allowWhite,
}: Props) {
  const id = useId();
  const rootRef = useRef<HTMLDivElement | null>(null);
  const [open, setOpen] = useState(false);
  const [custom, setCustom] = useState(false);

  const colors = useMemo(() => {
    const list = [...brandColors, ...popularColors];
    if (!allowWhite) return list.filter((c) => c.hex.toLowerCase() !== "#ffffff");
    return list;
  }, [allowWhite, brandColors, popularColors]);

  useEffect(() => {
    function onDocMouseDown(e: MouseEvent) {
      const el = rootRef.current;
      if (!el) return;
      if (el.contains(e.target as Node)) return;
      setOpen(false);
    }

    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }

    document.addEventListener("mousedown", onDocMouseDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("mousedown", onDocMouseDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, []);

  return (
    <div ref={rootRef} className="relative">
      <button
        id={id}
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between rounded-2xl border border-border bg-background px-4 py-3 text-sm font-extrabold shadow-sm transition hover:bg-muted"
        aria-expanded={open}
        aria-controls={`${id}-panel`}
      >
        <span className="text-muted-foreground">{label}</span>
        <span className="flex items-center gap-3">
          <span
            className="h-6 w-10 rounded-lg border border-border"
            style={{ backgroundColor: value }}
          />
          <span className="text-xs text-muted-foreground">{open ? "إخفاء" : "تحديد"}</span>
        </span>
      </button>

      {open ? (
        <div
          id={`${id}-panel`}
          className="absolute left-0 right-0 top-[calc(100%+10px)] z-50 overflow-hidden rounded-2xl border border-border bg-card/95 p-4 shadow-lg backdrop-blur"
        >
          <div className="flex items-center justify-between">
            <div className="text-xs font-extrabold text-muted-foreground">ألوان جاهزة</div>
            <button
              type="button"
              onClick={() => setCustom((v) => !v)}
              className={
                "rounded-lg px-3 py-1 text-xs font-extrabold transition " +
                (custom ? "bg-primary text-primary-foreground" : "border border-border bg-card")
              }
            >
              مخصص
            </button>
          </div>

          <div className="mt-3 flex flex-wrap gap-2">
            {colors.map((c) => (
              <button
                key={c.hex}
                type="button"
                onClick={() => {
                  onChange(c.hex);
                  setCustom(false);
                  setOpen(false);
                }}
                className={
                  "h-7 w-7 rounded-lg border transition " +
                  (value.toLowerCase() === c.hex.toLowerCase()
                    ? "border-primary ring-2 ring-primary/40"
                    : "border-border")
                }
                style={{ backgroundColor: c.hex }}
                aria-label={c.name}
                title={c.name}
              />
            ))}
          </div>

          {custom ? (
            <div className="mt-3">
              <input
                type="color"
                value={value}
                onChange={(e) => onChange(e.target.value)}
                className="h-10 w-full rounded-xl border border-border bg-background px-2"
              />
            </div>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}
