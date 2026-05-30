# Code Magic Trading App

Expo (React Native) trading assistant app with AI-powered quick analysis.

## GitHub Actions Setup (Android APK Build)

### Step 1 — EXPO_TOKEN secret add kara
1. expo.dev var jaun account banva
2. expo.dev → Settings → Access Tokens → "Create Token"
3. GitHub repo → Settings → Secrets → Actions → **New secret**
   - Name: `EXPO_TOKEN`
   - Value: (copied token)

### Step 2 — EAS project register kara (ekdach)
```bash
npm install -g eas-cli
eas login
eas build:configure
```

### Step 3 — Push kara → APK auto build hoil
```bash
git push origin main
```
GitHub Actions tab madhe build disel → APK download karta yeil.

---

## Features (Marathi)

### Screen Monitor Tab 📱
- Phone icon var tap kara → App selector ughadto
- Zerodha, Upstox, Angel One, etc. madun select kara
- **Start Trading** → 20 second candle animation → Floating window ughadto

### Floating Window (White) 🪟
- **Screen Share** — chalu/band kara
- **Mic** — on/off kara
- **Stop** — trading band kara

### Chat Tab 💬
- Commands type kara
- Image picker — chart scan kara
- Always-on Mic 🎤 button
- Topic search bar

### Commands
| Command | Kaam |
|---------|------|
| `123`   | Trading suru kara |
| `2`     | Information save kara |
| `25 2`  | Buy/Sell % analysis |
| `13 6`  | Quick Buy/Sell decision (1 second) |
| `3 2 1` | Trading band kara |
| `000`   | Chat clear kara |

### Knowledge Tab 🧠
- 7 topics pre-filled: Support & Resistance, Trend Analysis, Indicators, Volume, Candlesticks, RSI, MACD
- Topic-wise information save kara + images add kara
- Search kara

### Settings Tab ⚙️
- Default trading candle theme
- Gallery madhun custom theme add kara
- Always-on Mic toggle

---

## Tech Stack
- Expo (React Native) + TypeScript
- Expo Router (file-based routing)
- AsyncStorage (local data)
- EAS Build (GitHub Actions APK)
