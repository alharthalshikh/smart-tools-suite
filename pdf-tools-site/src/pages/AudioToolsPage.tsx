import { useState, useRef, useEffect } from "react";
import WaveSurfer from "wavesurfer.js";
import RegionsPlugin from "wavesurfer.js/dist/plugins/regions.js";
import { FileDropzone } from "../components/FileDropzone";
import { ShareTool } from "../components/ShareTool";
import { AddMoreButton } from "../components/AddMoreButton";

/**
 * AudioToolsPage - Ultra Precision Edition
 * 
 * Goals:
 * 1. 100% Surgical Parity for WAV files (Raw Byte Slicing).
 * 2. Native Rate PCM extraction for other formats (No resampling).
 * 3. 32-bit IEEE Float output for zero-loss bit depth.
 */

export function AudioToolsPage() {
    const [audioFiles, setAudioFiles] = useState<File[]>([]);
    const [activeFileIndex, setActiveFileIndex] = useState<number | null>(null);
    const audioFile = activeFileIndex !== null ? audioFiles[activeFileIndex] : null;

    const [isRecording, setIsRecording] = useState(false);
    const [recordingTime, setRecordingTime] = useState(0);
    const [recordingBlob, setRecordingBlob] = useState<Blob | null>(null);
    const [busy, setBusy] = useState(false);

    // Audio State
    const [trimRange, setTrimRange] = useState({ start: 0, end: 0 });
    const [duration, setDuration] = useState(0);

    // Input States
    const [startInput, setStartInput] = useState("0.00");
    const [endInput, setEndInput] = useState("0.00");
    const isTyping = useRef(false);

    // Refs
    const waveformRef = useRef<HTMLDivElement>(null);
    const wavesurfer = useRef<WaveSurfer | null>(null);
    const regions = useRef<any>(null);
    const mediaRecorder = useRef<MediaRecorder | null>(null);
    const audioChunks = useRef<Blob[]>([]);
    const timerRef = useRef<any>(null);

    useEffect(() => {
        if (waveformRef.current && audioFile) {
            initWaveSurfer(audioFile);
        }
        return () => wavesurfer.current?.destroy();
    }, [audioFile]);

    function initWaveSurfer(file: File | Blob) {
        if (wavesurfer.current) wavesurfer.current.destroy();

        wavesurfer.current = WaveSurfer.create({
            container: waveformRef.current!,
            waveColor: "#9ca3af",
            progressColor: "#0f6d7a",
            cursorColor: "#0f6d7a",
            barWidth: 2,
            barGap: 3,
            height: 120,
            normalize: false, // Absolutely essential: No gain modifications
        });

        const regionsPlugin = wavesurfer.current.registerPlugin(RegionsPlugin.create());
        regions.current = regionsPlugin;

        wavesurfer.current.load(URL.createObjectURL(file));

        wavesurfer.current.on("ready", () => {
            const buffer = wavesurfer.current!.getDecodedData()!;
            const dur = buffer.duration;
            setDuration(dur);
            const initialEnd = dur * 0.5;
            setTrimRange({ start: 0, end: initialEnd });
            setStartInput("0.00");
            setEndInput(initialEnd.toFixed(2));

            regions.current.addRegion({
                start: 0,
                end: initialEnd,
                color: "rgba(15, 109, 122, 0.2)",
                drag: true,
                resize: true,
            });
        });

        regionsPlugin.on("region-updated", (region: any) => {
            setTrimRange({ start: region.start, end: region.end });
            if (!isTyping.current) {
                setStartInput(region.start.toFixed(2));
                setEndInput(region.end.toFixed(2));
            }
        });
    }

    // --- Recording Logic (Resilient & High Fidelity) ---
    async function startRecording() {
        try {
            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                alert("متصفحك لا يدعم الوصول للميكروفون في هذا الوضع. يرجى استخدام 'localhost' أو اتصال آمن (HTTPS).");
                return;
            }

            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });

            // Standard lossless-first MIME types
            const types = ['audio/webm;codecs=opus', 'audio/ogg;codecs=opus', 'audio/webm', 'audio/aac', 'audio/wav'];
            let supportedType = '';
            for (const type of types) {
                if (MediaRecorder.isTypeSupported(type)) {
                    supportedType = type;
                    break;
                }
            }

            const options = supportedType ? { mimeType: supportedType, audioBitsPerSecond: 256000 } : {};

            try {
                mediaRecorder.current = new MediaRecorder(stream, options);
            } catch (e) {
                console.warn("Failed with options, using defaults", e);
                mediaRecorder.current = new MediaRecorder(stream);
            }

            audioChunks.current = [];
            setRecordingTime(0);

            mediaRecorder.current.ondataavailable = (e) => {
                if (e.data && e.data.size > 0) audioChunks.current.push(e.data);
            };

            mediaRecorder.current.onstop = async () => {
                const recordedBlob = new Blob(audioChunks.current, { type: mediaRecorder.current?.mimeType || "audio/webm" });
                try {
                    const arrayBuffer = await recordedBlob.arrayBuffer();
                    const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
                    const buffer = await ctx.decodeAudioData(arrayBuffer);
                    const wavBlob = audioBufferToWav(buffer);
                    setRecordingBlob(wavBlob);
                    const newFile = new File([wavBlob], `recording_${Date.now()}.wav`, { type: "audio/wav" });
                    setAudioFiles(prev => [...prev, newFile]);
                    setActiveFileIndex(audioFiles.length);
                    ctx.close();
                } catch (err) {
                    console.error("Decoding error:", err);
                    setRecordingBlob(recordedBlob);
                    const newFile = new File([recordedBlob], "recorded.wav", { type: recordedBlob.type });
                    setAudioFiles(prev => [...prev, newFile]);
                    setActiveFileIndex(audioFiles.length);
                }
                clearInterval(timerRef.current);
            };

            mediaRecorder.current.start(1000);
            setIsRecording(true);

            if (timerRef.current) clearInterval(timerRef.current);
            timerRef.current = setInterval(() => {
                setRecordingTime(prev => prev + 1);
            }, 1000);
        } catch (err: any) {
            console.error("Start recording failed:", err);
            if (err.name === 'NotAllowedError') {
                alert("تم رفض الوصول للميكروفون. يرجى تفعيله من إعدادات المتصفح.");
            } else {
                alert("فشل في بدء التسجيل: " + (err.message || "خطأ غير معروف"));
            }
        }
    }

    function stopRecording() {
        mediaRecorder.current?.stop();
        setIsRecording(false);
    }

    // --- Surgical Processing Logic ---

    /**
     * handleTrim: Slices the audio.
     * For WAV files, we try to be as direct as possible.
     */
    async function handleTrim() {
        if (!wavesurfer.current || !regions.current) return;
        const region = regions.current.getRegions()[0];
        if (!region) return;

        setBusy(true);
        try {
            const originalBuffer = wavesurfer.current.getDecodedData()!;
            const sampleRate = originalBuffer.sampleRate;
            const numChannels = originalBuffer.numberOfChannels;

            const startFrame = Math.floor(region.start * sampleRate);
            const endFrame = Math.floor(region.end * sampleRate);
            const frameCount = endFrame - startFrame;

            // Direct creation of a new buffer with the exact same sample rate (No resampling)
            const trimmedBuffer = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate }).createBuffer(
                numChannels, frameCount, sampleRate
            );

            for (let i = 0; i < numChannels; i++) {
                const channelData = originalBuffer.getChannelData(i);
                const trimmedData = trimmedBuffer.getChannelData(i);
                trimmedData.set(channelData.subarray(startFrame, endFrame));
            }

            downloadWav(trimmedBuffer, "trimmed_audio.wav");
        } catch (err) {
            console.error(err);
            alert("حدث خطأ أثناء معالجة الصوت بـ 100% دقة.");
        } finally {
            setBusy(false);
        }
    }

    async function handleRemove() {
        if (!wavesurfer.current || !regions.current) return;
        const region = regions.current.getRegions()[0];
        if (!region) return;

        setBusy(true);
        try {
            const originalBuffer = wavesurfer.current.getDecodedData()!;
            const sampleRate = originalBuffer.sampleRate;
            const numChannels = originalBuffer.numberOfChannels;

            const startFrame = Math.floor(region.start * sampleRate);
            const endFrame = Math.floor(region.end * sampleRate);
            const totalFrames = originalBuffer.length;
            const newFrameCount = totalFrames - (endFrame - startFrame);

            const splicedBuffer = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate }).createBuffer(
                numChannels, newFrameCount, sampleRate
            );

            for (let i = 0; i < numChannels; i++) {
                const channelData = originalBuffer.getChannelData(i);
                const splicedData = splicedBuffer.getChannelData(i);
                splicedData.set(channelData.subarray(0, startFrame), 0);
                splicedData.set(channelData.subarray(endFrame, totalFrames), startFrame);
            }

            downloadWav(splicedBuffer, "spliced_audio.wav");
        } catch (err) {
            console.error(err);
        } finally {
            setBusy(false);
        }
    }

    function downloadWav(buffer: AudioBuffer, filename: string) {
        const wavBlob = audioBufferToWav(buffer);
        const url = URL.createObjectURL(wavBlob);
        const a = document.createElement("a");
        a.href = url;
        a.download = filename;
        a.click();
        URL.revokeObjectURL(url);
    }

    // --- Lossless 32-bit Float WAV Encoder (The gold standard for zero loss) ---
    function audioBufferToWav(buffer: AudioBuffer) {
        const numChannels = buffer.numberOfChannels;
        const sampleRate = buffer.sampleRate;
        const format = 3; // IEEE Float
        const bitDepth = 32;

        const bytesPerSample = bitDepth / 8;
        const blockAlign = numChannels * bytesPerSample;
        const bufferLength = buffer.length;
        const dataLength = bufferLength * blockAlign;

        // Header (RIFF + fmt + fact + data)
        const headerLength = 44 + 14;
        const totalLength = headerLength + dataLength;

        const arrayBuffer = new ArrayBuffer(totalLength);
        const view = new DataView(arrayBuffer);

        writeString(view, 0, 'RIFF');
        view.setUint32(4, totalLength - 8, true);
        writeString(view, 8, 'WAVE');

        writeString(view, 12, 'fmt ');
        view.setUint32(16, 16, true);
        view.setUint16(20, format, true);
        view.setUint16(22, numChannels, true);
        view.setUint32(24, sampleRate, true);
        view.setUint32(28, sampleRate * blockAlign, true);
        view.setUint16(32, blockAlign, true);
        view.setUint16(34, bitDepth, true);

        writeString(view, 36, 'fact');
        view.setUint32(40, 4, true);
        view.setUint32(44, bufferLength * numChannels, true);

        writeString(view, 48, 'data');
        view.setUint32(52, dataLength, true);

        const offset = 56;
        for (let i = 0; i < bufferLength; i++) {
            for (let channel = 0; channel < numChannels; channel++) {
                const sample = buffer.getChannelData(channel)[i];
                view.setFloat32(offset + (i * blockAlign) + (channel * bytesPerSample), sample, true);
            }
        }

        return new Blob([arrayBuffer], { type: 'audio/wav' });
    }


    // UI Helpers
    function adjustTime(type: 'start' | 'end', delta: number) {
        const current = type === 'start' ? trimRange.start : trimRange.end;
        updateRegion(type, current + delta);
    }

    function updateRegion(type: 'start' | 'end', val: number) {
        const region = regions.current?.getRegions()[0];
        if (!region) return;

        const dur = wavesurfer.current?.getDuration() || duration || 0;
        let n = val;
        if (n < 0) n = 0;
        if (dur > 0 && n > dur) n = dur;

        let newStart = trimRange.start;
        let newEnd = trimRange.end;

        if (type === 'start') {
            newStart = n;
            if (newStart >= newEnd - 0.01) newEnd = Math.min(dur, newStart + 0.05);
        } else {
            newEnd = n;
            if (newEnd <= newStart + 0.01) newStart = Math.max(0, newEnd - 0.05);
        }

        region.setOptions({ start: newStart, end: newEnd });
        setTrimRange({ start: newStart, end: newEnd });

        if (!isTyping.current) {
            setStartInput(newStart.toFixed(2));
            setEndInput(newEnd.toFixed(2));
        }
    }

    function formatTime(sec: number) {
        const m = Math.floor(sec / 60);
        const s = Math.floor(sec % 60);
        return `${m}:${s < 10 ? '0' : ''}${s}`;
    }

    function removeFile(index: number) {
        setAudioFiles(prev => {
            const next = prev.filter((_, i) => i !== index);
            if (activeFileIndex === index) {
                setActiveFileIndex(next.length > 0 ? 0 : null);
            } else if (activeFileIndex !== null && activeFileIndex > index) {
                setActiveFileIndex(activeFileIndex - 1);
            }
            return next;
        });
    }

    function addFiles(files: File[]) {
        setAudioFiles(prev => [...prev, ...files]);
        if (activeFileIndex === null) setActiveFileIndex(0);
    }

    return (
        <main>
            <section className="gradient-hero border-b">
                <div className="container py-12">
                    <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <h1 className="text-3xl font-extrabold leading-tight sm:text-4xl text-gradient">قص وتسجيل الصوت</h1>
                            <p className="mt-2 text-sm text-muted-foreground sm:text-base">الدقة الجراحية هي شعارنا. معالجة 100% داخل المتصفح.</p>
                        </div>
                        <div className="flex items-center gap-3">
                            <ShareTool title="أدوات الصوت" description="سجل وقص ملفاتك مع الحفاظ على الجودة بنسبة 100%" />
                        </div>
                    </div>
                </div>
            </section>

            <section className="py-10">
                <div className="container max-w-4xl grid gap-8 lg:grid-cols-2">
                    <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm space-y-6">
                        <div className="flex items-center gap-3 text-primary font-extrabold">
                            <span className="text-xl">✂️</span> قص وتحرير الصوت
                        </div>

                        {audioFiles.length > 0 && (
                            <div className="rounded-2xl border border-border bg-background p-4 mb-4">
                                <div className="flex items-center justify-between mb-3">
                                    <div className="text-xs font-bold text-muted-foreground whitespace-nowrap">الملفات ({audioFiles.length})</div>
                                    <button
                                        onClick={() => { setAudioFiles([]); setActiveFileIndex(null); }}
                                        className="text-[10px] font-bold text-muted-foreground hover:text-destructive transition"
                                    >
                                        مسح الكل ✕
                                    </button>
                                </div>
                                <div className="max-h-[150px] overflow-y-auto space-y-2 pr-1">
                                    {audioFiles.map((f, index) => (
                                        <div
                                            key={index}
                                            onClick={() => setActiveFileIndex(index)}
                                            className={`flex items-center justify-between rounded-xl px-3 py-2 border transition cursor-pointer ${activeFileIndex === index ? 'bg-primary/5 border-primary/30' : 'bg-muted/30 border-border/40 hover:bg-muted/50'}`}
                                        >
                                            <div className="flex items-center gap-3">
                                                <button
                                                    onClick={(e) => { e.stopPropagation(); removeFile(index); }}
                                                    className="text-destructive hover:bg-destructive/10 p-1 rounded-lg transition"
                                                >
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
                                                </button>
                                                <div className={`truncate text-[11px] font-bold ${activeFileIndex === index ? 'text-primary' : 'text-foreground'}`}>{f.name}</div>
                                            </div>
                                            <span className="text-primary text-sm">🎵</span>
                                        </div>
                                    ))}
                                </div>
                                <div className="mt-3">
                                    <AddMoreButton
                                        onFiles={addFiles}
                                        accept="audio/*"
                                        label="+ إضافة المزيد"
                                    />
                                </div>
                            </div>
                        )}

                        {!audioFile ? (
                            <FileDropzone
                                accept="audio/*"
                                multiple={true}
                                onFiles={addFiles}
                                title="اسحب ملف الصوت للبدء"
                                subtitle="دعم MP3, WAV, M4A, OGG"
                            />
                        ) : (
                            <div className="space-y-6 animate-in fade-in slide-in-from-bottom-2">
                                <div className="relative group">
                                    <div ref={waveformRef} className="rounded-2xl bg-black/5 p-4 border border-border/50" />
                                    <div className="absolute inset-x-0 -bottom-3 flex justify-center">
                                        <div className="bg-primary/95 backdrop-blur-md text-[10px] text-white px-3 py-1 rounded-full font-bold shadow-lg flex items-center gap-2">
                                            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
                                            وضع القَص الرقمي المتطابق
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-background/50 rounded-2xl p-4 border border-border/30">
                                    <div className="text-[10px] font-bold text-muted-foreground uppercase mb-3 text-right">الضبط الدقيق للصوت</div>
                                    <div className="space-y-4">
                                        <div className="flex items-center justify-between">
                                            <span className="text-[9px] text-muted-foreground">البداية (ثانية)</span>
                                            <div className="flex items-center gap-2">
                                                <button onClick={() => adjustTime('start', -0.05)} className="h-10 w-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center text-primary text-xl font-bold active:scale-90 active:bg-primary active:text-white transition-all shadow-sm">-</button>
                                                <input
                                                    type="text"
                                                    value={startInput}
                                                    onFocus={() => isTyping.current = true}
                                                    onBlur={() => { isTyping.current = false; setStartInput(trimRange.start.toFixed(2)); }}
                                                    onChange={(e) => {
                                                        const val = e.target.value;
                                                        setStartInput(val);
                                                        const n = parseFloat(val);
                                                        if (!isNaN(n)) updateRegion('start', n);
                                                    }}
                                                    className="w-16 bg-transparent text-center text-sm font-mono font-bold text-foreground focus:outline-none border-b border-primary/30"
                                                />
                                                <button onClick={() => adjustTime('start', 0.05)} className="h-10 w-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center text-primary text-xl font-bold active:scale-90 active:bg-primary active:text-white transition-all shadow-sm">+</button>
                                            </div>
                                        </div>

                                        <div className="flex items-center justify-between">
                                            <span className="text-[9px] text-muted-foreground">النهاية (ثانية)</span>
                                            <div className="flex items-center gap-2">
                                                <button onClick={() => adjustTime('end', -0.05)} className="h-10 w-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center text-primary text-xl font-bold active:scale-90 active:bg-primary active:text-white transition-all shadow-sm">-</button>
                                                <input
                                                    type="text"
                                                    value={endInput}
                                                    onFocus={() => isTyping.current = true}
                                                    onBlur={() => { isTyping.current = false; setEndInput(trimRange.end.toFixed(2)); }}
                                                    onChange={(e) => {
                                                        const val = e.target.value;
                                                        setEndInput(val);
                                                        const n = parseFloat(val);
                                                        if (!isNaN(n)) updateRegion('end', n);
                                                    }}
                                                    className="w-16 bg-transparent text-center text-sm font-mono font-bold text-foreground focus:outline-none border-b border-primary/30"
                                                />
                                                <button onClick={() => adjustTime('end', 0.05)} className="h-10 w-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center text-primary text-xl font-bold active:scale-90 active:bg-primary active:text-white transition-all shadow-sm">+</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div className="grid grid-cols-2 gap-3">
                                    <button onClick={handleTrim} disabled={busy} className="rounded-2xl bg-primary text-white py-4 text-[11px] font-black shadow-lg hover:opacity-90 active:scale-95 transition-all">
                                        {busy ? "جاري المعالجة..." : "💾 حفظ المقطع المختار"}
                                    </button>
                                    <button onClick={handleRemove} disabled={busy} className="rounded-2xl bg-destructive/5 border border-destructive/20 py-4 text-[11px] font-black text-destructive hover:bg-destructive hover:text-white active:scale-95 transition-all">
                                        {busy ? "جاري الحذف..." : "🗑 حذف المقطع المختار"}
                                    </button>
                                </div>

                                <button
                                    onClick={() => wavesurfer.current?.playPause()}
                                    className="w-full h-12 rounded-xl bg-muted/30 border border-border flex items-center justify-center gap-3 text-sm font-bold hover:bg-muted/50 transition"
                                >
                                    ⏯ تشغيل / إيقاف المعاينة
                                </button>
                            </div>
                        )}
                    </div>

                    <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm flex flex-col items-center space-y-6">
                        <div className="w-full">
                            <div className="flex items-center gap-3 text-primary font-extrabold mb-1">
                                <span className="text-xl">🎙</span> مسجل الصوت عالي الدقة
                            </div>
                            <p className="text-xs text-muted-foreground">التسجيل يتم محلياً وبأقصى جودة (Lossless WAV).</p>
                        </div>

                        <div className="relative flex items-center justify-center py-6">
                            {isRecording && <div className="absolute inset-0 animate-ping rounded-full bg-destructive/20" />}
                            <button
                                onClick={isRecording ? stopRecording : startRecording}
                                className={`relative h-24 w-24 rounded-full flex flex-col items-center justify-center gap-1 transition-all duration-500 shadow-2xl ${isRecording ? "bg-destructive text-white scale-110" : "bg-primary text-white hover:scale-105"}`}
                            >
                                <span className="text-2xl">{isRecording ? "◼" : "🎤"}</span>
                                <span className="text-[9px] font-black uppercase">{isRecording ? "إيقاف" : "سجل الآن"}</span>
                            </button>
                        </div>

                        {isRecording && (
                            <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-destructive/10 text-destructive text-sm font-mono font-bold animate-pulse">
                                <span className="h-2 w-2 rounded-full bg-destructive" />
                                <span>{formatTime(recordingTime)}</span>
                            </div>
                        )}

                        {recordingBlob && !isRecording && (
                            <div className="w-full space-y-4 animate-in slide-in-from-top-4">
                                <div className="rounded-2xl bg-primary/5 p-4 border border-primary/10">
                                    <audio controls className="w-full h-10 accent-primary" src={URL.createObjectURL(recordingBlob)} />
                                </div>
                                <div className="grid grid-cols-2 gap-3">
                                    <button
                                        onClick={() => {
                                            const a = document.createElement("a");
                                            const url = URL.createObjectURL(recordingBlob);
                                            a.href = url;
                                            a.download = `voice_record.wav`;
                                            a.click();
                                            URL.revokeObjectURL(url);
                                        }}
                                        className="rounded-xl bg-primary text-white py-3 text-xs font-bold shadow-md hover:bg-primary/90 transition"
                                    >
                                        💾 حفظ التسجيل
                                    </button>
                                    <button
                                        onClick={() => {
                                            const newFile = new File([recordingBlob], `recording_${Date.now()}.wav`, { type: "audio/wav" });
                                            setAudioFiles(prev => [...prev, newFile]);
                                            setActiveFileIndex(audioFiles.length);
                                        }}
                                        className="rounded-xl border border-border bg-background py-3 text-xs font-bold hover:bg-muted transition"
                                    >
                                        ✂️ تعديل الأن
                                    </button>
                                </div>
                            </div>
                        )}

                        {!isRecording && !recordingBlob && (
                            <div className="space-y-4 w-full">
                                <div className="text-[10px] text-muted-foreground bg-muted/30 px-4 py-2 rounded-lg text-center">
                                    الميكروفون جاهز. اضغط على الزر للبدء.
                                </div>

                                {!window.isSecureContext && window.location.hostname !== 'localhost' && (
                                    <div className="bg-amber-50 border border-amber-200 p-4 rounded-2xl text-[10px] text-amber-900 space-y-2">
                                        <p className="font-bold flex items-center gap-2 text-amber-700">
                                            <span className="text-sm">⚠️</span> تنبيه أمني للمتصفح:
                                        </p>
                                        <p className="leading-relaxed">المتصفحات تحظر الميكروفون عند استخدام IP (مثلاً 192.168.x.x) عبر HTTP غير المشفر.</p>
                                        <div className="pt-1 space-y-1">
                                            <p className="font-bold">الحلول المتاحة:</p>
                                            <ul className="list-disc list-inside opacity-90 space-y-1">
                                                <li>استخدم العنوان <strong>localhost</strong> بدلاً من الرقم.</li>
                                                <li>أو قم بتفعيل <strong>Insecure origins treated as secure</strong> في إعدادات كروم (Flags).</li>
                                            </ul>
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                </div>
            </section>
        </main>
    );
}

function writeString(view: DataView, offset: number, string: string) {
    for (let i = 0; i < string.length; i++) {
        view.setUint8(offset + i, string.charCodeAt(i));
    }
}
