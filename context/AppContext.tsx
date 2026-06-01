import React, { createContext, useContext, useState } from "react";

type App = {
  id: string;
  name: string;
  icon?: string;
};

type AppContextType = {
  installedApps: App[];
  addApp: (name: string) => void;
  removeApp: (id: string) => void;
  selectedApp: App | null;
  setSelectedApp: (app: App | null) => void;
  tradingActive: boolean;
  setTradingActive: (v: boolean) => void;
  screenShareActive: boolean;
  setScreenShareActive: (v: boolean) => void;
  isLoadingTrading: boolean;
  setIsLoadingTrading: (v: boolean) => void;
  activeTabIndex: number;
  setActiveTabIndex: (v: number) => void;
};

const AppContext = createContext<AppContextType>({
  installedApps: [],
  addApp: () => {},
  removeApp: () => {},
  selectedApp: null,
  setSelectedApp: () => {},
  tradingActive: false,
  setTradingActive: () => {},
  screenShareActive: false,
  setScreenShareActive: () => {},
  isLoadingTrading: false,
  setIsLoadingTrading: () => {},
  activeTabIndex: 0,
  setActiveTabIndex: () => {},
});

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [installedApps, setInstalledApps] = useState<App[]>([
    { id: "1", name: "Zerodha Kite", icon: "trending-up" },
    { id: "2", name: "Groww", icon: "bar-chart-2" },
    { id: "3", name: "Upstox", icon: "activity" },
  ]);
  const [selectedApp, setSelectedApp] = useState<App | null>(null);
  const [tradingActive, setTradingActive] = useState(false);
  const [screenShareActive, setScreenShareActive] = useState(false);
  const [isLoadingTrading, setIsLoadingTrading] = useState(false);
  const [activeTabIndex, setActiveTabIndex] = useState(0);

  const addApp = (name: string) => {
    const newApp: App = { id: Date.now().toString(), name };
    setInstalledApps((prev) => [...prev, newApp]);
  };

  const removeApp = (id: string) => {
    setInstalledApps((prev) => prev.filter((a) => a.id !== id));
  };

  return (
    <AppContext.Provider
      value={{
        installedApps,
        addApp,
        removeApp,
        selectedApp,
        setSelectedApp,
        tradingActive,
        setTradingActive,
        screenShareActive,
        setScreenShareActive,
        isLoadingTrading,
        setIsLoadingTrading,
        activeTabIndex,
        setActiveTabIndex,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  return useContext(AppContext);
}
