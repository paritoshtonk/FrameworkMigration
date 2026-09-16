import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { extractTransactions, formatMoney } from '../utils/formatters';

export default function Ledger() {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchLedger = async () => {
            try {
                const data = await api.getTransactions();
                setTransactions(extractTransactions(data || []));
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        };
        fetchLedger();
    }, []);

    const getTypeBadgeClass = (type) => {
        switch (type) {
            case 'DEPOSIT': return 'badge-success';
            case 'WITHDRAWAL': return 'badge-warning';
            case 'BUY': return 'badge-buy';
            case 'SELL': return 'badge-sell';
            default: return 'badge-secondary';
        }
    };

    return (
        <div className="ledger-view">
            <div className="section-header">
                <h3>Financial Audit Ledger</h3>
                <span className="text-muted">Immutable transaction records with balance checkpoints</span>
            </div>

            <div className="card">
                <div className="table-responsive">
                    <table className="table">
                        <thead>
                            <tr>
                                <th>Tx ID</th>
                                <th>Date & Time</th>
                                <th>Type</th>
                                <th>Transaction Amount</th>
                                <th>Cash Balance After</th>
                                <th>Description / Narrative</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="6" className="text-center py-4">Loading ledger transactions...</td>
                                </tr>
                            ) : transactions.length === 0 ? (
                                <tr>
                                    <td colSpan="6" className="text-center text-muted py-4">No transactions recorded yet.</td>
                                </tr>
                            ) : (
                                transactions.map(tx => (
                                    <tr key={tx.transactionId}>
                                        <td><strong>#{tx.transactionId}</strong></td>
                                        <td>{new Date(tx.createdDate).toLocaleString()}</td>
                                        <td>
                                            <span className={`badge ${getTypeBadgeClass(tx.transactionType)}`}>
                                                {tx.transactionType}
                                            </span>
                                        </td>
                                        <td>
                                            <strong>
                                                {tx.transactionType === 'WITHDRAWAL' || tx.transactionType === 'BUY' ? '-' : '+'}
                                                ${formatMoney(tx.amount)}
                                            </strong>
                                        </td>
                                        <td>
                                            <strong>{tx.balanceAfter !== null ? `$${formatMoney(tx.balanceAfter)}` : '—'}</strong>
                                        </td>
                                        <td className="text-muted">{tx.description}</td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}

