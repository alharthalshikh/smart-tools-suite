export function AboutPage() {
    return (
        <main className="min-h-screen bg-background">
            <section className="gradient-hero border-b">
                <div className="container py-16 text-center">
                    <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">
                        حول <span className="text-gradient">أدوات ذكية</span>
                    </h1>
                    <p className="mt-4 text-lg text-muted-foreground max-w-2xl mx-auto">
                        قصتنا بدأت من فكرة بسيطة: لماذا نحتاج لرفع ملفاتنا الحساسة لسيرفرات غريبة لكي نقوم بعمليات بسيطة؟
                    </p>
                </div>
            </section>

            <section className="py-20">
                <div className="container max-w-4xl">
                    <div className="grid gap-12">
                        <div className="space-y-4">
                            <h2 className="text-2xl font-bold">لماذا نحن مختلفون؟</h2>
                            <p className="text-muted-foreground leading-relaxed">
                                معظم المواقع التي تقدم أدوات PDF أو معالجة الصور تقوم برفع ملفاتك إلى خوادمها الخاصة. هذا لا يعني فقط بطء في العمل، بل يمثل خطراً على خصوصيتك.
                                في <strong>أدوات ذكية</strong>، قمنا ببناء كل شيء ليعمل <strong>داخل متصفحك مباشرة</strong>.
                            </p>
                        </div>

                        <div className="grid gap-6 sm:grid-cols-2">
                            <div className="rounded-3xl border border-border bg-card p-6 shadow-sm">
                                <div className="text-3xl mb-4">🔒</div>
                                <h3 className="font-bold mb-2">خصوصية 100%</h3>
                                <p className="text-sm text-muted-foreground leading-relaxed">
                                    ملفاتك لا تغادر جهازك أبداً. المعالجة تتم باستخدام قوة معالج جهازك أنت، وليس خوادمنا.
                                </p>
                            </div>
                            <div className="rounded-3xl border border-border bg-card p-6 shadow-sm">
                                <div className="text-3xl mb-4">⚡</div>
                                <h3 className="font-bold mb-2">سرعة فائقة</h3>
                                <p className="text-sm text-muted-foreground leading-relaxed">
                                    لا داعي لانتظار رفع الملفات الكبيرة أو تحميلها مرة أخرى. العمليات فورية وتعتمد على سرعة جهازك.
                                </p>
                            </div>
                            <div className="rounded-3xl border border-border bg-card p-6 shadow-sm">
                                <div className="text-3xl mb-4">💰</div>
                                <h3 className="font-bold mb-2">مجاني بالكامل</h3>
                                <p className="text-sm text-muted-foreground leading-relaxed">
                                    نؤمن بأن الأدوات الأساسية يجب أن تكون متاحة للجميع بدون قيود أو اشتراكات مملة.
                                </p>
                            </div>
                            <div className="rounded-3xl border border-border bg-card p-6 shadow-sm">
                                <div className="text-3xl mb-4">🌍</div>
                                <h3 className="font-bold mb-2">دعم عربي كامل</h3>
                                <p className="text-sm text-muted-foreground leading-relaxed">
                                    واجهة مصممة خصيصاً للمستخدم العربي، مع مراعاة تفاصيل اللغة والتنسيق الصحيح.
                                </p>
                            </div>
                        </div>

                        <div className="rounded-3xl bg-primary/5 border border-primary/10 p-8 text-center space-y-4">
                            <h2 className="text-xl font-bold text-primary">هل أنت مطور؟</h2>
                            <p className="text-sm text-muted-foreground">
                                هذا الموقع مبني باستخدام تقنيات حديثة مثل React و Vite ومكتبات معالجة البيانات المحلية.
                                هدفنا هو إثبات أن الويب الحديث قادر على القيام بمهام معقدة دون الحاجة لتهديد خصوصية المستخدمين.
                            </p>
                        </div>
                    </div>
                </div>
            </section>
        </main>
    );
}
