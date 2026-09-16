import React, { useState } from 'react';
import { api } from '../api/client';

export default function Login({ onLoginSuccess, onSwitchToRegister, sessionExpiredMessage }) {
    const [usernameOrEmail, setUsernameOrEmail] = useState('demo_trader');
    const [password, setPassword] = useState('Password123!');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            const res = await api.login(usernameOrEmail, password);
            onLoginSuccess(res.user);
        } catch (err) {
            setError(err.message || 'Login failed. Check credentials.');
        } finally {
            setLoading(false);
        }
    };

    const handleQuickLogin = (demoUser) => {
        setUsernameOrEmail(demoUser);
        setPassword('Password123!');
    };

    return (
        <div className="auth-card">
            <div className="auth-header">
                <h2>Welcome to CryptoTrader</h2>
                <p>Sign in to your simulated paper-trading account</p>
            </div>

            {sessionExpiredMessage && (
                <div className="alert alert-error" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                    <span>⚠️</span>
                    <span>{sessionExpiredMessage}</span>
                </div>
            )}
            {error && <div className="alert alert-error">{error}</div>}

            <form onSubmit={handleSubmit} className="auth-form">
                <div className="form-group">
                    <label>Username or Email</label>
                    <input
                        type="text"
                        value={usernameOrEmail}
                        onChange={(e) => setUsernameOrEmail(e.target.value)}
                        placeholder="Enter username or email"
                        required
                    />
                </div>

                <div className="form-group">
                    <label>Password</label>
                    <input
                        type="password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="Enter password"
                        required
                    />
                </div>

                <button type="submit" className="btn btn-primary btn-block" disabled={loading}>
                    {loading ? 'Authenticating...' : 'Sign In'}
                </button>
            </form>

            <div className="demo-accounts-box">
                <div className="demo-title">Quick Demo Login:</div>
                <div className="demo-buttons">
                    <button type="button" className="btn-demo" onClick={() => handleQuickLogin('demo_trader')}>
                        demo_trader ($10,000)
                    </button>
                    <button type="button" className="btn-demo" onClick={() => handleQuickLogin('trader1')}>
                        trader1 (BTC/ETH)
                    </button>
                    <button type="button" className="btn-demo" onClick={() => handleQuickLogin('trader2')}>
                        trader2 (SOL/ADA)
                    </button>
                </div>
            </div>

            <div className="auth-footer">
                Don't have an account?{' '}
                <button type="button" className="link-btn" onClick={onSwitchToRegister}>
                    Register New Account
                </button>
            </div>
        </div>
    );
}

