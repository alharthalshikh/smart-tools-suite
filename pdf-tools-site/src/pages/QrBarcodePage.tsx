import { useEffect, useMemo, useRef, useState } from "react";
import Barcode from "react-barcode";
import { FileDropzone } from "../components/FileDropzone";
import { ColorDropdown } from "../components/ColorDropdown";
import QRCodeStyling from "qr-code-styling";

type Mode = "qr" | "barcode";

type BarcodeFormat =
  | "CODE128"
  | "EAN13"
  | "EAN8"
  | "UPC"
  | "ITF14"
  | "MSI";

function downloadPng(dataUrl: string, filename: string) {
  const a = document.createElement("a");
  a.href = dataUrl;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
}

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

function svgToPngDataUrl(
  svgEl: SVGSVGElement,
  width: number,
  height: number,
  background: string,
): Promise<string> {
  return new Promise((resolve, reject) => {
    const xml = new XMLSerializer().serializeToString(svgEl);
    const svg64 = btoa(unescape(encodeURIComponent(xml)));
    const image64 = "data:image/svg+xml;base64," + svg64;

    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext("2d");
      if (!ctx) return reject(new Error("فشل معالجة الصورة في المتصفح"));
      ctx.fillStyle = background;
      ctx.fillRect(0, 0, width, height);
      ctx.drawImage(img, 0, 0, width, height);
      resolve(canvas.toDataURL("image/png"));
    };
    img.onerror = reject;
    img.src = image64;
  });
}

export function QrBarcodePage() {
  const [mode, setMode] = useState<Mode>("qr");

  const [text, setText] = useState("https://");
  const [qrSize, setQrSize] = useState(320);
  const [qrFg, setQrFg] = useState("#0f6d7a");
  const [qrFg2, setQrFg2] = useState("#111827");
  const [qrBg, setQrBg] = useState("#0b1f3a");
  const [qrTransparentBg, setQrTransparentBg] = useState(false);
  const [qrGradient, setQrGradient] = useState(false);
  const [qrPreviewReady, setQrPreviewReady] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [qrDesign, setQrDesign] = useState<
    "square" | "dots" | "rounded" | "extra-rounded" | "classy" | "classy-rounded"
  >("square");

  const [qrLogo, setQrLogo] = useState<string | null>(null);

  const qrRef = useRef<HTMLDivElement | null>(null);
  const qrInstanceRef = useRef<any>(null);

  const [barcodeFormat, setBarcodeFormat] = useState<BarcodeFormat>("CODE128");
  const [barcodeWidth, setBarcodeWidth] = useState(2);
  const [barcodeHeight, setBarcodeHeight] = useState(90);
  const [barcodeLine, setBarcodeLine] = useState("#0f6d7a");
  const [barcodeBg, setBarcodeBg] = useState("#0b1f3a");
  const [barcodeTransparentBg, setBarcodeTransparentBg] = useState(false);

  const BRAND_COLORS = [
    { name: "Teal", hex: "#0f6d7a" },
    { name: "Teal 2", hex: "#14919b" },
    { name: "Amber", hex: "#f59e0b" },
    { name: "Navy", hex: "#0b1f3a" },
  ] as const;

  const POPULAR_COLORS = [
    { name: "Black", hex: "#111827" },
    { name: "Gray", hex: "#6b7280" },
    { name: "Blue", hex: "#2563eb" },
    { name: "Green", hex: "#16a34a" },
    { name: "Red", hex: "#dc2626" },
    { name: "Purple", hex: "#7c3aed" },
    { name: "Pink", hex: "#db2777" },
    { name: "White", hex: "#ffffff" },
  ] as const;

  const canGenerate = useMemo(() => text.trim().length > 0, [text]);

  const qrOptions = useMemo(() => {
    const dotsType =
      qrDesign === "square"
        ? "square"
        : qrDesign === "dots"
          ? "dots"
          : qrDesign === "rounded"
            ? "rounded"
            : qrDesign === "extra-rounded"
              ? "extra-rounded"
              : qrDesign === "classy"
                ? "classy"
                : "classy-rounded";

    const isDots = qrDesign === "dots";

    const commonColorOptions = qrGradient
      ? {
        gradient: {
          type: "linear",
          rotation: 0,
          colorStops: [
            { offset: 0, color: qrFg },
            { offset: 1, color: qrFg2 },
          ],
        },
      }
      : { color: qrFg };

    return {
      width: qrSize,
      height: qrSize,
      data: text.trim() || " ",
      margin: 2,
      dotsOptions: {
        ...commonColorOptions,
        type: dotsType,
      },
      cornersSquareOptions: {
        ...commonColorOptions,
        type: isDots ? "extra-rounded" : dotsType === "dots" ? "square" : dotsType,
      },
      cornersDotOptions: {
        ...commonColorOptions,
        type: isDots ? "dot" : dotsType === "dots" ? "square" : dotsType,
      },
      backgroundOptions: {
        color: qrTransparentBg ? "transparent" : qrBg,
      },
      image: qrLogo ?? undefined,
      imageOptions: {
        crossOrigin: "anonymous",
        margin: 8,
        imageSize: 0.22,
      },
      qrOptions: {
        errorCorrectionLevel: "H",
      },
    };
  }, [qrBg, qrTransparentBg, qrDesign, qrFg, qrFg2, qrGradient, qrLogo, qrSize, text]);

  useEffect(() => {
    if (!qrRef.current) return;

    if (!qrInstanceRef.current) {
      const inst = new QRCodeStyling(qrOptions);
      qrInstanceRef.current = inst;
      qrRef.current.innerHTML = "";
      inst.append(qrRef.current);
      setQrPreviewReady(true);
      return;
    }

    qrInstanceRef.current.update(qrOptions);
    setQrPreviewReady(true);
  }, [qrOptions]);

  async function generateQr() {
    setBusy(true);
    setError(null);
    try {
      const inst = qrInstanceRef.current;
      if (!inst) throw new Error("الـQR غير جاهز بعد");
      const blob: Blob = await inst.getRawData("png");
      downloadBlob(blob, "qr.png");
    } catch (e) {
      setError(e instanceof Error ? e.message : "فشل توليد QR");
    } finally {
      setBusy(false);
    }
  }

  async function onLogoFile(files: File[]) {
    const file = files[0];
    if (!file) return;

    const logoUrl = URL.createObjectURL(file);
    setQrLogo(logoUrl);
  }

  async function downloadBarcodePng() {
    setError(null);
    try {
      const svg = document.getElementById("barcode-svg") as SVGSVGElement | null;
      if (!svg) throw new Error("لم يتم إنشاء الباركود بعد");
      const dataUrl = await svgToPngDataUrl(svg, 900, 320, barcodeTransparentBg ? "transparent" : barcodeBg);
      downloadPng(dataUrl, "barcode.png");
    } catch (e) {
      setError(e instanceof Error ? e.message : "فشل التحميل");
    }
  }

  return (
    <main>
      <section className="gradient-hero border-b">
        <div className="container mx-auto px-4 py-12">
          <h1 className="text-3xl font-extrabold sm:text-4xl">QR + باركود</h1>
          <p className="mt-3 text-sm text-muted-foreground sm:text-base">توليد QR قابل للتخصيص + باركود بعدة معايير، مع تحميل مباشر.</p>

          <div className="mt-6 flex gap-2">
            <button
              type="button"
              onClick={() => setMode("qr")}
              className={
                "rounded-xl px-4 py-2 text-sm font-extrabold transition " +
                (mode === "qr" ? "bg-primary text-primary-foreground" : "border border-border bg-card/70")
              }
            >
              QR
            </button>
            <button
              type="button"
              onClick={() => setMode("barcode")}
              className={
                "rounded-xl px-4 py-2 text-sm font-extrabold transition " +
                (mode === "barcode" ? "bg-primary text-primary-foreground" : "border border-border bg-card/70")
              }
            >
              Barcode
            </button>
          </div>
        </div>
      </section>

      <section className="py-10">
        <div className="container mx-auto grid gap-6 px-4 lg:grid-cols-2">
          <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm">
            <div className="text-sm font-extrabold">البيانات</div>
            <textarea
              value={text}
              onChange={(e) => setText(e.target.value)}
              rows={4}
              className="mt-3 w-full rounded-2xl border border-border bg-background px-3 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/40"
              placeholder="اكتب رابط أو نص..."
            />

            {mode === "qr" ? (
              <>
                <div className="mt-4 grid gap-3 sm:grid-cols-2">
                  <label className="space-y-1">
                    <div className="text-xs font-bold text-muted-foreground">الحجم</div>
                    <input
                      type="number"
                      min={128}
                      max={1024}
                      value={qrSize}
                      onChange={(e) => setQrSize(Number(e.target.value))}
                      className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                    />
                  </label>
                </div>

                <div className="mt-4">
                  <label className="space-y-1">
                    <div className="text-xs font-bold text-muted-foreground">نمط التصميم</div>
                    <select
                      value={qrDesign}
                      onChange={(e) =>
                        setQrDesign(
                          e.target.value as
                          | "square"
                          | "dots"
                          | "rounded"
                          | "extra-rounded"
                          | "classy"
                          | "classy-rounded",
                        )
                      }
                      className="w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm font-extrabold shadow-sm outline-none focus:ring-2 focus:ring-primary/40"
                    >
                      <option value="square">مربعات (تقليدي)</option>
                      <option value="dots">نقاط (دائرية)</option>
                      <option value="rounded">ناعم (Rounded)</option>
                      <option value="extra-rounded">دائري جدًا</option>
                      <option value="classy">كلاسيكي (Classy)</option>
                      <option value="classy-rounded">كلاسيكي ناعم</option>
                    </select>
                  </label>
                </div>

                <div className="mt-4">
                  <label className="flex items-center gap-2 text-xs font-extrabold text-muted-foreground">
                    <input
                      type="checkbox"
                      checked={qrGradient}
                      onChange={(e) => setQrGradient(e.target.checked)}
                      className="h-4 w-4"
                    />
                    تدرّج
                  </label>
                </div>

                <div className="mt-6 space-y-4">
                  <div className="grid gap-4 sm:grid-cols-2">
                    <ColorDropdown
                      label="لون الكود"
                      value={qrFg}
                      onChange={setQrFg}
                      brandColors={BRAND_COLORS}
                      popularColors={POPULAR_COLORS}
                    />

                    {qrGradient && (
                      <div className="animate-in fade-in slide-in-from-right-2 duration-300">
                        <ColorDropdown
                          label="لون التدرّج الثاني"
                          value={qrFg2}
                          onChange={setQrFg2}
                          brandColors={BRAND_COLORS}
                          popularColors={POPULAR_COLORS}
                        />
                      </div>
                    )}
                  </div>

                  <div className="rounded-2xl border border-border bg-background/30 p-4 transition-all">
                    <div className="flex items-center justify-between mb-4">
                      <div className="text-sm font-extrabold text-foreground">الخلفية:</div>
                      <label className="flex items-center gap-2 text-sm font-bold cursor-pointer group">
                        <input
                          type="checkbox"
                          checked={qrTransparentBg}
                          onChange={(e) => setQrTransparentBg(e.target.checked)}
                          className="h-5 w-5 rounded border-border bg-background text-primary focus:ring-primary/40 transition"
                        />
                        <span className="group-hover:text-primary transition">شفاف</span>
                      </label>
                    </div>

                    {!qrTransparentBg && (
                      <div className="animate-in fade-in slide-in-from-top-2 duration-300">
                        <ColorDropdown
                          label="لون الخلفية"
                          value={qrBg}
                          onChange={setQrBg}
                          brandColors={BRAND_COLORS}
                          popularColors={POPULAR_COLORS}
                          allowWhite
                        />
                      </div>
                    )}
                  </div>
                </div>

                <div className="mt-4">
                  <div className="text-xs font-bold text-muted-foreground">شعار في المنتصف (اختياري)</div>
                  <div className="mt-2">
                    <FileDropzone
                      accept="image/*"
                      multiple={false}
                      onFiles={onLogoFile}
                      title="اسحب صورة الشعار هنا"
                      subtitle="PNG/JPG/WebP"
                    />
                  </div>
                </div>

                <div className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
                  <button
                    type="button"
                    disabled={!canGenerate || busy}
                    onClick={generateQr}
                    className={
                      "rounded-xl px-5 py-3 text-sm font-extrabold shadow-md transition " +
                      (canGenerate && !busy ? "bg-primary text-primary-foreground hover:opacity-95" : "bg-muted text-muted-foreground")
                    }
                  >
                    {busy ? "جاري..." : "توليد QR"}
                  </button>
                  <button
                    type="button"
                    disabled={!qrPreviewReady}
                    onClick={generateQr}
                    className={
                      "rounded-xl border border-border bg-card/70 px-5 py-3 text-sm font-extrabold shadow-sm transition " +
                      (qrPreviewReady ? "hover:bg-card" : "opacity-60")
                    }
                  >
                    تحميل PNG
                  </button>
                </div>
              </>
            ) : (
              <>
                <div className="mt-4 grid gap-3 sm:grid-cols-2">
                  <label className="space-y-1">
                    <div className="text-xs font-bold text-muted-foreground">المعيار</div>
                    <select
                      value={barcodeFormat}
                      onChange={(e) => setBarcodeFormat(e.target.value as BarcodeFormat)}
                      className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                    >
                      <option value="CODE128">CODE128</option>
                      <option value="EAN13">EAN13</option>
                      <option value="EAN8">EAN8</option>
                      <option value="UPC">UPC</option>
                      <option value="ITF14">ITF14</option>
                      <option value="MSI">MSI</option>
                    </select>
                  </label>
                  <label className="space-y-1">
                    <div className="text-xs font-bold text-muted-foreground">عرض الخط</div>
                    <input
                      type="number"
                      min={1}
                      max={6}
                      value={barcodeWidth}
                      onChange={(e) => setBarcodeWidth(Number(e.target.value))}
                      className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                    />
                  </label>
                  <label className="space-y-1">
                    <div className="text-xs font-bold text-muted-foreground">الارتفاع</div>
                    <input
                      type="number"
                      min={40}
                      max={220}
                      value={barcodeHeight}
                      onChange={(e) => setBarcodeHeight(Number(e.target.value))}
                      className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                    />
                  </label>
                </div>

                <div className="mt-6 space-y-4">
                  <div className="rounded-2xl border border-border bg-background/30 p-4 transition-all">
                    <div className="flex items-center justify-between mb-4">
                      <div className="text-sm font-extrabold text-foreground">الخلفية:</div>
                      <label className="flex items-center gap-2 text-sm font-bold cursor-pointer group">
                        <input
                          type="checkbox"
                          checked={barcodeTransparentBg}
                          onChange={(e) => setBarcodeTransparentBg(e.target.checked)}
                          className="h-5 w-5 rounded border-border bg-background text-primary focus:ring-primary/40 transition"
                        />
                        <span className="group-hover:text-primary transition">شفاف</span>
                      </label>
                    </div>

                    {!barcodeTransparentBg && (
                      <div className="animate-in fade-in slide-in-from-top-2 duration-300">
                        <ColorDropdown
                          label="لون الخلفية"
                          value={barcodeBg}
                          onChange={setBarcodeBg}
                          brandColors={BRAND_COLORS}
                          popularColors={POPULAR_COLORS}
                          allowWhite
                        />
                      </div>
                    )}
                  </div>

                  <ColorDropdown
                    label="لون الباركود"
                    value={barcodeLine}
                    onChange={setBarcodeLine}
                    brandColors={BRAND_COLORS}
                    popularColors={POPULAR_COLORS}
                  />
                </div>

                <div className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
                  <button
                    type="button"
                    disabled={!canGenerate}
                    onClick={() => setError(null)}
                    className={
                      "rounded-xl px-5 py-3 text-sm font-extrabold shadow-md transition " +
                      (canGenerate ? "bg-primary text-primary-foreground hover:opacity-95" : "bg-muted text-muted-foreground")
                    }
                  >
                    تحديث الباركود
                  </button>
                  <button
                    type="button"
                    onClick={downloadBarcodePng}
                    className="rounded-xl border border-border bg-card/70 px-5 py-3 text-sm font-extrabold shadow-sm transition hover:bg-card"
                  >
                    تحميل PNG
                  </button>
                </div>
              </>
            )}

            {error ? (
              <div className="mt-4 rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm font-bold text-destructive">
                {error}
              </div>
            ) : null}
          </div>

          <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm">
            <div className="text-sm font-extrabold">المعاينة</div>

            <div className="mt-4 flex items-center justify-center rounded-2xl border border-border bg-background p-4 min-h-[300px] overflow-x-auto">
              <div
                ref={qrRef}
                id="qr-preview-container"
                className={"w-full flex items-center justify-center [&_canvas]:max-w-full [&_canvas]:h-auto [&_svg]:max-w-full [&_svg]:h-auto " + (mode === "qr" ? "block" : "hidden")}
              />

              <div className={"w-full flex items-center justify-center " + (mode === "barcode" ? "block" : "hidden")}>
                <div dir="ltr" className="max-w-full overflow-auto">
                  <Barcode
                    value={text.trim() || " "}
                    format={barcodeFormat}
                    width={barcodeWidth}
                    height={barcodeHeight}
                    displayValue
                    background={barcodeTransparentBg ? "transparent" : barcodeBg}
                    lineColor={barcodeLine}
                    renderer="svg"
                    id="barcode-svg"
                  />
                </div>
              </div>
            </div>

            <div className="mt-4 text-xs text-muted-foreground">
              ملاحظة: بعض معايير الباركود تتطلب طولًا محددًا (مثل EAN13). إذا ظهر خطأ، غيّر المعيار إلى CODE128.
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
