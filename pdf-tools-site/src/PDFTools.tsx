import { useEffect, useMemo, useState } from "react";
import { FileDropzone } from "./components/FileDropzone";
import { Section } from "./components/Section";
import { ToolCard } from "./components/ToolCard";
import {
  addTextWatermark,
  deletePages,
  downloadBytes,
  getPdfPageCount,
  mergePdfs,
  parsePagesList,
  readPdfFile,
  rotatePdf,
  splitPdf,
  type PdfInputFile,
} from "./lib/pdf";
import * as XLSX from "xlsx";
import { jsPDF } from "jspdf";
import autoTable from "jspdf-autotable";
import * as mammoth from "mammoth";
import * as pdfjsLib from "pdfjs-dist";
import JSZip from "jszip";
import { ShareTool } from "./components/ShareTool";
import { AddMoreButton } from "./components/AddMoreButton";

// Setup PDF.js worker
pdfjsLib.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsLib.version}/pdf.worker.min.js`;

type ToolId =
  | "merge"
  | "split"
  | "rotate"
  | "delete"
  | "watermark"
  | "pdf_to_jpg"
  | "excel_to_pdf"
  | "word_to_pdf"
  | "jpg_to_pdf";

const TOOL_META: Record<ToolId, { title: string; description: string; icon: string }> = {
  merge: { title: "دمج ملفات PDF", description: "اجمع عدة ملفات في ملف واحد مرتب", icon: "⧉" },
  split: { title: "تقسيم PDF", description: "استخرج نطاق صفحات (مثل 1-5)", icon: "✂" },
  rotate: { title: "تدوير الصفحات", description: "تدوير 90°/180°/270° لإصلاح الاتجاه", icon: "⟳" },
  delete: { title: "حذف صفحات", description: "احذف صفحات محددة بسرعة", icon: "🗑" },
  watermark: { title: "علامة مائية", description: "أضف نص علامة مائية داخل كل صفحة", icon: "⛨" },
  excel_to_pdf: { title: "إكسل إلى PDF", description: "حول جداول Excel إلى ملفات PDF مرتبة", icon: "📑" },
  word_to_pdf: { title: "وورد إلى PDF", description: "حول ملفات Word (docx) إلى PDF نصي", icon: "📝" },
  pdf_to_jpg: { title: "PDF إلى صور (JPG)", description: "حول صفحات ملف PDF إلى صور منفصلة مضغوطة", icon: "🖼" },
  jpg_to_pdf: { title: "صور إلى PDF", description: "حول مجموعة صور إلى ملف PDF واحد", icon: "📄" },
};

export function PDFTools() {
  const [activeTool, setActiveTool] = useState<ToolId>("merge");
  const [pdfFiles, setPdfFiles] = useState<PdfInputFile[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [statusText, setStatusText] = useState<string>("");

  const [pageCount, setPageCount] = useState<number | null>(null);

  const [splitFrom, setSplitFrom] = useState<number>(1);
  const [splitTo, setSplitTo] = useState<number>(1);
  const [rotation, setRotation] = useState<90 | 180 | 270>(90);
  const [deleteMode, setDeleteMode] = useState<"list" | "range">("list");
  const [pagesToDelete, setPagesToDelete] = useState("2, 3");
  const [deleteFrom, setDeleteFrom] = useState<number>(1);
  const [deleteTo, setDeleteTo] = useState<number>(1);
  const [watermarkText, setWatermarkText] = useState("نسخة تجريبية");

  const canRun = useMemo(() => {
    if (activeTool === "merge") return pdfFiles.length >= 2;
    if (activeTool === "split") return pdfFiles.length === 1;
    if (activeTool === "rotate") return pdfFiles.length === 1;
    if (activeTool === "delete") return pdfFiles.length === 1;
    if (activeTool === "watermark") return pdfFiles.length === 1;
    if (activeTool === "excel_to_pdf") return pdfFiles.length === 1;
    if (activeTool === "word_to_pdf") return pdfFiles.length === 1;
    if (activeTool === "pdf_to_jpg") return pdfFiles.length === 1;
    if (activeTool === "jpg_to_pdf") return pdfFiles.length >= 1;
    return false;
  }, [activeTool, pdfFiles.length]);

  useEffect(() => {
    let canceled = false;

    async function load() {
      if (pdfFiles.length !== 1) {
        setPageCount(null);
        return;
      }

      try {
        const count = await getPdfPageCount(pdfFiles[0]!);
        if (canceled) return;
        setPageCount(count);

        setSplitFrom((v) => Math.max(1, Math.min(v, count)));
        setSplitTo((v) => Math.max(1, Math.min(v, count)));
        setDeleteFrom((v) => Math.max(1, Math.min(v, count)));
        setDeleteTo((v) => Math.max(1, Math.min(v, count)));
      } catch {
        if (canceled) return;
        setPageCount(null);
      }
    }

    void load();
    return () => {
      canceled = true;
    };
  }, [pdfFiles]);

  async function addFiles(files: File[]) {
    setError(null);
    setSuccess(null);

    const pdfsOnly = files.filter(
      (f) => {
        if (activeTool === "excel_to_pdf") {
          return f.name.toLowerCase().endsWith(".xlsx") || f.name.toLowerCase().endsWith(".xls");
        }
        if (activeTool === "word_to_pdf") {
          return f.name.toLowerCase().endsWith(".docx");
        }
        if (activeTool === "jpg_to_pdf") {
          return f.type.startsWith("image/");
        }
        return f.type === "application/pdf" || f.name.toLowerCase().endsWith(".pdf");
      }
    );

    if (pdfsOnly.length === 0) return;

    if (activeTool === "excel_to_pdf" || activeTool === "word_to_pdf") {
      setPdfFiles([{ file: pdfsOnly[0], name: pdfsOnly[0].name, bytes: new Uint8Array() }]);
      return;
    }

    if (activeTool === "jpg_to_pdf") {
      const mapped = pdfsOnly.map(f => ({ file: f, name: f.name, bytes: new Uint8Array() }));
      setPdfFiles(prev => [...prev, ...mapped]);
      return;
    }

    const mapped = await Promise.all(pdfsOnly.map(readPdfFile));

    setPdfFiles((prev) => {
      return [...prev, ...mapped];
    });
  }

  function removeFile(index: number) {
    setPdfFiles(prev => prev.filter((_, i) => i !== index));
  }

  function reset() {
    setPdfFiles([]);
    setError(null);
    setSuccess(null);
  }

  async function runTool() {
    setBusy(true);
    setError(null);
    setSuccess(null);

    try {
      if (!canRun) {
        throw new Error("اختر ملفات مناسبة للأداة أولاً");
      }

      if (activeTool === "merge") {
        const out = await mergePdfs(pdfFiles);
        downloadBytes(out, "merged.pdf");
        setSuccess("تم دمج الملفات بنجاح");
        return;
      }

      const input = pdfFiles[0]!;

      if (activeTool === "split") {
        const from = Number.isFinite(splitFrom) ? Math.floor(splitFrom) : 1;
        const to = Number.isFinite(splitTo) ? Math.floor(splitTo) : from;
        if (from <= 0 || to <= 0) throw new Error("أرقام الصفحات يجب أن تكون أكبر من 0");
        const out = await splitPdf(input, from, to);
        downloadBytes(out, "split.pdf");
        setSuccess("تم استخراج الصفحات بنجاح");
        return;
      }

      if (activeTool === "rotate") {
        const out = await rotatePdf(input, rotation);
        downloadBytes(out, `rotated-${rotation}.pdf`);
        setSuccess("تم تدوير الصفحات بنجاح");
        return;
      }

      if (activeTool === "delete") {
        let pages: number[] = [];
        if (deleteMode === "list") {
          pages = parsePagesList(pagesToDelete);
          if (pages.length === 0) throw new Error("اكتب أرقام الصفحات المراد حذفها (مثال: 2,3)");
        } else {
          const from = Math.floor(deleteFrom);
          const to = Math.floor(deleteTo);
          if (from <= 0 || to <= 0) throw new Error("أرقام الصفحات يجب أن تكون أكبر من 0");
          for (let i = Math.min(from, to); i <= Math.max(from, to); i++) {
            pages.push(i);
          }
        }
        const out = await deletePages(input, pages);
        downloadBytes(out, "deleted-pages.pdf");
        setSuccess("تم حذف الصفحات بنجاح");
        return;
      }

      if (activeTool === "watermark") {
        if (!watermarkText.trim()) throw new Error("اكتب نص العلامة المائية");
        const out = await addTextWatermark(input, watermarkText.trim());
        downloadBytes(out, "watermark.pdf");
        setSuccess("تمت إضافة العلامة المائية بنجاح");
        return;
      }

      if (activeTool === "excel_to_pdf") {
        const file = pdfFiles[0].file;
        const data = await file.arrayBuffer();
        const workbook = XLSX.read(data);
        const worksheet = workbook.Sheets[workbook.SheetNames[0]];
        const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as any[][];

        const doc = new jsPDF();
        autoTable(doc, {
          head: [jsonData[0]],
          body: jsonData.slice(1),
          styles: { font: "helvetica", halign: "right" }, // Basic RTL support hack
        });
        doc.save("excel-converted.pdf");
        setSuccess("تم تحويل الإكسل إلى PDF بنجاح");
        return;
      }

      if (activeTool === "word_to_pdf") {
        const file = pdfFiles[0].file;
        const arrayBuffer = await file.arrayBuffer();
        const result = await mammoth.extractRawText({ arrayBuffer });
        const text = result.value;

        const doc = new jsPDF();
        const splitText = doc.splitTextToSize(text, 180);
        doc.text(splitText, 10, 10);
        doc.save("word-converted.pdf");
        setSuccess("تم تحويل الوورد إلى PDF بنجاح");
        return;
      }

      if (activeTool === "pdf_to_jpg") {
        setStatusText("جاري معالجة الصفحات...");
        const file = pdfFiles[0].file;
        const arrayBuffer = await file.arrayBuffer();
        const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
        const zip = new JSZip();

        for (let i = 1; i <= pdf.numPages; i++) {
          setStatusText(`جاري تحويل صفحة ${i} من ${pdf.numPages}...`);
          const page = await pdf.getPage(i);
          const viewport = page.getViewport({ scale: 2.0 });
          const canvas = document.createElement("canvas");
          const context = canvas.getContext("2d");
          canvas.height = viewport.height;
          canvas.width = viewport.width;

          // @ts-ignore
          await page.render({ canvasContext: context!, viewport }).promise;
          const blob = await new Promise<Blob | null>(resolve => canvas.toBlob(resolve, "image/jpeg", 0.9));
          if (blob) zip.file(`page-${i}.jpg`, blob);
        }

        const content = await zip.generateAsync({ type: "blob" });
        const url = URL.createObjectURL(content);
        const a = document.createElement("a");
        a.href = url;
        a.download = "pdf-pages.zip";
        a.click();
        setSuccess("تم تحويل PDF إلى صور بنجاح (تحقق من التحميلات)");
        return;
      }

      if (activeTool === "jpg_to_pdf") {
        setStatusText("جاري تجميع الصور...");
        const doc = new jsPDF();
        for (let i = 0; i < pdfFiles.length; i++) {
          setStatusText(`جاري إضافة صورة ${i + 1} من ${pdfFiles.length}...`);
          const file = pdfFiles[i].file;
          const imgData = await new Promise<string>((resolve) => {
            const reader = new FileReader();
            reader.onload = (e) => resolve(e.target?.result as string);
            reader.readAsDataURL(file);
          });

          if (i > 0) doc.addPage();
          const props = doc.getImageProperties(imgData);
          const pdfWidth = doc.internal.pageSize.getWidth();
          const pdfHeight = (props.height * pdfWidth) / props.width;
          doc.addImage(imgData, "JPEG", 0, 0, pdfWidth, pdfHeight);
        }
        doc.save("images-converted.pdf");
        setSuccess("تم تجميع الصور في ملف PDF بنجاح");
        return;
      }

      throw new Error("هذه الأداة غير متاحة حاليًا");
    } catch (e) {
      const msg = e instanceof Error ? e.message : "حدث خطأ غير معروف";
      setError(msg);
    } finally {
      setBusy(false);
    }
  }

  const dropzoneTitle = activeTool === "merge" ? "اسحب ملفات PDF هنا" : "اسحب ملف PDF هنا";

  return (
    <div className="min-h-screen bg-background">
      <main>
        <section className="gradient-hero border-b">
          <div className="container py-12">
            <div className="grid items-center gap-10 lg:grid-cols-2">
              <div className="animate-slide-up">
                <div className="flex flex-wrap items-center gap-3 mb-4">
                  <span className="rounded-full bg-success/10 px-3 py-1 text-[10px] font-bold text-success">خصوصية 100%</span>
                  <ShareTool title="أدوات PDF" description="دمج وتقسيم ملفات PDF بخصوصية تامة داخل المتصفح" />
                </div>
                <h1 className="text-3xl font-extrabold leading-tight sm:text-4xl">
                  أدوات PDF
                  <span className="text-gradient"> مجانية</span>
                  <span className="text-gradient"> واحترافية</span>
                </h1>
                <p className="mt-4 text-sm leading-7 text-muted-foreground sm:text-base">
                  دمج، تقسيم، تدوير، حذف صفحات، وإضافة علامة مائية — كل ذلك يتم محليًا داخل المتصفح لحماية ملفاتك.
                </p>

                <div className="mt-6">
                  <button
                    type="button"
                    onClick={() => document.getElementById("tools")?.scrollIntoView({ behavior: "smooth" })}
                    className="rounded-xl bg-primary px-8 py-3 text-sm font-extrabold text-primary-foreground shadow-md transition hover:opacity-95"
                  >
                    ابدأ الآن
                  </button>
                </div>
              </div>

              <div className="animate-fade-in">
                <div className="gradient-card rounded-3xl border border-border p-6 shadow-lg">
                  <div className="flex items-center justify-between">
                    <div className="text-sm font-extrabold">الأداة الحالية</div>
                    <div className="rounded-full bg-primary/10 px-3 py-1 text-xs font-bold text-primary">
                      {TOOL_META[activeTool].title}
                    </div>
                  </div>

                  <div className="mt-5">
                    <FileDropzone
                      accept={
                        activeTool === "excel_to_pdf"
                          ? ".xlsx, .xls"
                          : activeTool === "word_to_pdf"
                            ? ".docx"
                            : activeTool === "jpg_to_pdf"
                              ? "image/*"
                              : "application/pdf"
                      }
                      multiple={activeTool === "merge" || activeTool === "jpg_to_pdf"}
                      onFiles={addFiles}
                      title={
                        activeTool === "excel_to_pdf"
                          ? "اسحب ملف Excel هنا"
                          : activeTool === "word_to_pdf"
                            ? "اسحب ملف Word هنا"
                            : activeTool === "jpg_to_pdf"
                              ? "اسحب الصور هنا"
                              : dropzoneTitle
                      }
                      subtitle={
                        activeTool === "merge"
                          ? "اختر ملفين أو أكثر للدمج"
                          : activeTool === "excel_to_pdf"
                            ? "دعم XLSX, XLS"
                            : activeTool === "word_to_pdf"
                              ? "دعم DOCX فقط"
                              : activeTool === "jpg_to_pdf"
                                ? "يمكن اختيار عدة صور"
                                : "اختر ملف واحد للتعديل"
                      }
                    />
                  </div>

                  {pdfFiles.length > 0 ? (
                    <div className="mt-5 rounded-2xl border border-border bg-card p-4">
                      <div className="flex items-center justify-between">
                        <div className="text-sm font-extrabold">الملفات المختارة ({pdfFiles.length})</div>
                        <button
                          type="button"
                          onClick={reset}
                          className="text-xs font-bold text-muted-foreground hover:text-foreground"
                        >
                          مسح الكل
                        </button>
                      </div>
                      <div className="mt-4 max-h-[220px] overflow-y-auto space-y-2 pr-1">
                        {pdfFiles.map((f, index) => (
                          <div key={index} className="flex items-center justify-between rounded-xl bg-muted/50 px-3 py-2 border border-border/40">
                            <div className="flex items-center gap-3">
                              <button
                                onClick={() => removeFile(index)}
                                className="text-destructive hover:bg-destructive/10 p-1 rounded-lg transition"
                              >
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
                              </button>
                              <div className="truncate text-xs font-bold">{f.name}</div>
                            </div>
                            <span className="text-primary text-lg">📄</span>
                          </div>
                        ))}
                      </div>
                      <div className="mt-4 pt-3 border-t border-border/40">
                        <AddMoreButton
                          onFiles={addFiles}
                          multiple
                          accept={activeTool === "excel_to_pdf" ? ".xlsx, .xls" : activeTool === "word_to_pdf" ? ".docx" : activeTool === "jpg_to_pdf" ? "image/*" : "application/pdf"}
                          label="+ إضافة ملفات أخرى"
                        />
                      </div>
                    </div>
                  ) : null}
                </div>
              </div>
            </div>
          </div>
        </section>

        <div id="tools" />
        <Section title="الأدوات" subtitle="اختر الأداة التي تريدها ثم ارفع الملف/الملفات.">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {(Object.keys(TOOL_META) as ToolId[]).map((id) => (
              <ToolCard
                key={id}
                title={TOOL_META[id].title}
                description={TOOL_META[id].description}
                icon={<span className="text-xl">{TOOL_META[id].icon}</span>}
                active={activeTool === id}
                onClick={() => {
                  setActiveTool(id);
                  setError(null);
                  setSuccess(null);
                  setPdfFiles((prev) => {
                    if (id === "merge" || id === "jpg_to_pdf") return prev;
                    return prev.length > 0 ? [prev[0]] : [];
                  });
                }}
              />
            ))}
          </div>

          <div className="mt-6 rounded-3xl border border-border bg-card/80 p-6 shadow-sm">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
              <div>
                <div className="text-lg font-extrabold">إعدادات الأداة</div>
                <div className="mt-1 text-sm text-muted-foreground">حسب الأداة المختارة</div>
              </div>

              <div className="w-full max-w-2xl">
                {activeTool === "split" ? (
                  <div className="grid gap-3 sm:grid-cols-2">
                    <label className="space-y-1">
                      <div className="text-xs font-bold text-muted-foreground">من صفحة</div>
                      <input
                        value={splitFrom}
                        onChange={(e) => setSplitFrom(Number(e.target.value))}
                        placeholder="1"
                        inputMode="numeric"
                        type="number"
                        min={1}
                        max={pageCount ?? undefined}
                        className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                      />
                    </label>
                    <label className="space-y-1">
                      <div className="text-xs font-bold text-muted-foreground">إلى صفحة</div>
                      <input
                        value={splitTo}
                        onChange={(e) => setSplitTo(Number(e.target.value))}
                        placeholder="1"
                        inputMode="numeric"
                        type="number"
                        min={1}
                        max={pageCount ?? undefined}
                        className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                      />
                    </label>
                    {pageCount ? (
                      <div className="sm:col-span-2 text-xs font-bold text-muted-foreground">
                        عدد صفحات الملف: {pageCount}
                      </div>
                    ) : null}
                  </div>
                ) : null}

                {activeTool === "rotate" ? (
                  <div className="grid gap-3 sm:grid-cols-2">
                    <label className="space-y-1">
                      <div className="text-xs font-bold text-muted-foreground">درجة التدوير</div>
                      <select
                        value={rotation}
                        onChange={(e) => setRotation(Number(e.target.value) as 90 | 180 | 270)}
                        className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                      >
                        <option value={90}>90°</option>
                        <option value={180}>180°</option>
                        <option value={270}>270°</option>
                      </select>
                    </label>
                  </div>
                ) : null}

                {activeTool === "delete" ? (
                  <div className="space-y-4">
                    <div className="flex gap-2 p-1 bg-muted rounded-xl w-fit">
                      <button
                        onClick={() => setDeleteMode("list")}
                        className={`px-4 py-1.5 text-xs font-bold rounded-lg transition ${deleteMode === "list" ? "bg-background shadow-sm text-primary" : "text-muted-foreground hover:text-foreground"}`}
                      >
                        صفحات محددة
                      </button>
                      <button
                        onClick={() => setDeleteMode("range")}
                        className={`px-4 py-1.5 text-xs font-bold rounded-lg transition ${deleteMode === "range" ? "bg-background shadow-sm text-primary" : "text-muted-foreground hover:text-foreground"}`}
                      >
                        نطاق صفحات (من-إلى)
                      </button>
                    </div>

                    {deleteMode === "list" ? (
                      <div className="grid gap-3">
                        <label className="space-y-1">
                          <div className="text-xs font-bold text-muted-foreground">أرقام الصفحات للحذف</div>
                          <input
                            value={pagesToDelete}
                            onChange={(e) => setPagesToDelete(e.target.value)}
                            placeholder="مثال: 2, 3, 8"
                            className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                          />
                        </label>
                      </div>
                    ) : (
                      <div className="grid gap-3 sm:grid-cols-2">
                        <label className="space-y-1">
                          <div className="text-xs font-bold text-muted-foreground">من صفحة</div>
                          <input
                            value={deleteFrom}
                            onChange={(e) => setDeleteFrom(Number(e.target.value))}
                            type="number"
                            min={1}
                            max={pageCount ?? undefined}
                            className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                          />
                        </label>
                        <label className="space-y-1">
                          <div className="text-xs font-bold text-muted-foreground">إلى صفحة</div>
                          <input
                            value={deleteTo}
                            onChange={(e) => setDeleteTo(Number(e.target.value))}
                            type="number"
                            min={1}
                            max={pageCount ?? undefined}
                            className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                          />
                        </label>
                      </div>
                    )}
                    {pageCount ? (
                      <div className="text-[10px] font-bold text-muted-foreground">
                        عدد الصفحات المتاحة: {pageCount}
                      </div>
                    ) : null}
                  </div>
                ) : null}

                {activeTool === "watermark" ? (
                  <div className="grid gap-3 sm:grid-cols-2">
                    <label className="space-y-1">
                      <div className="text-xs font-bold text-muted-foreground">نص العلامة المائية</div>
                      <input
                        value={watermarkText}
                        onChange={(e) => setWatermarkText(e.target.value)}
                        placeholder="مثال: سري"
                        className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/40"
                      />
                    </label>
                  </div>
                ) : null}

                {activeTool === "merge" ? <div className="text-sm text-muted-foreground">ارفع ملفين أو أكثر، ثم اضغط تنفيذ.</div> : null}
                {activeTool === "jpg_to_pdf" ? <div className="text-sm text-muted-foreground">ارفع صورة أو أكثر ليتم تجميعها في ملف واحد.</div> : null}
              </div>
            </div>

            <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div className="space-y-2">
                {error ? (
                  <div className="rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm font-bold text-destructive">
                    {error}
                  </div>
                ) : null}
                {success ? (
                  <div className="rounded-xl border border-success/30 bg-success/10 px-4 py-3 text-sm font-bold text-success">
                    {success}
                  </div>
                ) : null}
              </div>

              <button
                type="button"
                onClick={runTool}
                disabled={!canRun || busy}
                className={
                  "rounded-xl px-5 py-3 text-sm font-extrabold shadow-md transition " +
                  (canRun && !busy
                    ? "bg-primary text-primary-foreground hover:opacity-95"
                    : "cursor-not-allowed bg-muted text-muted-foreground")
                }
              >
                {busy ? (statusText || "جاري التنفيذ...") : "تنفيذ"}
              </button>
            </div>
          </div>
        </Section>


        <Section title="الأسئلة الشائعة" subtitle="إجابات سريعة">
          <div className="space-y-3">
            <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm">
              <div className="text-sm font-extrabold">هل ترفعون ملفاتي للسيرفر؟</div>
              <div className="mt-2 text-sm text-muted-foreground">لا. المعالجة تتم محليًا داخل المتصفح.</div>
            </div>
            <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm">
              <div className="text-sm font-extrabold">هل الخدمة مجانية؟</div>
              <div className="mt-2 text-sm text-muted-foreground">نعم، مجانية بالكامل للاستخدام الشخصي.</div>
            </div>
          </div>
        </Section>
      </main>

    </div>
  );
}
