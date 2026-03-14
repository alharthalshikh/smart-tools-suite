import {
  degrees,
  PDFDocument,
  rgb,
  StandardFonts,
} from "pdf-lib";

export type PdfInputFile = {
  file: File;
  bytes: Uint8Array;
  name: string;
};

export async function readPdfFile(file: File): Promise<PdfInputFile> {
  const ab = await file.arrayBuffer();
  return {
    file,
    bytes: new Uint8Array(ab),
    name: file.name,
  };
}

export async function getPdfPageCount(input: PdfInputFile): Promise<number> {
  const pdf = await PDFDocument.load(input.bytes);
  return pdf.getPageCount();
}

export function downloadBytes(bytes: Uint8Array, filename: string) {
  const blob = new Blob([bytes as unknown as BlobPart], { type: "application/pdf" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

export async function mergePdfs(files: PdfInputFile[]): Promise<Uint8Array> {
  const mergedPdf = await PDFDocument.create();

  for (const f of files) {
    const pdf = await PDFDocument.load(f.bytes);
    const pages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
    for (const p of pages) mergedPdf.addPage(p);
  }

  return await mergedPdf.save();
}

export async function splitPdf(
  input: PdfInputFile,
  fromPage: number,
  toPage: number,
): Promise<Uint8Array> {
  const src = await PDFDocument.load(input.bytes);
  const pageCount = src.getPageCount();

  const start = Math.max(1, Math.min(fromPage, pageCount));
  const end = Math.max(start, Math.min(toPage, pageCount));

  const out = await PDFDocument.create();
  const indices = [] as number[];
  for (let i = start - 1; i <= end - 1; i++) indices.push(i);

  const pages = await out.copyPages(src, indices);
  for (const p of pages) out.addPage(p);

  return await out.save();
}

export async function rotatePdf(input: PdfInputFile, rotationDeg: 90 | 180 | 270) {
  const pdf = await PDFDocument.load(input.bytes);
  for (const page of pdf.getPages()) {
    const current = page.getRotation().angle;
    page.setRotation(degrees((current + rotationDeg) % 360));
  }
  return await pdf.save();
}

export async function deletePages(
  input: PdfInputFile,
  pagesToDelete1Based: number[],
): Promise<Uint8Array> {
  const src = await PDFDocument.load(input.bytes);
  const total = src.getPageCount();
  const toDelete = new Set(
    pagesToDelete1Based
      .map((p) => Math.floor(p))
      .filter((p) => p >= 1 && p <= total)
      .map((p) => p - 1),
  );

  const out = await PDFDocument.create();
  const keepIndices: number[] = [];
  for (let i = 0; i < total; i++) {
    if (!toDelete.has(i)) keepIndices.push(i);
  }

  const pages = await out.copyPages(src, keepIndices);
  for (const p of pages) out.addPage(p);

  return await out.save();
}

export async function addTextWatermark(
  input: PdfInputFile,
  text: string,
): Promise<Uint8Array> {
  const pdf = await PDFDocument.load(input.bytes);
  const font = await pdf.embedFont(StandardFonts.HelveticaBold);

  for (const page of pdf.getPages()) {
    const { width, height } = page.getSize();

    page.drawText(text, {
      x: width * 0.1,
      y: height * 0.5,
      size: Math.max(18, Math.min(48, Math.floor(width / 12))),
      font,
      color: rgb(0.1, 0.1, 0.1),
      opacity: 0.15,
      rotate: degrees(-25),
    });
  }

  return await pdf.save();
}

export type PageRange = {
  from: number;
  to: number;
};

export function parsePageRange(value: string): PageRange | null {
  const trimmed = value.trim();
  if (!trimmed) return null;

  const m = trimmed.match(/^\s*(\d+)\s*(-|:|\.\.)\s*(\d+)\s*$/);
  if (!m) return null;

  const from = Number(m[1]);
  const to = Number(m[3]);
  if (!Number.isFinite(from) || !Number.isFinite(to)) return null;

  return { from, to };
}

export function parsePagesList(value: string): number[] {
  const trimmed = value.trim();
  if (!trimmed) return [];

  const parts = trimmed.split(/[,\s]+/g);
  const pages: number[] = [];
  for (const part of parts) {
    const n = Number(part);
    if (Number.isFinite(n) && n > 0) pages.push(Math.floor(n));
  }
  return pages;
}
