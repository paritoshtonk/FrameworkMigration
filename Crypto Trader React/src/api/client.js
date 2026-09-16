/**
 * Centralized API Client for Crypto Trader React
 * Communicates with the ASP.NET Web API 2 backend at http://localhost:44341/api
 */

import { API_BASE_URL } from '../config';

export const authStorage = {
    getToken: () => localStorage.getItem('crypto_trader_token'),
    setToken: (token) => localStorage.setItem('crypto_trader_token', token),
    clearToken: () => localStorage.removeItem('crypto_trader_token'),
    getUser: () => {
        try {
            return JSON.parse(localStorage.getItem('crypto_trader_user') || 'null');
        } catch {
            return null;
        }
    },
    setUser: (user) => localStorage.setItem('crypto_trader_user', JSON.stringify(user)),
    clearUser: () => localStorage.removeItem('crypto_trader_user'),
    logout: () => {
        authStorage.clearToken();
        authStorage.clearUser();
    }
};

async function request(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...(options.headers || {})
    };

    const token = authStorage.getToken();
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(url, {
        cache: 'no-store',
        ...options,
        headers
    });

    const data = await response.json();

    if (!response.ok || !data.success) {
        const errorMsg = data.message || `Request failed with status ${response.status}`;
        const error = new Error(errorMsg);
        error.status = response.status;
        error.errorCode = data.errorCode;
        throw error;
    }

    return data.data;
}

export const api = {
    // Auth
    login: async (usernameOrEmail, password) => {
        const res = await request('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ usernameOrEmail, password })
        });
        if (res.token) {
            authStorage.setToken(res.token);
            authStorage.setUser(res.user);
        }
        return res;
    },

    register: async (payload) => {
        const res = await request('/auth/register', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
        if (res.token) {
            authStorage.setToken(res.token);
            authStorage.setUser(res.user);
        }
        return res;
    },

    // Market / Cryptocurrencies
    getCryptos: (force = false) => request(`/cryptocurrencies${force ? '?force=true' : ''}`),
    getCrypto: (symbol) => request(`/cryptocurrencies/${symbol}`),
    getCryptoChart: (symbol, timeframe = '24h') => request(`/cryptocurrencies/${symbol}/chart?timeframe=${encodeURIComponent(timeframe)}`),

    // Portfolio
    getPortfolio: () => request('/portfolio'),
    closePosition: (symbol) => request(`/portfolio/positions/${symbol}/close`, { method: 'POST' }),
    downloadPnLReport: async (timeframe = '30d') => {
        const token = authStorage.getToken();
        const res = await fetch(`${API_BASE_URL}/portfolio/reports/pnl-settlement?timeframe=${encodeURIComponent(timeframe)}`, {
            headers: token ? { 'Authorization': `Bearer ${token}` } : {}
        });
        if (!res.ok) {
            throw new Error(`Failed to generate report (${res.status})`);
        }
        const blob = await res.blob();
        const blobUrl = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = blobUrl;
        a.download = `Crypto_PnL_Settlement_Report_${timeframe}_${new Date().toISOString().slice(0, 10)}.pdf`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        setTimeout(() => window.URL.revokeObjectURL(blobUrl), 1000);
    },

    // Orders
    getOrders: (status) => {
        const query = status ? `?status=${encodeURIComponent(status)}` : '';
        return request(`/orders${query}`);
    },
    createOrder: (order) => request('/orders', {
        method: 'POST',
        body: JSON.stringify(order)
    }),
    cancelOrder: (orderId) => request(`/orders/${orderId}`, {
        method: 'DELETE'
    }),

    // Trades
    getTrades: () => request('/trades'),

    // Ledger / Transactions
    getTransactions: () => request('/transactions'),

    // Funds
    getDeposits: () => request('/deposits'),
    createDeposit: (amount, currency = 'USD') => request('/deposits', {
        method: 'POST',
        body: JSON.stringify({ amount: parseFloat(amount), currency })
    }),
    getWithdrawals: () => request('/withdrawals'),
    createWithdrawal: (amount, currency = 'USD') => request('/withdrawals', {
        method: 'POST',
        body: JSON.stringify({ amount: parseFloat(amount), currency })
    }),

    // Profile
    getProfile: () => request('/profile'),
    updateProfile: (profile) => request('/profile', {
        method: 'PUT',
        body: JSON.stringify(profile)
    })
};

export default api;

