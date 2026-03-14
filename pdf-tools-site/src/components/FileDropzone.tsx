import { useCallback, useMemo, useRef, useState } from "react";

type Props = {
  accept?: string;
  multiple?: boolean;
  onFiles: (files: File[]) => void;
  title: string;
  subtitle?: string;
};

export function FileDropzone({ accept, multiple, onFiles, title, subtitle }: Props) {
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [isDragging, setIsDragging] = useState(false);

  const acceptLabel = useMemo(() => {
    if (!accept) return undefined;
    if (accept.includes("pdf")) return "PDF";
    if (accept.includes("image")) return "صور";
    return accept;
  }, [accept]);

  const handlePick = useCallback(() => {
    inputRef.current?.click();
  }, []);

  const handleFiles = useCallback(
    (fileList: FileList | null) => {
      if (!fileList) return;
      const files = Array.from(fileList);
      if (files.length === 0) return;
      onFiles(files);
    },
    [onFiles],
  );

  return (
    <div
      className={
        "relative overflow-hidden rounded-2xl border bg-card/80 p-6 shadow-md transition " +
        (isDragging ? "border-primary shadow-glow" : "border-border")
      }
      onDragEnter={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(true);
      }}
      onDragOver={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(true);
      }}
      onDragLeave={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(false);
      }}
      onDrop={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(false);
        handleFiles(e.dataTransfer.files);
      }}
    >
      <div className="pointer-events-none absolute -top-24 left-10 h-52 w-52 rounded-full bg-primary/10 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-24 right-10 h-52 w-52 rounded-full bg-secondary/10 blur-3xl" />

      <div className="flex flex-col items-center gap-3 text-center">
        <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary">
          <span className="text-xl">⬇</span>
        </div>
        <div className="space-y-1">
          <div className="text-lg font-bold">{title}</div>
          {subtitle ? <div className="text-sm text-muted-foreground">{subtitle}</div> : null}
        </div>

        <div className="flex flex-col gap-2 sm:flex-row">
          <button
            type="button"
            onClick={handlePick}
            className="inline-flex items-center justify-center rounded-xl bg-primary px-4 py-2 text-sm font-bold text-primary-foreground shadow-md transition hover:opacity-95"
          >
            اختر {acceptLabel ?? "ملف"}
          </button>
          <div className="text-sm text-muted-foreground sm:pt-2">
            أو اسحب وأفلت هنا
          </div>
        </div>

        <input
          ref={inputRef}
          type="file"
          multiple={multiple}
          accept={accept}
          className="hidden"
          onChange={(e) => handleFiles(e.target.files)}
        />
      </div>
    </div>
  );
}
