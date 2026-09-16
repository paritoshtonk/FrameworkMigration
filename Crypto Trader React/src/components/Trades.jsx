import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { extractTrades, formatMoney, safeNum } from '../utils/formatters';

export default function Trades() {
    const [trades, setTrades] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchTrades = async () => {
            try {
                const data = await api.getTrades();
                setTrades(extractTrades(data || []));
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        };
        fetchTrades();
    }, []);

    return (
        <div className="trades-view">
            <div className="section-header">
                <h3>Executed Trades History</h3>
                <span className="text-muted">Direct executions resulting from filled orders</span>
            </div>

            <div className="card">
                <div className="table-responsive">
                    <table className="table">
                        <thead>
                            <tr>
                                <th>Trade ID</th>
                                <th>Order ID</th>
                                <th>Timestamp</th>
                                <th>Asset</th>
                                <th>Side</th>
                                <th>Executed Quantity</th>
                                <th>Execution Price</th>
                                <th>Total Settlement</th>
                                <th>Realized P/L</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="9" className="text-center py-4">Loading trade history...</td>
                                </tr>
                            ) : trades.length === 0 ? (
                                <tr>
                                    <td colSpan="9" className="text-center text-muted py-4">No executed trades recorded yet.</td>
                                </tr>
                            ) : (
                                trades.map(t => {
                                    const pnl = safeNum(t.realizedPnL);
                                    const isSell = t.side === 'SELL';

                                    return (
                                        <tr key={t.tradeId}>
                                            <td><strong>#{t.tradeId}</strong></td>
                                            <td>#{t.orderId}</td>
                                            <td>{new Date(t.executedDate).toLocaleString()}</td>
                                            <td><strong>{t.symbol}</strong></td>
                                            <td>
                                                <span className={`badge ${t.side === 'BUY' ? 'badge-buy' : 'badge-sell'}`}>
                                                    {t.side}
                                                </span>
                                            </td>
                                            <td>{safeNum(t.quantity).toFixed(8)}</td>
                                            <td>${formatMoney(t.price, 2, 6)}</td>
                                            <td><strong>${formatMoney(t.totalAmount)}</strong></td>
                                            <td>
                                                {isSell ? (
                                                    <strong className={pnl >= 0 ? 'text-success' : 'text-danger'}>
                                                        {pnl >= 0 ? '+' : ''}${formatMoney(pnl)}
                                                    </strong>
                                                ) : (
                                                    <span className="text-muted">—</span>
                                                )}
                                            </td>
                                        </tr>
                                    );
                                })
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}

