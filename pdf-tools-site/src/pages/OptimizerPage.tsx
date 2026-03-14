import { useMemo, useState } from "react";
import imageCompression from "browser-image-compression";
import { FileDropzone } from "../components/FileDropzone";

type PresetId = "instagram" | "facebook" | "whatsapp" | "twitter" | "linkedin";

const PRESETS: Record<
  PresetId,
  { title: string; width: number; height: number; maxMB: number; quality: number }
> = {
  instagram: { title: "Instagram (1080×1080)", width: 1080, height: 1080, maxMB: 1.0, quality: 0.9 },
  facebook: { title: "Facebook (1200×630)", width: 1200, height: 630, maxMB: 1.0, quality: 0.9 },
  whatsapp: { title: "WhatsApp (1600×900)", width: 1600, height: 900, maxMB: 0.8, quality: 0.9 },
  twitter: { title: "Twitter/X (1600×900)", width: 1600, height: 900, maxMB: 1.0, quality: 0.9 },
  linkedin: { title: "LinkedIn (1200×627)", width: 1200, height: 627, maxMB: 1.0, quality: 0.9 },
};

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

export function OptimizerPage() {
  const [files, setFiles] = useState<File[]>([]);
  const [preset, setPreset] = useState<PresetId>("instagram");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const canRun = useMemo(() => files.length > 0, [files.length]);

  async function onFiles(inFiles: File[]) {
    setError(null);
    setFiles(prev => [...prev, ...inFiles]);
  }

  function removeFile(index: number) {
    setFiles(prev => prev.filter((_, i) => i !== index));
  }

  async function run() {
    setBusy(true);
    setError(null);

    try {
      const p = PRESETS[preset];

      for (const f of files) {
        const compressed = await imageCompression(f, {
          maxSizeMB: p.maxMB,
          maxWidthOrHeight: Math.max(p.width, p.height),
          useWebWorker: true,
          initialQuality: p.quality,
        });

        const base = f.name.replace(/\.[^.]+$/, "");
        downloadBlob(compressed, `${base}-${preset}.jpg`);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "فشل التحسين");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main>
      <section className="gradient-hero border-b">
        <div className="container py-12">
          <h1 className="text-3xl font-extrabold">تحسين الصور للسوشيال</h1>
          <p className="mt-3 text-sm text-muted-foreground">ضغط ذكي + إعدادات جاهزة للمنصات. كل شيء محلي داخل المتصفح.</p>
        </div>
      </section>

      <section className="py-10">
        <div className="container grid gap-6 lg:grid-cols-2">
          <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm">
            <FileDropzone
              accept="image/*"
              multiple
              onFiles={onFiles}
              title="اسحب الصور هنا"
              subtitle="PNG / JPG / WEBP"
            />

            {files.length > 0 ? (
              <div className="mt-5 rounded-2xl border border-border bg-card p-4">
                <div className="flex items-center justify-between mb-3">
                  <div className="text-sm font-extrabold">الملفات المختارة ({files.length})</div>
                  <button
                    type="button"
                    onClick={() => setFiles([])}
                    className="text-xs font-bold text-muted-foreground hover:text-foreground"
                  >
                    مسح الكل
                  </button>
                </div>
                <div className="mt-3 max-h-[200px] overflow-y-auto space-y-2 pr-1">
                  {files.map((f, index) => (
                    <div key={index} className="flex items-center justify-between rounded-xl bg-muted/50 px-3 py-2 border border-border/40">
                      <div className="flex items-center gap-2 overflow-hidden">
                        <span className="text-primary text-sm">✨</span>
                        <div className="truncate text-xs font-bold">{f.name}</div>
                      </div>
                      <div className="flex items-center gap-3">
                        <div className="text-[10px] text-muted-foreground whitespace-nowrap">{Math.round(f.size / 1024)} KB</div>
                        <button
                          onClick={() => removeFile(index)}
                          className="text-destructive hover:bg-destructive/10 p-1 rounded-lg transition"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="mt-4 pt-3 border-t border-border/40">
                  <label className="flex items-center justify-center gap-2 w-full py-2 rounded-xl border-2 border-dashed border-border hover:border-primary/50 hover:bg-primary/5 cursor-pointer transition text-xs font-bold text-muted-foreground hover:text-primary">
                    <input
                      type="file"
                      className="hidden"
                      multiple
                      accept="image/*"
                      onChange={(e) => e.target.files && onFiles(Array.from(e.target.files))}
                    />
                    <span>+ إضافة صور أخرى</span>
                  </label>
                </div>
              </div>
            ) : null}

            <div className="mt-5 grid gap-3 sm:grid-cols-2">
              <label className="space-y-1">
                <div className="text-xs font-bold text-muted-foreground">المنصة</div>
                <select
                  value={preset}
                  onChange={(e) => setPreset(e.target.value as PresetId)}
                  className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                >
                  {Object.entries(PRESETS).map(([id, p]) => (
                    <option key={id} value={id}>
                      {p.title}
                    </option>
                  ))}
                </select>
              </label>
            </div>

            <div className="mt-6 flex flex-col gap-2 sm:flex-row">
              <button
                type="button"
                onClick={run}
                disabled={!canRun || busy}
                className={
                  "flex-1 rounded-xl px-5 py-3 text-sm font-extrabold shadow-md transition " +
                  (canRun && !busy ? "bg-primary text-primary-foreground hover:opacity-95 text-gradient-rev" : "bg-muted text-muted-foreground")
                }
              >
                {busy ? "جاري التحسين..." : "تحسين وتحميل الكل"}
              </button>
            </div>

            {error ? (
              <div className="mt-4 rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm font-bold text-destructive">
                {error}
              </div>
            ) : null}
          </div>

          <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm">
            <div className="text-sm font-extrabold">ماذا يفعل هذا؟</div>
            <div className="mt-3 text-sm leading-7 text-muted-foreground">
              - يضغط الصورة لتصير مناسبة للنشر.

              - يحاول الحفاظ على الجودة قدر الإمكان.

              - بإمكانك اختيار منصة مختلفة حسب المقاس.
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
