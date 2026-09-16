import React, { useState } from 'react';
import { api } from '../api/client';
import { extractPortfolio, formatMoney, safeNum } from '../utils/formatters';

export default function Funds({ portfolio, onFundsUpdated }) {
    const [depositAmount, setDepositAmount] = useState('1000');
    const [withdrawAmount, setWithdrawAmount] = useState('500');
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState(null);

    const { cash: availableCash } = extractPortfolio(portfolio);

    const handleDeposit = async (e) => {
        e.preventDefault();
        setMessage(null);
        const amount = parseFloat(depositAmount);
        if (!amount || amount <= 0) {
            setMessage({ type: 'error', text: 'Enter a positive deposit amount.' });
            return;
        }

        setLoading(true);
        try {
            const res = await api.createDeposit(amount);
            const newBal = (res?.newBalance !== undefined && res?.newBalance !== null && !(res?.newBalance === 0 && res?.remainingBalance > 0))
                ? safeNum(res.newBalance)
                : safeNum(res?.remainingBalance ?? (safeNum(availableCash) + amount));
            setMessage({ type: 'success', text: `Deposit of $${amount.toFixed(2)} completed! New Balance: $${newBal.toFixed(2)}` });
            setDepositAmount('');
            if (onFundsUpdated) onFundsUpdated();
        } catch (err) {
            setMessage({ type: 'error', text: err.message || 'Deposit failed.' });
        } finally {
            setLoading(false);
        }
    };

    const handleWithdraw = async (e) => {
        e.preventDefault();
        setMessage(null);
        const amount = parseFloat(withdrawAmount);
        if (!amount || amount <= 0) {
            setMessage({ type: 'error', text: 'Enter a positive withdrawal amount.' });
            return;
        }

        if (amount > availableCash) {
            setMessage({ type: 'error', text: `Insufficient funds. Available cash is $${safeNum(availableCash).toFixed(2)}` });
            return;
        }

        setLoading(true);
        try {
            const res = await api.createWithdrawal(amount);
            const newBal = (res?.newBalance !== undefined && res?.newBalance !== null && !(res?.newBalance === 0 && res?.remainingBalance > 0))
                ? safeNum(res.newBalance)
                : safeNum(res?.remainingBalance ?? Math.max(0, safeNum(availableCash) - amount));
            setMessage({ type: 'success', text: `Withdrawal of $${amount.toFixed(2)} completed! New Balance: $${newBal.toFixed(2)}` });
            setWithdrawAmount('');
            if (onFundsUpdated) onFundsUpdated();
        } catch (err) {
            setMessage({ type: 'error', text: err.message || 'Withdrawal failed.' });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="funds-view">
            <div className="section-header">
                <h3>Funds Management (Simulated Cash)</h3>
                <span className="text-muted">Simulate paper cash deposits and withdrawals</span>
            </div>

            {message && (
                <div className={`alert ${message.type === 'success' ? 'alert-success' : 'alert-error'}`}>
                    {message.text}
                </div>
            )}

            <div className="funds-grid">
                {/* Deposit Card */}
                <div className="card">
                    <div className="card-header">
                        <h4>Simulated Deposit</h4>
                        <span className="badge badge-success">+ Instant Credit</span>
                    </div>

                    <form onSubmit={handleDeposit} className="p-3">
                        <div className="form-group">
                            <label>Deposit Amount (USD)</label>
                            <input
                                type="number"
                                step="0.01"
                                value={depositAmount}
                                onChange={(e) => setDepositAmount(e.target.value)}
                                placeholder="1000.00"
                                required
                            />
                        </div>

                        <div className="quick-amount-buttons">
                            <button type="button" className="btn-pct" onClick={() => setDepositAmount('500')}>+$500</button>
                            <button type="button" className="btn-pct" onClick={() => setDepositAmount('1000')}>+$1,000</button>
                            <button type="button" className="btn-pct" onClick={() => setDepositAmount('5000')}>+$5,000</button>
                            <button type="button" className="btn-pct" onClick={() => setDepositAmount('10000')}>+$10,000</button>
                        </div>

                        <button type="submit" className="btn btn-primary btn-block btn-lg mt-3" disabled={loading}>
                            {loading ? 'Processing...' : 'Deposit Cash'}
                        </button>
                    </form>
                </div>

                {/* Withdrawal Card */}
                <div className="card">
                    <div className="card-header">
                        <h4>Simulated Withdrawal</h4>
                        <span className="badge badge-warning">Available: ${formatMoney(availableCash)}</span>
                    </div>

                    <form onSubmit={handleWithdraw} className="p-3">
                        <div className="form-group">
                            <label>Withdrawal Amount (USD)</label>
                            <input
                                type="number"
                                step="0.01"
                                value={withdrawAmount}
                                onChange={(e) => setWithdrawAmount(e.target.value)}
                                placeholder="500.00"
                                required
                            />
                        </div>

                        <div className="quick-amount-buttons">
                            <button type="button" className="btn-pct" onClick={() => setWithdrawAmount((safeNum(availableCash) * 0.25).toFixed(2))}>25%</button>
                            <button type="button" className="btn-pct" onClick={() => setWithdrawAmount((safeNum(availableCash) * 0.50).toFixed(2))}>50%</button>
                            <button type="button" className="btn-pct" onClick={() => setWithdrawAmount((safeNum(availableCash) * 0.75).toFixed(2))}>75%</button>
                            <button type="button" className="btn-pct" onClick={() => setWithdrawAmount(safeNum(availableCash).toFixed(2))}>100%</button>
                        </div>

                        <button type="submit" className="btn btn-warning btn-block btn-lg mt-3" disabled={loading}>
                            {loading ? 'Processing...' : 'Withdraw Cash'}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
}

