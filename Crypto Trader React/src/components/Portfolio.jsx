import React, { useState } from 'react';
import { api } from '../api/client';
import { extractPortfolio, formatMoney } from '../utils/formatters';
import { REFRESH_INTERVAL_SECONDS } from '../config';

export default function Portfolio({
    portfolio,
    setActiveTab,
    lastUpdated,
    isRefreshing,
    onRefresh,
    onTradeCrypto
}) {
    const { cash, cryptoVal, total, unrealized, realized, holdings } = extractPortfolio(portfolio);

    // State for Report Download
    const [reportTimeframe, setReportTimeframe] = useState('30d');
    const [isDownloadingReport, setIsDownloadingReport] = useState(false);

    // State for Close Position Modal
    const [closingHolding, setClosingHolding] = useState(null);
    const [isClosing, setIsClosing] = useState(false);
    const [feedback, setFeedback] = useState(null);

    const handleDownloadReport = async () => {
        setIsDownloadingReport(true);
        setFeedback(null);
        try {
            await api.downloadPnLReport(reportTimeframe);
            setFeedback({
                type: 'success',
                message: `PnL & Settlement statement for ${reportTimeframe.toUpperCase()} downloaded successfully.`
            });
        } catch (err) {
            setFeedback({
                type: 'error',
                message: err.message || 'Failed to download report. Ensure the backend server is running.'
            });
        } finally {
            setIsDownloadingReport(false);
        }
    };

    const handleInitiateClose = (holding) => {
        setFeedback(null);
        setClosingHolding(holding);
    };

    const confirmClosePosition = async () => {
        if (!closingHolding) return;
        setIsClosing(true);
        try {
            const result = await api.closePosition(closingHolding.symbol);
            setFeedback({
                type: 'success',
                message: `Successfully closed entire position of ${closingHolding.quantity} ${closingHolding.symbol} at $${formatMoney(result?.executionPrice || closingHolding.currentPrice)}!`
            });
            setClosingHolding(null);
            if (onRefresh) {
                await onRefresh();
            }
        } catch (err) {
            setFeedback({
                type: 'error',
                message: err.message || `Failed to close position for ${closingHolding.symbol}.`
            });
        } finally {
            setIsClosing(false);
        }
    };

    return (
        <div className="portfolio-view">
            {feedback && (
                <div
                    className={`alert alert-${feedback.type === 'success' ? 'success' : 'error'} mb-3`}
                    style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}
                >
                    <span>{feedback.type === 'success' ? '✅' : '⚠️'} {feedback.message}</span>
                    <button
                        className="btn btn-sm btn-outline"
                        style={{ border: 'none', background: 'transparent', color: 'inherit', cursor: 'pointer' }}
                        onClick={() => setFeedback(null)}
                    >
                        ✕
                    </button>
                </div>
            )}

            <div className="section-header">
                <div>
                    <h3>Portfolio Valuation & Cost Basis</h3>
                    {lastUpdated && (
                        <small className="text-muted">Live {REFRESH_INTERVAL_SECONDS}s Polling Synced: {lastUpdated.toLocaleTimeString()}</small>
                    )}
                </div>
                {onRefresh && (
                    <button
                        className="btn btn-sm btn-outline btn-refresh"
                        onClick={onRefresh}
                        disabled={isRefreshing}
                        title="Refresh portfolio valuation with live prices"
                    >
                        <span className={isRefreshing ? 'spin-icon' : ''}>🔄</span> {isRefreshing ? 'Refreshing...' : 'Refresh Valuation'}
                    </button>
                )}
            </div>

            {/* PnL & Settlement PDF Report Download Banner */}
            <div
                className="card p-3 mb-4"
                style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    flexWrap: 'wrap',
                    gap: '1rem',
                    background: 'linear-gradient(135deg, rgba(37, 99, 235, 0.08) 0%, rgba(15, 23, 42, 0.4) 100%)',
                    border: '1px solid rgba(59, 130, 246, 0.25)',
                    borderRadius: '8px'
                }}
            >
                <div style={{ minWidth: '240px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.2rem' }}>
                        <span style={{ fontSize: '1.2rem' }}>📄</span>
                        <strong style={{ fontSize: '1.05rem', color: '#e2e8f0' }}>PnL & Settlement PDF Statement</strong>
                        <span className="badge badge-primary" style={{ fontSize: '0.7rem', padding: '0.15rem 0.4rem' }}>OFFICIAL PDF</span>
                    </div>
                    <small className="text-muted">Generate and download official PDF statement for your selected accounting period.</small>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                        <label style={{ fontSize: '0.85rem', color: '#94a3b8', margin: 0 }}>Period:</label>
                        <select
                            className="form-control form-control-sm"
                            style={{
                                background: '#0d1117',
                                color: '#f0f6fc',
                                border: '1px solid #30363d',
                                padding: '0.35rem 0.6rem',
                                borderRadius: '6px',
                                minWidth: '140px'
                            }}
                            value={reportTimeframe}
                            onChange={(e) => setReportTimeframe(e.target.value)}
                            disabled={isDownloadingReport}
                        >
                            <option value="7d">Last 7 Days</option>
                            <option value="30d">Last 30 Days (Default)</option>
                            <option value="90d">Last 90 Days</option>
                            <option value="ytd">Year to Date (YTD)</option>
                            <option value="all">All Time History</option>
                        </select>
                    </div>

                    <button
                        className="btn btn-sm btn-primary"
                        onClick={handleDownloadReport}
                        disabled={isDownloadingReport}
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.4rem',
                            fontWeight: 600,
                            padding: '0.4rem 0.85rem'
                        }}
                    >
                        {isDownloadingReport ? (
                            <>
                                <span className="spin-icon">⏳</span> Generating PDF...
                            </>
                        ) : (
                            <>
                                <span>📥</span> Download PDF Statement
                            </>
                        )}
                    </button>
                </div>
            </div>

            <div className="metrics-grid">
                <div className="metric-card metric-primary">
                    <div className="metric-label">Total Portfolio Net Worth</div>
                    <div className="metric-value">${formatMoney(total)}</div>
                    <div className="metric-sub">Mark-to-Market Total</div>
                </div>

                <div className="metric-card">
                    <div className="metric-label">Cash Balance</div>
                    <div className="metric-value">${formatMoney(cash)}</div>
                    <div className="metric-sub">{total > 0 ? ((cash / total) * 100).toFixed(1) : 100}% Allocation</div>
                </div>

                <div className="metric-card">
                    <div className="metric-label">Crypto Holdings</div>
                    <div className="metric-value">${formatMoney(cryptoVal)}</div>
                    <div className="metric-sub">{total > 0 ? ((cryptoVal / total) * 100).toFixed(1) : 0}% Allocation</div>
                </div>

                <div className="metric-card">
                    <div className="metric-label">Unrealized P/L</div>
                    <div className={`metric-value ${unrealized >= 0 ? 'text-success' : 'text-danger'}`}>
                        {unrealized >= 0 ? '+' : ''}${formatMoney(unrealized)}
                    </div>
                    <div className="metric-sub">Open Positions</div>
                </div>

                <div className="metric-card">
                    <div className="metric-label">Realized P/L</div>
                    <div className={`metric-value ${realized >= 0 ? 'text-success' : 'text-danger'}`}>
                        {realized >= 0 ? '+' : ''}${formatMoney(realized)}
                    </div>
                    <div className="metric-sub">Lifetime Realized</div>
                </div>
            </div>

            {/* Allocation Bar */}
            {total > 0 && (
                <div className="card mt-4 p-3">
                    <div className="allocation-header">
                        <span><strong>Asset Allocation:</strong></span>
                        <span>Cash: {((cash / total) * 100).toFixed(1)}% | Crypto: {((cryptoVal / total) * 100).toFixed(1)}%</span>
                    </div>
                    <div className="allocation-progress-bar">
                        <div
                            className="bar-cash"
                            style={{ width: `${(cash / total) * 100}%` }}
                            title={`Cash: $${formatMoney(cash)}`}
                        />
                        <div
                            className="bar-crypto"
                            style={{ width: `${(cryptoVal / total) * 100}%` }}
                            title={`Crypto: $${formatMoney(cryptoVal)}`}
                        />
                    </div>
                </div>
            )}

            {/* Holdings Detailed Table */}
            <div className="card mt-4">
                <div className="card-header">
                    <h4>Active Cryptocurrency Holdings ({holdings.length})</h4>
                    <button
                        className="btn btn-sm btn-primary"
                        onClick={() => {
                            if (onTradeCrypto) onTradeCrypto('BTC');
                            else setActiveTab('trading');
                        }}
                    >
                        + New Trade
                    </button>
                </div>

                <div className="table-responsive">
                    <table className="table">
                        <thead>
                            <tr>
                                <th>Asset</th>
                                <th>Holding Quantity</th>
                                <th>Average Buy Price</th>
                                <th>Current Market Price</th>
                                <th>Total Market Value</th>
                                <th>Unrealized P/L ($)</th>
                                <th>Unrealized P/L (%)</th>
                                <th>Portfolio Share</th>
                                <th style={{ minWidth: '150px' }}>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {holdings.length === 0 ? (
                                <tr>
                                    <td colSpan="9" className="text-center text-muted" style={{ padding: '2rem' }}>
                                        No cryptocurrency positions open. Go to the Trading tab to execute a buy order.
                                    </td>
                                </tr>
                            ) : (
                                holdings.map(h => {
                                    const qty = h.quantity;
                                    const avgPrice = h.averageCost;
                                    const curPrice = h.currentPrice;
                                    const curValue = h.currentValue;
                                    const pnl = h.unrealizedProfitLoss;
                                    const pnlPct = h.unrealizedProfitLossPercentage;
                                    const share = total > 0 ? ((curValue / total) * 100).toFixed(1) : 0;

                                    return (
                                        <tr key={h.symbol}>
                                            <td>
                                                <strong>{h.symbol}</strong>
                                                <div className="text-muted small">{h.name}</div>
                                            </td>
                                            <td><strong>{qty.toFixed(8)}</strong></td>
                                            <td>${formatMoney(avgPrice)}</td>
                                            <td>${formatMoney(curPrice, curPrice < 1 ? 4 : 2, curPrice < 1 ? 4 : 2)}</td>
                                            <td><strong>${formatMoney(curValue)}</strong></td>
                                            <td className={pnl >= 0 ? 'text-success' : 'text-danger'}>
                                                {pnl >= 0 ? '+' : ''}${formatMoney(pnl)}
                                            </td>
                                            <td className={pnlPct >= 0 ? 'text-success' : 'text-danger'}>
                                                {pnlPct >= 0 ? '+' : ''}{pnlPct.toFixed(2)}%
                                            </td>
                                            <td>{share}%</td>
                                            <td>
                                                <div style={{ display: 'flex', gap: '0.4rem' }}>
                                                    <button
                                                        className="btn btn-sm btn-outline"
                                                        onClick={() => {
                                                            if (onTradeCrypto) onTradeCrypto(h.symbol);
                                                            else setActiveTab('trading');
                                                        }}
                                                        title="Trade this cryptocurrency"
                                                    >
                                                        Trade
                                                    </button>
                                                    <button
                                                        className="btn btn-sm"
                                                        style={{
                                                            background: 'rgba(239, 68, 68, 0.15)',
                                                            color: '#f87171',
                                                            border: '1px solid rgba(239, 68, 68, 0.3)',
                                                            cursor: 'pointer'
                                                        }}
                                                        onClick={() => handleInitiateClose(h)}
                                                        title={`Close entire position of ${h.quantity} ${h.symbol}`}
                                                    >
                                                        Close Position
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Confirmation Modal for One-Click Close Position */}
            {closingHolding && (
                <div
                    className="modal-backdrop"
                    style={{
                        position: 'fixed',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        backgroundColor: 'rgba(0, 0, 0, 0.75)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        zIndex: 9999,
                        backdropFilter: 'blur(3px)'
                    }}
                >
                    <div
                        className="card p-4"
                        style={{
                            maxWidth: '460px',
                            width: '90%',
                            background: '#161b22',
                            border: '1px solid rgba(239, 68, 68, 0.35)',
                            borderRadius: '10px',
                            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.6)'
                        }}
                    >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                            <span style={{ fontSize: '1.5rem' }}>⚠️</span>
                            <h4 style={{ margin: 0, color: '#f87171' }}>Close Position: {closingHolding.symbol}</h4>
                        </div>

                        <p style={{ color: '#c9d1d9', fontSize: '0.92rem', lineHeight: '1.4', marginBottom: '1rem' }}>
                            Are you sure you want to completely close and liquidate your entire position in <strong>{closingHolding.symbol}</strong> ({closingHolding.name})?
                        </p>

                        <div
                            style={{
                                background: '#0d1117',
                                border: '1px solid #30363d',
                                borderRadius: '8px',
                                padding: '0.85rem 1rem',
                                marginBottom: '1.25rem',
                                fontSize: '0.88rem'
                            }}
                        >
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.4rem' }}>
                                <span className="text-muted">Quantity to Liquidate:</span>
                                <strong>{closingHolding.quantity} {closingHolding.symbol}</strong>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.4rem' }}>
                                <span className="text-muted">Current Execution Price:</span>
                                <span>${formatMoney(closingHolding.currentPrice, closingHolding.currentPrice < 1 ? 4 : 2, closingHolding.currentPrice < 1 ? 4 : 2)}</span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.4rem' }}>
                                <span className="text-muted">Estimated Cash Proceeds:</span>
                                <strong style={{ color: '#58a6ff' }}>${formatMoney(closingHolding.currentValue)}</strong>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                <span className="text-muted">Unrealized P/L to Realize:</span>
                                <span className={closingHolding.unrealizedProfitLoss >= 0 ? 'text-success' : 'text-danger'} style={{ fontWeight: 600 }}>
                                    {closingHolding.unrealizedProfitLoss >= 0 ? '+' : ''}${formatMoney(closingHolding.unrealizedProfitLoss)} ({closingHolding.unrealizedProfitLossPercentage.toFixed(2)}%)
                                </span>
                            </div>
                        </div>

                        <p className="text-muted small" style={{ marginBottom: '1.25rem' }}>
                            💡 <strong>No quantity entry required:</strong> This executes an immediate MARKET SELL order for 100% of your position. The settlement proceeds will be credited instantly to your cash balance.
                        </p>

                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
                            <button
                                className="btn btn-outline"
                                onClick={() => setClosingHolding(null)}
                                disabled={isClosing}
                            >
                                Cancel
                            </button>
                            <button
                                className="btn"
                                style={{
                                    background: '#da3633',
                                    borderColor: '#f85149',
                                    color: '#ffffff',
                                    fontWeight: 600
                                }}
                                onClick={confirmClosePosition}
                                disabled={isClosing}
                            >
                                {isClosing ? 'Liquidating Position...' : 'Confirm & Close Position'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
