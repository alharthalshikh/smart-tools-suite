import { useState } from "react";
import { jsPDF } from "jspdf";

export function DocScannerPage() {
    const [images, setImages] = useState<string[]>([]);
    const [exporting, setExporting] = useState(false);

    const handleCapture = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (ev) => {
                setImages([...images, ev.target?.result as string]);
            };
            reader.readAsDataURL(file);
        }
    };

    const exportToPdf = async () => {
        if (images.length === 0) return;
        setExporting(true);

        try {
            const pdf = new jsPDF("p", "mm", "a4");
            const pageWidth = pdf.internal.pageSize.getWidth();
            const pageHeight = pdf.internal.pageSize.getHeight();

            for (let i = 0; i < images.length; i++) {
                if (i > 0) pdf.addPage();

                // Add image with fit-to-page logic
                pdf.addImage(images[i], "JPEG", 0, 0, pageWidth, pageHeight, undefined, "FAST");
            }

            pdf.save(`document_${Date.now()}.pdf`);
        } catch (err) {
            console.error(err);
            alert("فشل تصدير الملف، يرجى المحاولة مرة أخرى.");
        } finally {
            setExporting(false);
        }
    };

    return (
        <div className="container py-4 h-[calc(100vh-80px)] flex flex-col overflow-hidden">
            {/* Header - Compact */}
            <div className="gradient-hero rounded-2xl p-4 mb-4 border border-border flex items-center justify-between shadow-sm shrink-0">
                <div>
                    <h1 className="text-xl font-black mb-1">ماسح المستندات</h1>
                    <p className="text-xs text-muted-foreground">قم بتصوير الأوراق لتحويلها إلى صور رقمية مقصوصة.</p>
                </div>
                {images.length > 0 && (
                    <button
                        onClick={() => setImages([])}
                        disabled={exporting}
                        className="text-[10px] bg-destructive/10 text-destructive px-3 py-1.5 rounded-lg font-bold hover:bg-destructive/20 transition"
                    >
                        مسح الكل
                    </button>
                )}
            </div>

            {/* Main Content - Scrollable Grid */}
            <div className="flex-1 overflow-y-auto pr-2 custom-scrollbar">
                <div className="grid gap-3 grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
                    {/* Scan Button - Small Version */}
                    <label className="aspect-[3/4] border-2 border-dashed border-border rounded-xl flex flex-col items-center justify-center bg-card/30 cursor-pointer hover:bg-muted hover:border-primary transition group shadow-inner">
                        <input type="file" hidden accept="image/*" capture="environment" onChange={handleCapture} />
                        <div className="text-2xl mb-2 group-hover:scale-110 transition duration-300">📸</div>
                        <span className="text-[10px] font-bold text-muted-foreground">إضافة ورقة</span>
                    </label>

                    {images.map((img, idx) => (
                        <div key={idx} className="relative group aspect-[3/4] rounded-xl overflow-hidden border border-border shadow-md animate-scale-in">
                            <img src={img} className="w-full h-full object-cover" />
                            <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition flex items-center justify-center">
                                <button
                                    onClick={() => setImages(images.filter((_, i) => i !== idx))}
                                    className="h-8 w-8 bg-destructive text-white rounded-full flex items-center justify-center text-sm shadow-xl hover:scale-110 transition"
                                >
                                    ✕
                                </button>
                            </div>
                            <div className="absolute bottom-1 right-1 bg-black/60 text-[8px] text-white px-1.5 py-0.5 rounded-md font-bold">
                                {idx + 1}
                            </div>
                        </div>
                    ))}
                </div>

                {images.length === 0 && (
                    <div className="h-full flex flex-col items-center justify-center opacity-20 pointer-events-none">
                        <div className="text-6xl mb-4">📄</div>
                        <p className="text-sm font-bold">لم يتم مسح أي مستند بعد</p>
                    </div>
                )}
            </div>

            {/* Footer Actions - Modern Overlay */}
            {images.length > 0 && (
                <div className="mt-4 flex justify-center shrink-0">
                    <button
                        onClick={exportToPdf}
                        disabled={exporting}
                        className={`bg-primary text-primary-foreground px-8 py-3 rounded-xl font-black text-xs shadow-xl hover:scale-105 transition active:scale-95 flex items-center gap-2 ${exporting ? 'opacity-50 cursor-not-allowed' : ''}`}
                    >
                        <span>{exporting ? "⏳" : "📄"}</span>
                        {exporting ? "جاري التصدير..." : "تصدير المستندات (PDF)"}
                    </button>
                </div>
            )}
        </div>
    );
}
