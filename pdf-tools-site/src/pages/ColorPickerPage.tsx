import { useState, useRef } from "react";
// @ts-ignore
import ColorThief from "colorthief";
import { FileDropzone } from "../components/FileDropzone";

export function ColorPickerPage() {
    const [image, setImage] = useState<string | null>(null);
    const [palette, setPalette] = useState<{ rgb: string; hex: string }[]>([]);
    const [dominant, setDominant] = useState<{ rgb: string; hex: string } | null>(null);
    const imgRef = useRef<HTMLImageElement>(null);

    const [toast, setToast] = useState<{ show: boolean; rgb: string; hex: string }>({ show: false, rgb: "", hex: "" });

    function rgbToHex(r: number, g: number, b: number) {
        return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1).toUpperCase();
    }

    function handleImage(file: File) {
        const url = URL.createObjectURL(file);
        setImage(url);
        setPalette([]);
        setDominant(null);
    }

    function extractColors() {
        if (!imgRef.current) return;
        const colorThief = new ColorThief();
        const img = imgRef.current;

        if (img.complete) {
            process(img);
        } else {
            img.onload = () => process(img);
        }

        function process(el: HTMLImageElement) {
            const dom = colorThief.getColor(el);
            const pal = colorThief.getPalette(el, 8);

            setDominant({
                rgb: `rgb(${dom.join(",")})`,
                hex: rgbToHex(dom[0], dom[1], dom[2])
            });

            setPalette(pal.map((c: number[]) => ({
                rgb: `rgb(${c.join(",")})`,
                hex: rgbToHex(c[0], c[1], c[2])
            })));
        }
    }

    async function copyToClipboard(colorObj: { rgb: string; hex: string }) {
        const fullText = `${colorObj.rgb} ${colorObj.hex}`;
        try {
            // Priority 1: Modern API
            if (navigator.clipboard && window.isSecureContext) {
                await navigator.clipboard.writeText(fullText);
            } else {
                // Priority 2: Fallback for older mobile browsers or insecure contexts
                const textArea = document.createElement("textarea");
                textArea.value = fullText;
                textArea.style.position = "fixed";
                textArea.style.left = "-9999px";
                textArea.style.top = "0";
                document.body.appendChild(textArea);
                textArea.focus();
                textArea.select();
                document.execCommand("copy");
                textArea.remove();
            }

            // Show Premium Toast
            setToast({ show: true, rgb: colorObj.rgb, hex: colorObj.hex });
            setTimeout(() => setToast({ show: false, rgb: "", hex: "" }), 3000);
        } catch (err) {
            console.error("Failed to copy", err);
        }
    }

    return (
        <main>
            <section className="gradient-hero border-b">
                <div className="container py-12">
                    <h1 className="text-3xl font-extrabold flex items-center gap-3">
                        مستخرج الألوان ذكي
                        <span className="rounded-full bg-primary/20 px-3 py-1 text-[10px] font-bold text-primary">AI</span>
                    </h1>
                    <p className="mt-3 text-sm text-muted-foreground">ارفع صورة واستخرج لوحة الألوان المستخدمة فيها فوراً.</p>
                </div>
            </section>

            <section className="py-10">
                <div className="container max-w-5xl grid gap-8 lg:grid-cols-2">
                    {/* Upload & Preview */}
                    <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm space-y-6">
                        {!image ? (
                            <FileDropzone
                                accept="image/*"
                                multiple={false}
                                onFiles={(files) => handleImage(files[0])}
                                title="اسحب صورة لاستخراج الألوان"
                                subtitle="PNG, JPG, WebP"
                            />
                        ) : (
                            <div className="space-y-4">
                                <div className="relative aspect-video overflow-hidden rounded-2xl border border-border bg-muted">
                                    <img
                                        ref={imgRef}
                                        src={image}
                                        className="h-full w-full object-contain"
                                        onLoad={extractColors}
                                        crossOrigin="anonymous"
                                    />
                                </div>
                                <button
                                    onClick={() => setImage(null)}
                                    className="w-full rounded-xl bg-card border border-border py-3 text-xs font-bold"
                                >
                                    تغيير الصورة
                                </button>
                            </div>
                        )}
                    </div>

                    {/* Palette */}
                    <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm space-y-8">
                        <div>
                            <h3 className="text-sm font-extrabold mb-4">اللون السائد:</h3>
                            {dominant ? (
                                <div
                                    onClick={() => copyToClipboard(dominant)}
                                    className="group relative h-20 w-full cursor-pointer rounded-2xl border border-border transition-transform hover:scale-[1.02]"
                                    style={{ backgroundColor: dominant.rgb }}
                                >
                                    <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 bg-black/20 text-white text-xs font-bold rounded-2xl">
                                        نسخ الكود
                                    </div>
                                    <div className="absolute bottom-2 left-2 rounded-lg bg-black/40 px-2 py-1 text-[10px] text-white backdrop-blur-md">
                                        {dominant.rgb} | {dominant.hex}
                                    </div>
                                </div>
                            ) : (
                                <div className="h-20 w-full rounded-2xl bg-muted animate-pulse" />
                            )}
                        </div>

                        <div>
                            <h3 className="text-sm font-extrabold mb-4">لوحة الألوان (Palette):</h3>
                            <div className="grid grid-cols-4 gap-3">
                                {palette.length > 0 ? (
                                    palette.map((color, i) => (
                                        <div
                                            key={i}
                                            onClick={() => copyToClipboard(color)}
                                            className="group relative aspect-square cursor-pointer rounded-xl border border-border transition-all hover:scale-105"
                                            style={{ backgroundColor: color.rgb }}
                                        >
                                            <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 bg-black/20 text-white text-[8px] font-bold rounded-xl space-y-1 flex-col">
                                                <span>{color.hex}</span>
                                                <span>نسخ</span>
                                            </div>
                                        </div>
                                    ))
                                ) : (
                                    Array(8).fill(0).map((_, i) => (
                                        <div key={i} className="aspect-square rounded-xl bg-muted animate-pulse" />
                                    ))
                                )}
                            </div>
                        </div>

                        <div className="rounded-2xl bg-primary/5 p-4 text-[10px] text-muted-foreground leading-5">
                            <strong className="text-primary block mb-1">نصيحة:</strong>
                            اضغط على أي لون لنسخ كود الـ RGB الخاص به لاستخدامه في تصاميمك.
                        </div>
                    </div>
                </div>
            </section>

            {/* Premium Toast Notification */}
            <div
                className={`fixed bottom-8 left-1/2 -translate-x-1/2 z-[100] transition-all duration-300 transform ${toast.show ? "translate-y-0 opacity-100" : "translate-y-12 opacity-0 pointer-events-none"
                    }`}
            >
                <div className="flex items-center gap-3 rounded-2xl border border-white/10 bg-card/80 px-6 py-4 shadow-2xl backdrop-blur-xl">
                    <div
                        className="h-4 w-4 rounded-full border border-white/20 shadow-sm"
                        style={{ backgroundColor: toast.rgb }}
                    />
                    <div className="flex flex-col">
                        <span className="text-[10px] font-bold text-muted-foreground">تم النسخ بنجاح!</span>
                        <div className="flex gap-2 text-xs font-extrabold text-foreground">
                            <span>{toast.rgb}</span>
                            <span className="opacity-40">|</span>
                            <span>{toast.hex}</span>
                        </div>
                    </div>
                    <div className="ml-2 flex h-6 w-6 items-center justify-center rounded-full bg-success/20 text-success">
                        <span className="text-[10px]">✓</span>
                    </div>
                </div>
            </div>
        </main>
    );
}
