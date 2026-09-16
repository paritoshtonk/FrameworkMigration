import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { formatMoney, extractProfile } from '../utils/formatters';

export default function Profile({ user, onProfileUpdated }) {
    const initialProf = extractProfile(null, user) || {};
    const [profileData, setProfileData] = useState(() => initialProf);
    const [firstName, setFirstName] = useState(user?.firstName || '');
    const [lastName, setLastName] = useState(user?.lastName || '');
    const [email, setEmail] = useState(user?.email || '');
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState(null);

    useEffect(() => {
        let isMounted = true;
        const fetchProfile = async () => {
            try {
                const data = await api.getProfile();
                if (!isMounted) return;
                const prof = extractProfile(data, user);
                setProfileData(prof);
                if (prof) {
                    setFirstName(prof.firstName || user?.firstName || '');
                    setLastName(prof.lastName || user?.lastName || '');
                    setEmail(prof.email || user?.email || '');
                }
            } catch (err) {
                console.error('Failed to load profile:', err);
            } finally {
                if (isMounted) setLoading(false);
            }
        };
        fetchProfile();
        return () => { isMounted = false; };
    }, [user]);

    const handleSave = async (e) => {
        e.preventDefault();
        setMessage(null);
        setSaving(true);
        try {
            const raw = await api.updateProfile({ firstName, lastName, email });
            const updated = extractProfile(raw, {
                ...profileData,
                ...user,
                firstName,
                lastName,
                email
            });
            setProfileData(updated);
            setMessage({ type: 'success', text: 'Profile updated successfully.' });
            if (onProfileUpdated) {
                onProfileUpdated(updated);
            }
        } catch (err) {
            setMessage({ type: 'error', text: err.message || 'Failed to update profile.' });
        } finally {
            setSaving(false);
        }
    };

    if (loading && !profileData?.username && !user?.username) {
        return <div className="p-4 text-center">Loading profile...</div>;
    }

    const prof = extractProfile(profileData, user) || {};

    return (
        <div className="profile-view">
            <div className="section-header">
                <h3>User Profile & Account Settings</h3>
            </div>

            {message && (
                <div className={`alert ${message.type === 'success' ? 'alert-success' : 'alert-error'}`}>
                    {message.text}
                </div>
            )}

            <div className="profile-grid">
                {/* Account Details */}
                <div className="card">
                    <div className="card-header">
                        <h4>Account Information</h4>
                    </div>
                    <div className="p-3">
                        <div className="detail-item">
                            <span>User ID:</span>
                            <strong>#{prof.userId || '-'}</strong>
                        </div>
                        <div className="detail-item">
                            <span>Username:</span>
                            <strong>{prof.username || '-'}</strong>
                        </div>
                        <div className="detail-item">
                            <span>Account ID:</span>
                            <strong>#{prof.accountId || prof.userId || '-'}</strong>
                        </div>
                        <div className="detail-item">
                            <span>Cash Balance:</span>
                            <strong className="text-success">${formatMoney(prof.cashBalance)} {prof.currency || 'USD'}</strong>
                        </div>
                        <div className="detail-item">
                            <span>Member Since:</span>
                            <span>{prof.createdDate ? new Date(prof.createdDate).toLocaleDateString() : 'N/A'}</span>
                        </div>
                        <div className="detail-item">
                            <span>Last Login:</span>
                            <span>{prof.lastLoginDate ? new Date(prof.lastLoginDate).toLocaleString() : 'First session'}</span>
                        </div>
                    </div>
                </div>

                {/* Edit Form */}
                <div className="card">
                    <div className="card-header">
                        <h4>Edit Personal Information</h4>
                    </div>
                    <form onSubmit={handleSave} className="p-3">
                        <div className="form-group">
                            <label>First Name</label>
                            <input
                                type="text"
                                value={firstName}
                                onChange={(e) => setFirstName(e.target.value)}
                                placeholder="Enter first name"
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Last Name</label>
                            <input
                                type="text"
                                value={lastName}
                                onChange={(e) => setLastName(e.target.value)}
                                placeholder="Enter last name"
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Email Address</label>
                            <input
                                type="email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                placeholder="Enter email address"
                                required
                            />
                        </div>

                        <button type="submit" className="btn btn-primary btn-block" disabled={saving}>
                            {saving ? 'Saving...' : 'Save Profile Changes'}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
}
