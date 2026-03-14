// Device Info Page for system diagnostics
import { useState, useEffect } from "react";

export function DeviceInfoPage() {
    const [info, setInfo] = useState<Record<string, string>>({});

    useEffect(() => {
        const ua = navigator.userAgent;
        const platform = (navigator as any).platform;
        const language = navigator.language;
        const cores = navigator.hardwareConcurrency?.toString() || "غير معروف";
        const memory = (navigator as any).deviceMemory?.toString() ? `${(navigator as any).deviceMemory} GB` : "غير معروف";

        setInfo({
            "نظام التشغيل / المتصفح": ua,
            "المنصة": platform,
            "اللغة": language,
            "أنوية المعالج": cores,
            "الذاكرة العشوائية (تقريبية)": memory,
            "دقة الشاشة": `${window.screen.width} x ${window.screen.height}`,
            "كوكيز مفعلة": navigator.cookieEnabled ? "نعم" : "لا",
        });
    }, []);

    return (
        <div className="container py-10">
            <div className="gradient-hero rounded-3xl p-8 mb-10 border border-border">
                <h1 className="text-3xl font-extrabold mb-4">معلومات الجهاز</h1>
                <p className="text-muted-foreground text-sm leading-relaxed">
                    تفاصيل تقنية دقيقة عن المتصفح ونظام التشغيل والعتاد الخاص بجهازك الحالي.
                </p>
            </div>

            <div className="max-w-3xl mx-auto">
                <div className="bg-card/50 backdrop-blur-xl rounded-3xl border border-border overflow-hidden shadow-2xl">
                    {Object.entries(info).map(([key, value], idx) => (
                        <div
                            key={key}
                            className={`p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${idx !== Object.entries(info).length - 1 ? "border-b border-border/50" : ""
                                }`}
                        >
                            <span className="text-sm font-extrabold text-muted-foreground">{key}</span>
                            <span className="text-sm font-bold break-all text-left">{value}</span>
                        </div>
                    ))}
                </div>

                <div className="mt-8 p-6 bg-primary/5 rounded-2xl border border-primary/10 flex gap-4">
                    <span className="text-xl">🛡️</span>
                    <p className="text-xs leading-relaxed text-muted-foreground">
                        تنبيه: هذه المعلومات يتم قراءتها محلياً بواسطة المتصفح فقط. لا يتم حفظها أو إرسالها إلى أي مكان.
                    </p>
                </div>
            </div>
        </div>
    );
}
