import type { ReactNode } from "react";

export function Section({ title, subtitle, children }: { title: string; subtitle?: string; children: ReactNode }) {
  return (
    <section className="py-10">
      <div className="container">
        <div className="mb-6">
          <h2 className="text-2xl font-extrabold">{title}</h2>
          {subtitle ? <p className="mt-2 text-sm text-muted-foreground">{subtitle}</p> : null}
        </div>
        {children}
      </div>
    </section>
  );
}
