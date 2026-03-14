import { useMemo, useState } from "react";
import { FileDropzone } from "../components/FileDropzone";
import { AddMoreButton } from "../components/AddMoreButton";

type OutFormat = "image/png" | "image/jpeg" | "image/webp";

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

async function convertImage(file: File, outType: OutFormat, quality: number): Promise<Blob> {
  const url = URL.createObjectURL(file);
  const img = new Image();
  img.crossOrigin = "anonymous";

  await new Promise<void>((res, rej) => {
    img.onload = () => res();
    img.onerror = () => rej(new Error("فشل تحميل الصورة"));
    img.src = url;
  });

  const canvas = document.createElement("canvas");
  canvas.width = img.naturalWidth;
  canvas.height = img.naturalHeight;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas غير متاح");

  ctx.drawImage(img, 0, 0);

  const blob: Blob = await new Promise((resolve, reject) => {
    canvas.toBlob(
      (b) => (b ? resolve(b) : reject(new Error("فشل التحويل"))),
      outType,
      outType === "image/png" ? undefined : quality,
    );
  });

  URL.revokeObjectURL(url);
  return blob;
}

export function ImageConverterPage() {
  const [files, setFiles] = useState<File[]>([]);
  const [outType, setOutType] = useState<OutFormat>("image/webp");
  const [quality, setQuality] = useState(0.9);
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
      for (const f of files) {
        const blob = await convertImage(f, outType, quality);
        const ext = outType === "image/png" ? "png" : outType === "image/jpeg" ? "jpg" : "webp";
        const base = f.name.replace(/\.[^.]+$/, "");
        downloadBlob(blob, `${base}.${ext}`);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "فشل التحويل");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main>
      <section className="gradient-hero border-b">
        <div className="container py-12">
          <h1 className="text-3xl font-extrabold">تحويل الصور</h1>
          <p className="mt-3 text-sm text-muted-foreground">حوّل صورك (PNG/JPG/WebP) داخل المتصفح بجودة عالية.</p>
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
                      <div className="flex items-center gap-3">
                        <button
                          onClick={() => removeFile(index)}
                          className="text-destructive hover:bg-destructive/10 p-1 rounded-lg transition"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
                        </button>
                        <div className="truncate text-xs font-bold">{f.name}</div>
                      </div>
                      <div className="flex items-center gap-3">
                        <div className="text-[10px] text-muted-foreground whitespace-nowrap">{Math.round(f.size / 1024)} KB</div>
                        <span className="text-primary text-sm">🖼️</span>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="mt-4 pt-3 border-t border-border/40">
                  <AddMoreButton
                    onFiles={onFiles}
                    accept="image/*"
                    label="+ إضافة صور أخرى"
                  />
                </div>
              </div>
            ) : null}

            <div className="mt-5 grid gap-3 sm:grid-cols-2">
              <label className="space-y-1">
                <div className="text-xs font-bold text-muted-foreground">الصيغة</div>
                <select
                  value={outType}
                  onChange={(e) => setOutType(e.target.value as OutFormat)}
                  className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                >
                  <option value="image/webp">WEBP</option>
                  <option value="image/jpeg">JPG</option>
                  <option value="image/png">PNG</option>
                </select>
              </label>

              <label className="space-y-1">
                <div className="text-xs font-bold text-muted-foreground">الجودة</div>
                <input
                  type="number"
                  min={0.1}
                  max={1}
                  step={0.05}
                  value={quality}
                  onChange={(e) => setQuality(Number(e.target.value))}
                  className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                />
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
                {busy ? "جاري التحويل..." : "تحويل وتحميل الكل"}
              </button>
            </div>

            {error ? (
              <div className="mt-4 rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm font-bold text-destructive">
                {error}
              </div>
            ) : null}
          </div>

          <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm">
            <div className="text-sm font-extrabold">تنبيهات</div>
            <div className="mt-3 text-sm text-muted-foreground leading-7">
              عملية التحويل تتم بالكامل داخل متصفحك بشكل آمن وسريع.

              الصور ذات الأحجام الكبيرة قد تستغرق بضع ثوانٍ إضافية للمعالجة.
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
