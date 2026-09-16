import React, { useState, useEffect, useCallback } from 'react';
import { api, authStorage } from './api/client';
import Navbar from './components/Navbar';
import Login from './components/Login';
import Register from './components/Register';
import Dashboard from './components/Dashboard';
import Trading from './components/Trading';
import Portfolio from './components/Portfolio';
import Orders from './components/Orders';
import Trades from './components/Trades';
import Ledger from './components/Ledger';
import Funds from './components/Funds';
import Profile from './components/Profile';
import { REFRESH_INTERVAL_SECONDS, REFRESH_INTERVAL_MS } from './config';

export default function App() {
    const [user, setUser] = useState(() => authStorage.getUser());
    const [authMode, setAuthMode] = useState('login'); // 'login' or 'register'
    const [activeTab, setActiveTab] = useState('dashboard');
    const [selectedSymbol, setSelectedSymbol] = useState('BTC');
    const [cryptos, setCryptos] = useState([]);
    const [portfolio, setPortfolio] = useState(null);
    const [lastMarketUpdate, setLastMarketUpdate] = useState(null);
    const [isRefreshingMarket, setIsRefreshingMarket] = useState(false);
    const [marketRefreshCountdown, setMarketRefreshCountdown] = useState(REFRESH_INTERVAL_SECONDS);
    const [backendOffline, setBackendOffline] = useState(false);

    const fetchMarketData = useCallback(async (force = false) => {
        setIsRefreshingMarket(true);
        try {
            const data = await api.getCryptos(force);
            setCryptos(data || []);
            setLastMarketUpdate(new Date());
            setBackendOffline(false);
        } catch (err) {
            console.error('Failed to load cryptos:', err);
            setBackendOffline(true);
        } finally {
            setIsRefreshingMarket(false);
            setMarketRefreshCountdown(REFRESH_INTERVAL_SECONDS);
        }
    }, []);

    const fetchPortfolioData = useCallback(async () => {
        if (!user) return;
        try {
            const data = await api.getPortfolio();
            setPortfolio(data);
            setBackendOffline(false);
        } catch (err) {
            console.error('Failed to load portfolio:', err);
        }
    }, [user]);

    const refreshMarket = useCallback(async (force = false) => {
        await fetchMarketData(force);
        if (user) {
            await fetchPortfolioData();
        }
    }, [fetchMarketData, fetchPortfolioData, user]);

    // Initial load
    useEffect(() => {
        fetchMarketData();
    }, [fetchMarketData]);

    // 1-second interval countdown for market refresh
    useEffect(() => {
        const timer = setInterval(() => {
            setMarketRefreshCountdown(prev => {
                if (prev <= 1) {
                    fetchMarketData();
                    if (user) {
                        fetchPortfolioData();
                    }
                    return REFRESH_INTERVAL_SECONDS;
                }
                return prev - 1;
            });
        }, 1000);
        return () => clearInterval(timer);
    }, [fetchMarketData, fetchPortfolioData, user]);

    useEffect(() => {
        if (user) {
            fetchPortfolioData();
            const portTimer = setInterval(fetchPortfolioData, REFRESH_INTERVAL_MS);
            return () => clearInterval(portTimer);
        } else {
            setPortfolio(null);
        }
    }, [user, fetchPortfolioData]);

    const handleTradeCrypto = (symbol) => {
        setSelectedSymbol(symbol || 'BTC');
        setActiveTab('trading');
    };

    const handleLoginSuccess = (loggedInUser) => {
        setUser(loggedInUser);
        setActiveTab('dashboard');
    };

    const handleLogout = () => {
        authStorage.logout();
        setUser(null);
        setPortfolio(null);
        setAuthMode('login');
    };

    if (!user) {
        return (
            <div className="auth-wrapper">
                <div className="auth-container">
                    <div className="auth-brand">
                        <span className="brand-logo">⚡</span>
                        <h1>CryptoTrader</h1>
                        <span className="badge-legacy">LEGACY AS-IS PLATFORM</span>
                    </div>

                    {authMode === 'login' ? (
                        <Login
                            onLoginSuccess={handleLoginSuccess}
                            onSwitchToRegister={() => setAuthMode('register')}
                        />
                    ) : (
                        <Register
                            onRegisterSuccess={handleLoginSuccess}
                            onSwitchToLogin={() => setAuthMode('login')}
                        />
                    )}
                </div>
            </div>
        );
    }

    return (
        <div className="app-container">
            <Navbar
                activeTab={activeTab}
                setActiveTab={setActiveTab}
                user={user}
                portfolio={portfolio}
                onLogout={handleLogout}
            />

            <main className="main-content">
                {activeTab === 'dashboard' && (
                    <Dashboard
                        portfolio={portfolio}
                        cryptos={cryptos}
                        setActiveTab={setActiveTab}
                        lastUpdated={lastMarketUpdate}
                        isRefreshing={isRefreshingMarket}
                        countdown={marketRefreshCountdown}
                        backendOffline={backendOffline}
                        onRefreshMarket={() => refreshMarket(true)}
                        onRefresh={() => refreshMarket(true)}
                        onTradeCrypto={handleTradeCrypto}
                    />
                )}

                {activeTab === 'trading' && (
                    <Trading
                        cryptos={cryptos}
                        portfolio={portfolio}
                        selectedSymbol={selectedSymbol}
                        onSelectSymbol={setSelectedSymbol}
                        lastUpdated={lastMarketUpdate}
                        isRefreshing={isRefreshingMarket}
                        countdown={marketRefreshCountdown}
                        backendOffline={backendOffline}
                        onRefreshMarket={() => refreshMarket(true)}
                        onTradeExecuted={() => {
                            fetchPortfolioData();
                            fetchMarketData(true);
                        }}
                    />
                )}

                {activeTab === 'portfolio' && (
                    <Portfolio
                        portfolio={portfolio}
                        setActiveTab={setActiveTab}
                        lastUpdated={lastMarketUpdate}
                        isRefreshing={isRefreshingMarket}
                        onRefresh={() => refreshMarket(true)}
                        onTradeCrypto={handleTradeCrypto}
                    />
                )}

                {activeTab === 'orders' && (
                    <Orders
                        onOrderUpdated={() => {
                            fetchPortfolioData();
                        }}
                    />
                )}

                {activeTab === 'trades' && (
                    <Trades />
                )}

                {activeTab === 'ledger' && (
                    <Ledger />
                )}

                {activeTab === 'funds' && (
                    <Funds
                        portfolio={portfolio}
                        onFundsUpdated={() => {
                            fetchPortfolioData();
                        }}
                    />
                )}

                {activeTab === 'profile' && (
                    <Profile
                        user={user}
                        onProfileUpdated={(updatedUser) => {
                            setUser(prev => ({ ...prev, ...updatedUser }));
                            authStorage.setUser({ ...user, ...updatedUser });
                        }}
                    />
                )}
            </main>
        </div>
    );
}
