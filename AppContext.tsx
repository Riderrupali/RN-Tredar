import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";

export interface KnowledgeEntry {
  id: string;
  text: string;
  imageUri?: string;
  timestamp: number;
}

export interface KnowledgeTopic {
  id: string;
  name: string;
  icon: string;
  entries: KnowledgeEntry[];
  preloaded: boolean;
}

export interface AppItem {
  id: string;
  name: string;
  icon: string;
}

export interface ChatMessage {
  id: string;
  text: string;
  isUser: boolean;
  type: "text" | "command" | "analysis" | "image";
  imageUri?: string;
  timestamp: number;
}

interface AppContextType {
  tradingActive: boolean;
  setTradingActive: (v: boolean) => void;
  micActive: boolean;
  setMicActive: (v: boolean) => void;
  alwaysOnMicActive: boolean;
  setAlwaysOnMicActive: (v: boolean) => void;
  screenShareActive: boolean;
  setScreenShareActive: (v: boolean) => void;
  selectedApp: AppItem | null;
  setSelectedApp: (app: AppItem | null) => void;
  installedApps: AppItem[];
  addApp: (name: string) => void;
  removeApp: (id: string) => void;
  knowledgeTopics: KnowledgeTopic[];
  addKnowledgeEntry: (topicId: string, text: string, imageUri?: string) => void;
  deleteKnowledgeEntry: (topicId: string, entryId: string) => void;
  messages: ChatMessage[];
  addMessage: (msg: Omit<ChatMessage, "id" | "timestamp">) => void;
  clearMessages: () => void;
  customThemeBg: string | null;
  setCustomThemeBg: (uri: string | null) => void;
  isLoadingTrading: boolean;
  setIsLoadingTrading: (v: boolean) => void;
  buyPercent: number;
  sellPercent: number;
  setBuyPercent: (v: number) => void;
  setSellPercent: (v: number) => void;
  currentPrice: string;
  setCurrentPrice: (v: string) => void;
  analysisRules: string[];
  addAnalysisRule: (rule: string) => void;
  activeTabIndex: number;
  setActiveTabIndex: (v: number) => void;
}

const DEFAULT_TOPICS: KnowledgeTopic[] = [
  {
    id: "support_resistance",
    name: "Support & Resistance",
    icon: "trending-up",
    preloaded: true,
    entries: [
      {
        id: "sr1",
        text: "Support level: Candel ithun bounce karte, price ya level var yeto tewha candel varti jate. Resistance: Price ya level var yeto tewha candel khali yete.",
        timestamp: Date.now(),
      },
      {
        id: "sr2",
        text: "Strong support/resistance: Jya level la price 3+ wela bounce kela asel, to level strong asto. Break kelyavar direction change hotat.",
        timestamp: Date.now(),
      },
    ],
  },
  {
    id: "trend_analysis",
    name: "Trend Analysis",
    icon: "activity",
    preloaded: true,
    entries: [
      {
        id: "ta1",
        text: "Uptrend: Higher highs aani higher lows. Khredari (buy) karayla yogya. Downtrend: Lower highs aani lower lows. Vikrayi (sell) karayla yogya.",
        timestamp: Date.now(),
      },
      {
        id: "ta2",
        text: "Sideways trend: Price eka range madhe phirate. Support var buy kara, resistance var sell kara.",
        timestamp: Date.now(),
      },
    ],
  },
  {
    id: "indicators",
    name: "Use of Indicators",
    icon: "bar-chart-2",
    preloaded: true,
    entries: [
      {
        id: "ind1",
        text: "Moving Average (MA): Price cha average. Price MA chya varti asel tar bullish (buy), khali asel tar bearish (sell). 20 MA, 50 MA, 200 MA.",
        timestamp: Date.now(),
      },
      {
        id: "ind2",
        text: "Bollinger Bands: Varil band resistance, khali band support. Band mite mhanje breakout yenar.",
        timestamp: Date.now(),
      },
    ],
  },
  {
    id: "volume",
    name: "Volume",
    icon: "layers",
    preloaded: true,
    entries: [
      {
        id: "vol1",
        text: "Volume = Kiti shares vikle/kinde tya timeframe madhe. High volume sath price move = strong signal. Low volume sath price move = weak signal.",
        timestamp: Date.now(),
      },
      {
        id: "vol2",
        text: "Jyach site var buy/sell percent kami asle, tya site ne candel run honyache chance jast astat. Volume kami = volatility jast.",
        timestamp: Date.now(),
      },
    ],
  },
  {
    id: "candlesticks",
    name: "Types of Candlesticks",
    icon: "git-commit",
    preloaded: true,
    entries: [
      {
        id: "cs1",
        text: "Candel kashi run hote: Open price pasun close price la jato. Jor (body) cha range = open to close. Wicks = high aani low points.",
        timestamp: Date.now(),
      },
      {
        id: "cs2",
        text: "Green candel: Close > Open = Bullish (buyers stronger). Red candel: Close < Open = Bearish (sellers stronger). Body jitki moti, signal titka strong.",
        timestamp: Date.now(),
      },
      {
        id: "cs3",
        text: "Doji: Open aani close sama = market confusion, reversal yenar. Hammer: Khali wick moti = buy signal. Shooting Star: Varil wick moti = sell signal.",
        timestamp: Date.now(),
      },
      {
        id: "cs4",
        text: "Candel madhil antar: Body = emotional move. Wick = rejected price levels. Moti wick = strong rejection. Candel madhe gap asel tar news/event effect asto.",
        timestamp: Date.now(),
      },
      {
        id: "cs5",
        text: "Buy/Sell effect on candel: Jast buy orders = green candel varti jate. Jast sell orders = red candel khali yete. By/sell percent = market sentiment dakhavte.",
        timestamp: Date.now(),
      },
    ],
  },
  {
    id: "rsi",
    name: "RSI (Relative Strength Index)",
    icon: "percent",
    preloaded: true,
    entries: [
      {
        id: "rsi1",
        text: "RSI 0-100 madhe asto. RSI > 70 = Overbought (sell signal, candel khali yeu shakto). RSI < 30 = Oversold (buy signal, candel varti jeu shakto). RSI 50 cross = trend change.",
        timestamp: Date.now(),
      },
      {
        id: "rsi2",
        text: "RSI divergence: Price varti jate pan RSI khali yete = Bearish divergence (sell). Price khali yete pan RSI varti jate = Bullish divergence (buy).",
        timestamp: Date.now(),
      },
    ],
  },
  {
    id: "macd",
    name: "MACD",
    icon: "cpu",
    preloaded: true,
    entries: [
      {
        id: "macd1",
        text: "MACD = 12 EMA - 26 EMA. Signal line = 9 EMA of MACD. MACD line signal line cha varti gela = Buy. MACD line signal line cha khali gela = Sell.",
        timestamp: Date.now(),
      },
      {
        id: "macd2",
        text: "MACD histogram: Varti = bullish momentum. Khali = bearish momentum. Zero line cross = strong signal. MACD + RSI combination = more accurate signal.",
        timestamp: Date.now(),
      },
    ],
  },
];

const DEFAULT_APPS: AppItem[] = [
  { id: "zerodha", name: "Zerodha Kite", icon: "trending-up" },
  { id: "upstox", name: "Upstox", icon: "bar-chart-2" },
  { id: "angelone", name: "Angel One", icon: "activity" },
  { id: "groww", name: "Groww", icon: "dollar-sign" },
  { id: "5paisa", name: "5paisa", icon: "percent" },
];

const AppContext = createContext<AppContextType | undefined>(undefined);

const STORAGE_KEYS = {
  TOPICS: "cm_topics",
  APPS: "cm_apps",
  MESSAGES: "cm_messages",
  THEME_BG: "cm_theme_bg",
  RULES: "cm_rules",
  BUY_PCT: "cm_buy_pct",
  SELL_PCT: "cm_sell_pct",
};

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [tradingActive, setTradingActive] = useState(false);
  const [micActive, setMicActive] = useState(false);
  const [alwaysOnMicActive, setAlwaysOnMicActive] = useState(false);
  const [screenShareActive, setScreenShareActive] = useState(false);
  const [selectedApp, setSelectedApp] = useState<AppItem | null>(null);
  const [installedApps, setInstalledApps] =
    useState<AppItem[]>(DEFAULT_APPS);
  const [knowledgeTopics, setKnowledgeTopics] =
    useState<KnowledgeTopic[]>(DEFAULT_TOPICS);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [customThemeBg, setCustomThemeBgState] = useState<string | null>(null);
  const [isLoadingTrading, setIsLoadingTrading] = useState(false);
  const [buyPercent, setBuyPercentState] = useState(45);
  const [sellPercent, setSellPercentState] = useState(55);
  const [currentPrice, setCurrentPriceState] = useState("");
  const [analysisRules, setAnalysisRules] = useState<string[]>([]);
  const [activeTabIndex, setActiveTabIndex] = useState(0);

  useEffect(() => {
    (async () => {
      try {
        const [topicsRaw, appsRaw, msgsRaw, bgRaw, rulesRaw, bpRaw, spRaw] =
          await Promise.all([
            AsyncStorage.getItem(STORAGE_KEYS.TOPICS),
            AsyncStorage.getItem(STORAGE_KEYS.APPS),
            AsyncStorage.getItem(STORAGE_KEYS.MESSAGES),
            AsyncStorage.getItem(STORAGE_KEYS.THEME_BG),
            AsyncStorage.getItem(STORAGE_KEYS.RULES),
            AsyncStorage.getItem(STORAGE_KEYS.BUY_PCT),
            AsyncStorage.getItem(STORAGE_KEYS.SELL_PCT),
          ]);
        if (topicsRaw) setKnowledgeTopics(JSON.parse(topicsRaw));
        if (appsRaw) setInstalledApps(JSON.parse(appsRaw));
        if (msgsRaw) setMessages(JSON.parse(msgsRaw));
        if (bgRaw) setCustomThemeBgState(bgRaw);
        if (rulesRaw) setAnalysisRules(JSON.parse(rulesRaw));
        if (bpRaw) setBuyPercentState(Number(bpRaw));
        if (spRaw) setSellPercentState(Number(spRaw));
      } catch {
        // ignore
      }
    })();
  }, []);

  const addApp = useCallback(
    (name: string) => {
      const id =
        Date.now().toString() + Math.random().toString(36).substr(2, 5);
      const newApp: AppItem = { id, name, icon: "monitor" };
      const updated = [...installedApps, newApp];
      setInstalledApps(updated);
      AsyncStorage.setItem(STORAGE_KEYS.APPS, JSON.stringify(updated));
    },
    [installedApps]
  );

  const removeApp = useCallback(
    (id: string) => {
      const updated = installedApps.filter((a) => a.id !== id);
      setInstalledApps(updated);
      AsyncStorage.setItem(STORAGE_KEYS.APPS, JSON.stringify(updated));
    },
    [installedApps]
  );

  const addKnowledgeEntry = useCallback(
    (topicId: string, text: string, imageUri?: string) => {
      setKnowledgeTopics((prev) => {
        const updated = prev.map((t) => {
          if (t.id !== topicId) return t;
          const entry: KnowledgeEntry = {
            id:
              Date.now().toString() + Math.random().toString(36).substr(2, 5),
            text,
            imageUri,
            timestamp: Date.now(),
          };
          return { ...t, entries: [entry, ...t.entries] };
        });
        AsyncStorage.setItem(STORAGE_KEYS.TOPICS, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  const deleteKnowledgeEntry = useCallback(
    (topicId: string, entryId: string) => {
      setKnowledgeTopics((prev) => {
        const updated = prev.map((t) => {
          if (t.id !== topicId) return t;
          return { ...t, entries: t.entries.filter((e) => e.id !== entryId) };
        });
        AsyncStorage.setItem(STORAGE_KEYS.TOPICS, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  const addMessage = useCallback(
    (msg: Omit<ChatMessage, "id" | "timestamp">) => {
      const newMsg: ChatMessage = {
        ...msg,
        id: Date.now().toString() + Math.random().toString(36).substr(2, 5),
        timestamp: Date.now(),
      };
      setMessages((prev) => {
        const updated = [newMsg, ...prev];
        AsyncStorage.setItem(
          STORAGE_KEYS.MESSAGES,
          JSON.stringify(updated.slice(0, 200))
        );
        return updated;
      });
    },
    []
  );

  const clearMessages = useCallback(() => {
    setMessages([]);
    AsyncStorage.removeItem(STORAGE_KEYS.MESSAGES);
  }, []);

  const setCustomThemeBg = useCallback((uri: string | null) => {
    setCustomThemeBgState(uri);
    if (uri) AsyncStorage.setItem(STORAGE_KEYS.THEME_BG, uri);
    else AsyncStorage.removeItem(STORAGE_KEYS.THEME_BG);
  }, []);

  const setBuyPercent = useCallback((v: number) => {
    setBuyPercentState(v);
    AsyncStorage.setItem(STORAGE_KEYS.BUY_PCT, String(v));
  }, []);

  const setSellPercent = useCallback((v: number) => {
    setSellPercentState(v);
    AsyncStorage.setItem(STORAGE_KEYS.SELL_PCT, String(v));
  }, []);

  const setCurrentPrice = useCallback((v: string) => {
    setCurrentPriceState(v);
  }, []);

  const addAnalysisRule = useCallback(
    (rule: string) => {
      setAnalysisRules((prev) => {
        const updated = [rule, ...prev].slice(0, 50);
        AsyncStorage.setItem(STORAGE_KEYS.RULES, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  return (
    <AppContext.Provider
      value={{
        tradingActive,
        setTradingActive,
        micActive,
        setMicActive,
        alwaysOnMicActive,
        setAlwaysOnMicActive,
        screenShareActive,
        setScreenShareActive,
        selectedApp,
        setSelectedApp,
        installedApps,
        addApp,
        removeApp,
        knowledgeTopics,
        addKnowledgeEntry,
        deleteKnowledgeEntry,
        messages,
        addMessage,
        clearMessages,
        customThemeBg,
        setCustomThemeBg,
        isLoadingTrading,
        setIsLoadingTrading,
        buyPercent,
        sellPercent,
        setBuyPercent,
        setSellPercent,
        currentPrice,
        setCurrentPrice,
        analysisRules,
        addAnalysisRule,
        activeTabIndex,
        setActiveTabIndex,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
}
