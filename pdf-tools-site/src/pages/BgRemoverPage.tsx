import React, { useState } from "react";
import { removeBackground } from "@imgly/background-removal";

export function BgRemoverPage() {
    const [image, setImage] = useState<string | null>(null);
    const [result, setResult] = useState<string | null>(null);
    const [processing, setProcessing] = useState(false);
    const [progress, setProgress] = useState(0);

    const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setResult(null);
            const reader = new FileReader();
            reader.onload = (ev) => setImage(ev.target?.result as string);
            reader.readAsDataURL(file);
        }
    };

    const processImage = async () => {
        if (!image) return;
        setProcessing(true);
        setProgress(0);

        try {
            const blob = await removeBackground(image, {
                progress: (_: string, current: number, total: number) => {
                    setProgress(Math.round((current / total) * 100));
                },
            });
            const url = URL.createObjectURL(blob);
            setResult(url);
        } catch (err) {
            console.error(err);
            alert("حدث خطأ أثناء معالجة الصورة.");
        } finally {
            setProcessing(false);
        }
    };

    const downloadResult = () => {
        if (!result) return;
        const link = document.createElement("a");
        link.href = result;
        link.download = "no-bg-image.png";
        link.click();
    };

    return (
        <div className="container py-4 h-[calc(100vh-80px)] flex flex-col overflow-hidden">
            {/* Header - Compact */}
            <div className="gradient-hero rounded-2xl p-4 mb-4 border border-border flex items-center justify-between shadow-sm shrink-0">
                <div>
                    <h1 className="text-xl font-black mb-1">إزالة الخلفية AI</h1>
                    <p className="text-xs text-muted-foreground">تتم المعالجة محلياً داخل متصفحك للحفاظ على الخصوصية.</p>
                </div>
                {processing && (
                    <div className="flex items-center gap-3 bg-primary/10 px-4 py-2 rounded-xl border border-primary/20">
                        <div className="h-3 w-3 border-2 border-primary/30 border-t-primary rounded-full animate-spin"></div>
                        <span className="text-xs font-black">{progress}% جاري المسح...</span>
                    </div>
                )}
            </div>

            {/* Main Content - Flex-1 to fill space */}
            <div className="flex-1 min-h-0 grid gap-4 md:grid-cols-2 mb-4">
                {/* Original View */}
                <div className="flex flex-col min-h-0">
                    <span className="text-[10px] font-bold mb-2 opacity-50 uppercase text-center">الصورة الأصلية</span>
                    <div className="flex-1 bg-card/20 border border-border rounded-2xl flex items-center justify-center p-2 overflow-hidden relative shadow-inner">
                        {image ? (
                            <img src={image} className="max-w-full max-h-full object-contain rounded-lg" />
                        ) : (
                            <div className="text-4xl opacity-10">🖼️</div>
                        )}
                        {!image && (
                            <label className="absolute inset-0 cursor-pointer flex items-center justify-center">
                                <input type="file" hidden accept="image/*" onChange={handleFile} />
                            </label>
                        )}
                    </div>
                </div>

                {/* Result View */}
                <div className="flex flex-col min-h-0">
                    <span className="text-[10px] font-bold mb-2 opacity-50 uppercase text-center">النتيجة النهائية</span>
                    <div className="flex-1 bg-card/40 border border-border rounded-2xl flex items-center justify-center p-2 overflow-hidden relative shadow-inner [background-image:linear-gradient(45deg,#80808008_25%,transparent_25%),linear-gradient(-45deg,#80808008_25%,transparent_25%),linear-gradient(45deg,transparent_75%,#80808008_75%),linear-gradient(-45deg,transparent_75%,#80808008_75%)] [background-size:20px_20px]">
                        {processing ? (
                            <div className="text-center">
                                <div className="text-3xl animate-bounce mb-2">🧠</div>
                                <p className="text-[10px] text-muted-foreground">الذكاء الاصطناعي يحلل الصورة...</p>
                            </div>
                        ) : result ? (
                            <img src={result} className="max-w-full max-h-full object-contain drop-shadow-xl animate-scale-in" />
                        ) : (
                            <div className="text-4xl opacity-10">✨</div>
                        )}
                    </div>
                </div>
            </div>

            {/* Footer Actions - Compact Row */}
            <div className="flex items-center gap-3 shrink-0">
                <label className="cursor-pointer">
                    <input type="file" hidden accept="image/*" onChange={handleFile} />
                    <div className="bg-card border border-border px-6 py-3 rounded-xl font-bold text-xs hover:bg-muted transition flex items-center gap-2">
                        <span>📷</span> {image ? "تغيير الصورة" : "اختيار صورة"}
                    </div>
                </label>

                <button
                    onClick={processImage}
                    disabled={!image || processing}
                    className={`flex-1 rounded-xl py-3 font-black text-xs transition shadow-md flex items-center justify-center gap-2 ${!image || processing ? "bg-muted cursor-not-allowed opacity-50" : "bg-primary text-primary-foreground hover:brightness-110"
                        }`}
                >
                    {processing ? "جاري المعالجة..." : "إزالة الخلفية الآن"}
                </button>

                {result && !processing && (
                    <button
                        onClick={downloadResult}
                        className="bg-green-600 text-white px-8 py-3 rounded-xl font-black text-xs hover:bg-green-700 transition flex items-center gap-2 shadow-lg"
                    >
                        <span>📥</span> تحميل PNG
                    </button>
                )}
            </div>
        </div>
    );
}
