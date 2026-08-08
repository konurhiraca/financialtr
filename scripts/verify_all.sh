#!/usr/bin/env bash
# Kalite kapısı. Teslim öncesi ve her yeniden üretimden sonra koşturulur.
# Herhangi bir kontrol düşerse çıkış kodu 1.
#
# Bu dosya onur-claude-kit/scripts/scaffold-quality-gate.sh tarafından üretildi.
# Repoya özgü kontrolleri EN ALTA ekle; üstteki evrensel bloğu elle düzenleme —
# jeneratör güncellenince o blok yeniden üretilir.
set -uo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$R"
FAIL=0
hdr() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }
ok()  { echo "  ✓ $1"; }
bad() { echo "  ✗ $1"; FAIL=1; }

# Yalniz REPOYA GIREBILECEK dosyalar taranir: takip edilenler + gitignore'lu
# OLMAYANLAR. Kaynak/ham dosyalar gitignore'luysa zaten dagitilmaz.
files() { git ls-files --cached --others --exclude-standard 2>/dev/null; }

hdr "1. Sır sızıntısı"
python3 - <<'PY'
import os, re, subprocess, sys
PATS = [
    (r"(?i)\b(api[_-]?key|secret[_-]?key|access[_-]?token|bearer)\s*[:=]\s*['\"][A-Za-z0-9_\-]{16,}", "API anahtarı"),
    (r"\bsk-[A-Za-z0-9]{20,}", "OpenAI/Anthropic anahtarı"),
    (r"(?i)\bpassword\s*[:=]\s*['\"][^'\"]{6,}", "açık şifre"),
    (r"-----BEGIN [A-Z ]*PRIVATE KEY-----", "özel anahtar"),
]
SKIP = (".min.js", ".map", ".lock", ".png", ".jpg", ".webp", ".pdf", ".ico")
files = subprocess.run(["git","ls-files","--cached","--others","--exclude-standard"],
                       capture_output=True, text=True).stdout.split("\n")
hits = []
for f in files:
    if not f or f.endswith(SKIP) or not os.path.isfile(f): continue
    try: t = open(f, encoding="utf-8", errors="ignore").read()
    except Exception: continue
    for pat, label in PATS:
        m = re.search(pat, t)
        if m: hits.append((f, label)); break
for f, l in hits[:10]: print(f"  ✗ {f}: {l}")
print(f"  {'✗ ' + str(len(hits)) if hits else '✓ 0'} sır bulgusu")
sys.exit(1 if hits else 0)
PY
[ $? -ne 0 ] && FAIL=1

hdr "2. Kişisel veri deseni"
python3 - <<'PY'
import os, re, subprocess, sys
# Ad deseni: bilinen adlari maskelemek yetmez, BILINMEYENI desen yakalar.
PATS = [
    (r"\b(Mr|Mrs|Ms|Dr|Prof\.\s*Dr)\.\s+[A-ZÇĞİÖŞÜ][a-zçğıöşü]+\s+[A-ZÇĞİÖŞÜ][a-zçğıöşü]+", "kişi adı"),
    (r"\b[1-9][0-9]{10}\b(?![0-9])", "TCKN benzeri 11 hane"),
]
EXT = (".md", ".csv", ".json", ".txt", ".html")
files = subprocess.run(["git","ls-files","--cached","--others","--exclude-standard"],
                       capture_output=True, text=True).stdout.split("\n")
hits = []
for f in files:
    if not f or not f.endswith(EXT) or not os.path.isfile(f): continue
    try: t = open(f, encoding="utf-8", errors="ignore").read()
    except Exception: continue
    for pat, label in PATS:
        for m in re.finditer(pat, t):
            hits.append((f, label, m.group(0)[:40])); break
for f, l, g in hits[:8]: print(f"  ⚠ {f}: {l} → {g!r}")
print(f"  {'⚠ ' + str(len(hits)) + ' bulgu (incele — hepsi hata değil)' if hits else '✓ 0'}")
PY

hdr "3. Placeholder kalıntısı"
n=$(files | grep -E '\.(md|ts|tsx|js|json|html)$' | xargs grep -lE '\[BELİRLENECEK\]|\bTBD\b|\bXXX\b|LOREM IPSUM|FIXME' 2>/dev/null | wc -l | tr -d ' ')
[ "$n" -gt 0 ] && { echo "  ⚠ $n dosyada placeholder/FIXME"; files | grep -E '\.(md|ts|tsx|js|json|html)$' | xargs grep -lE '\[BELİRLENECEK\]|\bTBD\b|\bXXX\b|FIXME' 2>/dev/null | head -5 | sed 's/^/      /'; } || ok "0"

hdr "4. Karışık alfabe (LLM üretimlerinde Kiril/Arapça sızar)"
python3 - <<'PY'
import os, re, subprocess
files = subprocess.run(["git","ls-files","--cached","--others","--exclude-standard"],
                       capture_output=True, text=True).stdout.split("\n")
hits=[]
for f in files:
    if not f or not f.endswith((".md",".txt",".json",".csv")) or not os.path.isfile(f): continue
    try: t=open(f,encoding="utf-8",errors="ignore").read()
    except Exception: continue
    m=re.findall(r"[Ѐ-ӿ؀-ۿ]",t)
    if m: hits.append((f,"".join(sorted(set(m))[:6])))
for f,c in hits[:6]: print(f"  ✗ {f}: {c}")
print(f"  {'✗ ' + str(len(hits)) if hits else '✓ 0'}")
PY

hdr "5. Yanlışlıkla eklenmiş büyük dosya"
big=$(files | while read -r f; do [ -f "$f" ] && s=$(wc -c <"$f" 2>/dev/null || echo 0) && [ "$s" -gt 2000000 ] && echo "$f ($((s/1024))KB)"; done)
[ -n "$big" ] && { echo "  ⚠ 2MB üstü:"; echo "$big" | head -5 | sed 's/^/      /'; } || ok "0"

# ═══ REPOYA ÖZGÜ KONTROLLER — buradan aşağısı senin ═══

hdr "SONUÇ"
[ $FAIL -eq 0 ] && echo "  TÜM KONTROLLER GEÇTİ" || echo "  BAŞARISIZ — yukarıdaki ✗ maddelerini düzelt"
exit $FAIL
