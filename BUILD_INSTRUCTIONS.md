# Code Magic — Build Instructions

## GitHub वर कसं push करायचं

```bash
git init
git add .
git commit -m "Code Magic Trading App"
git remote add origin https://github.com/YOUR_USERNAME/code-magic.git
git push -u origin main
```

## Codemagic वर कसं build करायचं

1. codemagic.com वर login करा
2. "Add application" → GitHub → code-magic repo select करा
3. Workflow: **android-release** automatically दिसेल
4. "Start new build" दाबा
5. Build complete → **app-release.apk** download करा

## Keystore Details (आधीच setup आहे!)

| Property | Value |
|----------|-------|
| File | keystore/code_magic.jks |
| Alias | code_magic_key |
| Store Password | riderrupali@07 |
| Key Password | riderrupali@07 |
| Valid | 25 वर्षे |

## App Features

- 💬 **Chat** — Marathi/Hindi/English मध्ये बोला
- 📚 **शिकवा Mode** — Marathi मध्ये trading माहिती save करा
- 🔴 **Live Talk** — नेहमी बोलत राहतो
- 📈 **Trading Screen** — OCR ने candle/RSI/trend analyze करतो
- 📖 **Knowledge** — सगळी saved माहिती पाहा/शोधा
- ⚙️ **Settings** — भाषा आणि voice बदला
