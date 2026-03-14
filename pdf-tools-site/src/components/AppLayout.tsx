import { NavLink, Outlet } from "react-router-dom";
import { useTheme } from "../context/ThemeContext";

const nav = [
  { to: "/", label: "الرئيسية" },
  { to: "/pdf", label: "أدوات PDF" },
  { to: "/qr", label: "QR + باركود" },
  { to: "/audio-tools", label: "أدوات الصوت" },
  { to: "/color-picker", label: "الألوان" },
];

export function AppLayout() {
  const { mode, setMode } = useTheme();

  return (
    <div className="min-h-screen bg-background">
      <header className="sticky top-0 z-50 border-b bg-card/70 backdrop-blur">
        <div className="container flex items-center justify-between py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-primary/10 text-primary shadow-sm">
              <span className="text-lg">ST</span>
            </div>
            <div>
              <div className="text-base font-extrabold">أدوات ذكية</div>
              <div className="text-xs text-muted-foreground">مجموعة أدوات تعمل داخل المتصفح</div>
            </div>
          </div>

          <nav className="hidden items-center gap-2 lg:flex">
            {nav.map((i) => (
              <NavLink
                key={i.to}
                to={i.to}
                end={i.to === "/"}
                className={({ isActive }) =>
                  "rounded-xl px-3 py-2 text-sm font-bold transition " +
                  (isActive
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:bg-muted hover:text-foreground")
                }
              >
                {i.label}
              </NavLink>
            ))}
            <a
              href="https://my-profile-ecru.vercel.app/"
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-xl px-3 py-2 text-sm font-bold text-muted-foreground hover:bg-muted hover:text-foreground transition"
            >
              تواصل معي
            </a>
          </nav>

          <div className="flex items-center gap-2">
            <label className="hidden text-xs font-extrabold text-muted-foreground sm:block">المظهر</label>
            <select
              value={mode}
              onChange={(e) => setMode(e.target.value as "light" | "dark" | "system")}
              className="rounded-xl border border-border bg-background px-3 py-2 text-xs font-extrabold shadow-sm outline-none focus:ring-2 focus:ring-primary/40"
            >
              <option value="dark">داكن</option>
              <option value="light">فاتح</option>
              <option value="system">تلقائي</option>
            </select>
          </div>
        </div>

        <div className="container pb-3 lg:hidden">
          <div className="flex flex-wrap gap-2">
            {nav.map((i) => (
              <NavLink
                key={i.to}
                to={i.to}
                end={i.to === "/"}
                className={({ isActive }) =>
                  "rounded-xl px-3 py-2 text-xs font-bold transition " +
                  (isActive
                    ? "bg-primary text-primary-foreground"
                    : "bg-card text-muted-foreground hover:bg-muted hover:text-foreground border border-border")
                }
              >
                {i.label}
              </NavLink>
            ))}
          </div>
        </div>
      </header>

      <Outlet />

      <footer className="border-t bg-card/60">
        <div className="container py-10 text-center">
          <div className="text-sm font-extrabold text-gradient">أدوات ذكية | Smart Tools</div>
          <div className="mt-4 flex justify-center gap-4 text-xs font-bold">
            <a href="https://my-profile-ecru.vercel.app/" target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-primary transition">تواصل معي</a>
            <NavLink to="/" className="text-muted-foreground hover:text-primary transition">الرئيسية</NavLink>
          </div>
          <div className="mt-6 text-[10px] text-muted-foreground opacity-50">© {new Date().getFullYear()} - جميع الحقوق محفوظة</div>
        </div>
      </footer>
    </div>
  );
}
