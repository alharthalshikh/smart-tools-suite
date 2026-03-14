import { useState } from "react";

interface ShareToolProps {
    title: string;
    description?: string;
}

export function ShareTool({ title, description }: ShareToolProps) {
    const [copied, setCopied] = useState(false);

    const handleShare = async () => {
        const shareData = {
            title: `أداة ذكية: ${title}`,
            text: description || "جرب هذه الأداة الرائعة والمجانية بخصوصية 100%!",
            url: window.location.href,
        };

        if (navigator.share) {
            try {
                await navigator.share(shareData);
            } catch (err) {
                console.log("Error sharing", err);
            }
        } else {
            // Fallback: Copy to clipboard
            try {
                await navigator.clipboard.writeText(window.location.href);
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
            } catch (err) {
                console.error("Failed to copy!", err);
            }
        }
    };

    return (
        <button
            onClick={handleShare}
            className={`flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-bold transition-all ${copied
                    ? "bg-success text-success-foreground"
                    : "bg-primary/10 text-primary hover:bg-primary/20"
                }`}
        >
            <span>{copied ? "✓ تم النسخ" : "📢 مشاركة الأداة"}</span>
        </button>
    );
}
