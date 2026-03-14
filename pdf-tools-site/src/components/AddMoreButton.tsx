import type { ChangeEvent } from "react";

type Props = {
    onFiles: (files: File[]) => void;
    accept?: string;
    multiple?: boolean;
    label?: string;
};

export function AddMoreButton({ onFiles, accept, multiple = true, label = "+ إضافة المزيد" }: Props) {
    const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
        if (e.target.files) {
            onFiles(Array.from(e.target.files));
        }
    };

    return (
        <label className="flex items-center justify-center gap-2 w-full py-2.5 rounded-xl border-2 border-dashed border-border hover:border-primary/50 hover:bg-primary/5 cursor-pointer transition text-xs font-bold text-muted-foreground hover:text-primary">
            <input
                type="file"
                className="hidden"
                multiple={multiple}
                accept={accept}
                onChange={handleChange}
            />
            <span>{label}</span>
        </label>
    );
}
