/**
 * Numerical and currency formatting utilities with fail-safe zero fallbacks
 * to prevent NaN errors in the UI.
 */

export function safeNum(val, fallback = 0) {
    if (val === null || val === undefined) return fallback;
    const n = typeof val === 'number' ? val : parseFloat(val);
    return isNaN(n) ? fallback : n;
}

export function formatMoney(val, minDec = 2, maxDec = undefined) {
    const n = safeNum(val);
    let min = typeof minDec === 'number' && !isNaN(minDec) ? Math.max(0, Math.min(20, Math.floor(minDec))) : 2;
    let max = typeof maxDec === 'number' && !isNaN(maxDec) ? Math.max(0, Math.min(20, Math.floor(maxDec))) : Math.max(min, 2);
    if (max < min) {
        max = min;
    }
    try {
        return n.toLocaleString('en-US', { minimumFractionDigits: min, maximumFractionDigits: max });
    } catch {
        return n.toFixed(Math.min(min, 8));
    }
}

export function formatCrypto(val, decimals = 8) {
    const n = safeNum(val);
    return n.toFixed(decimals);
}

export function extractPortfolio(portfolio) {
    const s = portfolio?.summary || portfolio || {};
    const cash = safeNum(s.cashBalance ?? portfolio?.cashBalance);
    const cryptoVal = safeNum(s.holdingsMarketValue ?? s.cryptoHoldingsValue ?? portfolio?.cryptoHoldingsValue ?? portfolio?.holdingsMarketValue);
    const total = safeNum(s.totalPortfolioValue ?? portfolio?.totalPortfolioValue ?? (cash + cryptoVal));
    const unrealized = safeNum(s.unrealizedProfitLoss ?? s.totalUnrealizedPnL ?? portfolio?.totalUnrealizedPnL ?? portfolio?.unrealizedProfitLoss);
    const realized = safeNum(s.realizedProfitLoss ?? s.totalRealizedPnL ?? portfolio?.totalRealizedPnL ?? portfolio?.realizedProfitLoss);

    const holdings = (portfolio?.holdings || []).map(h => {
        const qty = safeNum(h.quantity);
        const avg = safeNum(h.averageCost ?? h.averageBuyPrice);
        const cur = safeNum(h.currentPrice);
        const val = safeNum(h.currentValue ?? (qty * cur));
        const pnl = safeNum(h.unrealizedProfitLoss ?? h.unrealizedPnL ?? (val - (qty * avg)));
        const pnlPct = safeNum(h.unrealizedProfitLossPercentage ?? h.unrealizedPnLPercentage ?? (avg > 0 ? ((cur - avg) / avg) * 100 : 0));

        return {
            ...h,
            quantity: qty,
            averageCost: avg,
            averageBuyPrice: avg,
            currentPrice: cur,
            currentValue: val,
            unrealizedProfitLoss: pnl,
            unrealizedPnL: pnl,
            unrealizedProfitLossPercentage: pnlPct,
            unrealizedPnLPercentage: pnlPct
        };
    });

    return { cash, cryptoVal, total, unrealized, realized, holdings };
}

export function extractTrades(trades) {
    return (trades || []).map(t => {
        const qty = safeNum(t.quantity);
        const price = safeNum(t.executionPrice ?? t.price);
        const total = safeNum(t.totalValue ?? t.totalAmount ?? (qty * price));
        const pnl = safeNum(t.realizedProfitLoss ?? t.realizedPnL);
        return {
            ...t,
            quantity: qty,
            executionPrice: price,
            price: price,
            totalValue: total,
            totalAmount: total,
            realizedProfitLoss: pnl,
            realizedPnL: pnl
        };
    });
}

export function extractTransactions(transactions) {
    return (transactions || []).map(tx => {
        const amount = safeNum(tx.amount);
        const balanceAfter = tx.balanceAfter !== undefined && tx.balanceAfter !== null ? safeNum(tx.balanceAfter) : null;
        const description = tx.description || `${tx.transactionType} transaction ${tx.referenceId ? `ref #${tx.referenceId}` : tx.status || ''}`.trim();
        return {
            ...tx,
            amount,
            balanceAfter,
            description
        };
    });
}

export function extractOrders(orders) {
    return (orders || []).map(o => {
        const qty = safeNum(o.quantity);
        const price = safeNum(o.price ?? o.executedPrice);
        const total = safeNum(o.totalValue ?? o.totalAmount ?? (qty * price));
        return {
            ...o,
            quantity: qty,
            price: price,
            totalValue: total,
            totalAmount: total
        };
    });
}

export function extractProfile(profileData, fallbackUser = {}) {
    if (!profileData && !fallbackUser) return null;
    const p = profileData?.data || profileData || {};
    const u = p.user || p || fallbackUser || {};
    const acc = p.account || p || {};

    const userId = safeNum(u.userId ?? p.userId ?? fallbackUser?.userId);
    const username = u.username || p.username || fallbackUser?.username || '';
    const firstName = u.firstName ?? p.firstName ?? fallbackUser?.firstName ?? '';
    const lastName = u.lastName ?? p.lastName ?? fallbackUser?.lastName ?? '';
    const email = u.email ?? p.email ?? fallbackUser?.email ?? '';
    const accountId = safeNum(acc.accountId ?? p.accountId ?? userId);
    const cashBalance = safeNum(acc.balance ?? acc.availableBalance ?? p.cashBalance ?? fallbackUser?.cashBalance);
    const currency = acc.currency || p.currency || fallbackUser?.currency || 'USD';
    const createdDate = u.createdDate || p.createdDate || fallbackUser?.createdDate;
    const lastLoginDate = u.lastLoginDate || p.lastLoginDate || fallbackUser?.lastLoginDate;

    return {
        userId,
        username,
        firstName,
        lastName,
        email,
        accountId,
        cashBalance,
        currency,
        createdDate,
        lastLoginDate,
        user: {
            userId,
            username,
            firstName,
            lastName,
            email,
            createdDate,
            lastLoginDate
        },
        account: {
            accountId,
            userId,
            currency,
            balance: cashBalance,
            availableBalance: cashBalance
        }
    };
}

