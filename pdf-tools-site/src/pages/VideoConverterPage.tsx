import { useState, useRef } from "react";
import { FFmpeg } from "@ffmpeg/ffmpeg";
import { fetchFile, toBlobURL } from "@ffmpeg/util";
import { FileDropzone } from "../components/FileDropzone";
import { AddMoreButton } from "../components/AddMoreButton";

export function VideoConverterPage() {
    const [loaded, setLoaded] = useState(false);
    const [busy, setBusy] = useState(false);
    const [progress, setProgress] = useState(0);
    const [videoFiles, setVideoFiles] = useState<File[]>([]);
    const [audioResults, setAudioResults] = useState<{ name: string, url: string }[]>([]);
    const [error, setError] = useState<string | null>(null);

    const ffmpegRef = useRef(new FFmpeg());

    async function loadFFmpeg() {
        setBusy(true);
        const baseURL = "https://unpkg.com/@ffmpeg/core@0.12.6/dist/esm";
        const ffmpeg = ffmpegRef.current;

        ffmpeg.on("log", ({ message }) => {
            console.log(message);
        });

        ffmpeg.on("progress", ({ progress }) => {
            setProgress(Math.round(progress * 100));
        });

        try {
            await ffmpeg.load({
                coreURL: await toBlobURL(`${baseURL}/ffmpeg-core.js`, "text/javascript"),
                wasmURL: await toBlobURL(`${baseURL}/ffmpeg-core.wasm`, "application/wasm"),
            });
            setLoaded(true);
        } catch (e) {
            setError("فشل تحميل محرك التحويل. يرجى التأكد من اتصال الإنترنت.");
        } finally {
            setBusy(false);
        }
    }

    async function convertAll() {
        if (videoFiles.length === 0) return;
        if (!loaded) await loadFFmpeg();

        setBusy(true);
        setProgress(0);
        setError(null);
        setAudioResults([]);

        try {
            const ffmpeg = ffmpegRef.current;
            const newResults: { name: string, url: string }[] = [];

            for (let i = 0; i < videoFiles.length; i++) {
                const f = videoFiles[i];
                const inputName = `input_${i}`;
                const outputName = `output_${i}.mp3`;

                await ffmpeg.writeFile(inputName, await fetchFile(f));
                await ffmpeg.exec(["-i", inputName, "-vn", "-acodec", "libmp3lame", "-q:a", "2", outputName]);

                const data = await ffmpeg.readFile(outputName);
                const url = URL.createObjectURL(new Blob([(data as any).buffer], { type: "audio/mp3" }));
                newResults.push({ name: f.name.replace(/\.[^.]+$/, ""), url });
                setProgress(Math.round(((i + 1) / videoFiles.length) * 100));
            }

            setAudioResults(newResults);
        } catch (e) {
            setError("حدث خطأ أثناء التحويل. تأكد من أن ملفات الفيديو مدعومة.");
        } finally {
            setBusy(false);
        }
    }

    function removeFile(index: number) {
        setVideoFiles(prev => prev.filter((_, i) => i !== index));
    }

    function addFiles(files: File[]) {
        setError(null);
        setVideoFiles(prev => [...prev, ...files]);
    }

    function downloadAudio(url: string, name: string) {
        const a = document.createElement("a");
        a.href = url;
        a.download = `${name}.mp3`;
        a.click();
    }

    return (
        <main>
            <section className="gradient-hero border-b">
                <div className="container py-12">
                    <h1 className="text-3xl font-extrabold">تحويل الفيديو إلى صوت</h1>
                    <p className="mt-3 text-sm text-muted-foreground">
                        استخراج الصوت من ملفات الفيديو (MP4, MKV, MOV) بصيغة MP3 عالية الجودة.
                    </p>
                </div>
            </section>

            <section className="py-10">
                <div className="container max-w-3xl">
                    <div className="rounded-3xl border border-border bg-card/80 p-8 shadow-sm">
                        {audioResults.length === 0 ? (
                            <div className="space-y-6">
                                <FileDropzone
                                    accept="video/*"
                                    multiple={true}
                                    onFiles={addFiles}
                                    title="اسحب ملفات الفيديو هنا"
                                    subtitle="يدعم MP4, WebM, MKV وأكثر"
                                />

                                {videoFiles.length > 0 && (
                                    <div className="rounded-2xl border border-border bg-background p-4 animate-in fade-in slide-in-from-bottom-2">
                                        <div className="flex items-center justify-between mb-3">
                                            <div className="text-sm font-extrabold text-muted-foreground whitespace-nowrap">الملفات ({videoFiles.length})</div>
                                            <button
                                                onClick={() => setVideoFiles([])}
                                                className="text-[10px] font-bold text-muted-foreground hover:text-destructive transition"
                                            >
                                                مسح الكل ✕
                                            </button>
                                        </div>
                                        <div className="max-h-[150px] overflow-y-auto space-y-2 pr-1 mb-4">
                                            {videoFiles.map((f, index) => (
                                                <div key={index} className="flex items-center justify-between rounded-xl bg-muted/50 px-3 py-2 border border-border/40">
                                                    <div className="flex items-center gap-3">
                                                        <button
                                                            onClick={() => removeFile(index)}
                                                            className="text-destructive hover:bg-destructive/10 p-1 rounded-lg transition"
                                                        >
                                                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
                                                        </button>
                                                        <div className="truncate text-[11px] font-bold">{f.name}</div>
                                                    </div>
                                                    <span className="text-primary text-sm">📹</span>
                                                </div>
                                            ))}
                                        </div>

                                        <div className="flex flex-col gap-3">
                                            <button
                                                onClick={convertAll}
                                                disabled={busy}
                                                className="w-full rounded-2xl bg-primary py-4 text-sm font-extrabold text-primary-foreground shadow-lg transition hover:scale-[1.01] hover:opacity-95 disabled:opacity-50 text-gradient-rev"
                                            >
                                                {busy ? `جاري معالجة الكل (${progress}%)...` : "بدء تحويل الكل إلى MP3"}
                                            </button>

                                            {!busy && (
                                                <AddMoreButton
                                                    onFiles={addFiles}
                                                    accept="video/*"
                                                    label="+ إضافة المزيد"
                                                />
                                            )}

                                            {busy && (
                                                <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
                                                    <div
                                                        className="h-full bg-primary transition-all duration-300"
                                                        style={{ width: `${progress}%` }}
                                                    />
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                )}
                            </div>
                        ) : (
                            <div className="animate-in zoom-in-95 space-y-6">
                                <div className="text-center">
                                    <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-success/10 text-success mb-4">
                                        <span className="text-2xl">✓</span>
                                    </div>
                                    <h2 className="text-xl font-extrabold">تم تحويل {audioResults.length} ملفات!</h2>
                                </div>

                                <div className="max-h-[300px] overflow-y-auto space-y-3 pr-2">
                                    {audioResults.map((res, i) => (
                                        <div key={i} className="rounded-2xl border border-border bg-background p-4 space-y-3 shadow-sm">
                                            <div className="flex items-center justify-between gap-4">
                                                <div className="truncate text-xs font-black">{res.name}</div>
                                                <button
                                                    onClick={() => downloadAudio(res.url, res.name)}
                                                    className="rounded-lg bg-primary/10 px-3 py-1.5 text-[10px] font-black text-primary hover:bg-primary hover:text-white transition"
                                                >
                                                    تحميل MP3
                                                </button>
                                            </div>
                                            <audio controls className="h-8 w-full accent-primary shadow-inner rounded-lg">
                                                <source src={res.url} type="audio/mp3" />
                                            </audio>
                                        </div>
                                    ))}
                                </div>

                                <div className="pt-4 flex justify-center">
                                    <button
                                        onClick={() => {
                                            setAudioResults([]);
                                            setVideoFiles([]);
                                        }}
                                        className="rounded-xl border border-border bg-card/70 px-8 py-3 text-sm font-extrabold shadow-sm transition hover:bg-card"
                                    >
                                        تحويل ملفات أخرى
                                    </button>
                                </div>
                            </div>
                        )}

                        {error && (
                            <div className="mt-6 rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm font-bold text-destructive animate-in shake-1">
                                {error}
                            </div>
                        )}
                    </div>

                    <div className="mt-8 rounded-2xl border border-border bg-muted/30 p-4 text-xs text-muted-foreground">
                        <h3 className="font-bold text-foreground mb-2">لماذا هذه الأداة؟</h3>
                        <ul className="list-disc list-inside space-y-1">
                            <li>خصوصية تامة: التحويل يتم بالكامل داخل جهازك ولا يتم رفع الفيديو لأي مكان.</li>
                            <li>جودة عالية: نستخدم أفضل التقنيات البرمجية لضمان استخراج الصوت بأعلى نقاء ممكن.</li>
                            <li>سرعة فائقة: المعالجة فورية وتعتمد على قوة جهازك الشخصي.</li>
                        </ul>
                    </div>
                </div>
            </section>
        </main>
    );
}
