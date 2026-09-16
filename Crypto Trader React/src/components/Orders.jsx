import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../api/client';
import { extractOrders, formatMoney, safeNum } from '../utils/formatters';

export default function Orders({ onOrderUpdated }) {
    const [orders, setOrders] = useState([]);
    const [filterStatus, setFilterStatus] = useState('');
    const [loading, setLoading] = useState(true);
    const [actionMessage, setActionMessage] = useState(null);

    const loadOrders = useCallback(async () => {
        setLoading(true);
        try {
            const data = await api.getOrders(filterStatus || null);
            setOrders(extractOrders(data || []));
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    }, [filterStatus]);

    useEffect(() => {
        loadOrders();
    }, [loadOrders]);

    const handleCancel = async (orderId) => {
        setActionMessage(null);
        try {
            await api.cancelOrder(orderId);
            setActionMessage({ type: 'success', text: `Order #${orderId} cancelled successfully.` });
            loadOrders();
            if (onOrderUpdated) onOrderUpdated();
        } catch (err) {
            setActionMessage({ type: 'error', text: err.message || 'Failed to cancel order.' });
        }
    };

    return (
        <div className="orders-view">
            <div className="section-header">
                <h3>Order Blotter & History</h3>
                <div className="filter-group">
                    <button
                        className={`filter-btn ${filterStatus === '' ? 'active' : ''}`}
                        onClick={() => setFilterStatus('')}
                    >
                        All Orders
                    </button>
                    <button
                        className={`filter-btn ${filterStatus === 'PENDING' ? 'active' : ''}`}
                        onClick={() => setFilterStatus('PENDING')}
                    >
                        Pending
                    </button>
                    <button
                        className={`filter-btn ${filterStatus === 'FILLED' ? 'active' : ''}`}
                        onClick={() => setFilterStatus('FILLED')}
                    >
                        Filled
                    </button>
                    <button
                        className={`filter-btn ${filterStatus === 'CANCELLED' ? 'active' : ''}`}
                        onClick={() => setFilterStatus('CANCELLED')}
                    >
                        Cancelled
                    </button>
                </div>
            </div>

            {actionMessage && (
                <div className={`alert ${actionMessage.type === 'success' ? 'alert-success' : 'alert-error'}`}>
                    {actionMessage.text}
                </div>
            )}

            <div className="card">
                <div className="table-responsive">
                    <table className="table">
                        <thead>
                            <tr>
                                <th>Order ID</th>
                                <th>Date & Time</th>
                                <th>Symbol</th>
                                <th>Side</th>
                                <th>Type</th>
                                <th>Quantity</th>
                                <th>Price</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="9" className="text-center py-4">Loading orders...</td>
                                </tr>
                            ) : orders.length === 0 ? (
                                <tr>
                                    <td colSpan="9" className="text-center text-muted py-4">No orders found.</td>
                                </tr>
                            ) : (
                                orders.map(o => (
                                    <tr key={o.orderId}>
                                        <td><strong>#{o.orderId}</strong></td>
                                        <td>{new Date(o.createdDate).toLocaleString()}</td>
                                        <td><strong>{o.symbol}</strong></td>
                                        <td>
                                            <span className={`badge ${o.side === 'BUY' ? 'badge-buy' : 'badge-sell'}`}>
                                                {o.side}
                                            </span>
                                        </td>
                                        <td>{o.orderType}</td>
                                        <td>{safeNum(o.quantity).toFixed(8)}</td>
                                        <td>{o.price ? `$${formatMoney(o.price)}` : 'MARKET'}</td>
                                        <td>
                                            <span className={`badge badge-status-${o.status.toLowerCase()}`}>
                                                {o.status}
                                            </span>
                                        </td>
                                        <td>
                                            {o.status === 'PENDING' && (
                                                <button
                                                    className="btn btn-sm btn-danger"
                                                    onClick={() => handleCancel(o.orderId)}
                                                >
                                                    Cancel
                                                </button>
                                            )}
                                        </td>
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

