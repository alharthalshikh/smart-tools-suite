import type { ReactNode } from "react";

type Props = {
  title: string;
  description: string;
  icon: ReactNode;
  active?: boolean;
  onClick?: () => void;
};

export function ToolCard({ title, description, icon, active, onClick }: Props) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={
        "group relative w-full rounded-2xl border bg-card/80 p-5 text-right shadow-sm transition hover:-translate-y-0.5 hover:shadow-md " +
        (active ? "border-primary shadow-glow" : "border-border")
      }
    >
      <div className="pointer-events-none absolute inset-0 rounded-2xl opacity-0 transition group-hover:opacity-100" />
      <div className="flex items-start gap-4">
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-primary">
          {icon}
        </div>
        <div className="min-w-0">
          <div className="text-base font-extrabold">{title}</div>
          <div className="mt-1 line-clamp-2 text-sm text-muted-foreground">{description}</div>
        </div>
      </div>
    </button>
  );
}
