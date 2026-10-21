import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { Monitor, Smartphone, CheckCircle, RefreshCw, LogOut, ArrowLeft, ExternalLink, ShieldCheck } from 'lucide-react';

const API_BASE_URL = 'https://wallpaper-sync-api.canvaslink.workers.dev';

export default function Dashboard() {
  const [token, setToken] = useState(localStorage.getItem('jwt_token') || '');
  const [inputToken, setInputToken] = useState('');
  const [boards, setBoards] = useState([]);
  const [selectedBoards, setSelectedBoards] = useState({ mobile: null, desktop: null, fallback: null });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (token) {
      fetchBoards();
    }
  }, [token]);

  const handleLogin = (e) => {
    e.preventDefault();
    if (!inputToken.trim()) return;
    localStorage.setItem('jwt_token', inputToken.trim());
    setToken(inputToken.trim());
  };

  const handleLogout = () => {
    localStorage.removeItem('jwt_token');
    setToken('');
    setBoards([]);
  };

  const fetchBoards = async () => {
    setIsLoading(true);
    setError('');
    try {
      const response = await fetch(`${API_BASE_URL}/api/boards`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      if (!response.ok) {
        if (response.status === 401) {
          handleLogout();
          throw new Error('Session expired. Please log in again.');
        }
        throw new Error('Failed to fetch boards.');
      }
      const data = await response.json();
      setBoards(data.items || []);
      if (data.selected_boards) {
        setSelectedBoards(data.selected_boards);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const setBoard = async (boardId, deviceType) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/set-board`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}` 
        },
        body: JSON.stringify({ board_id: boardId, device_type: deviceType })
      });
      
      if (!response.ok) throw new Error('Failed to update board');
      
      // Update local state to reflect change immediately and clear legacy fallback
      setSelectedBoards(prev => ({ ...prev, [deviceType]: boardId, fallback: null }));
    } catch (err) {
      alert(err.message);
    }
  };

  if (!token) {
    return (
      <div style={{ backgroundColor: 'var(--color-surface-soft)', minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '64px 24px' }}>
        <motion.div 
          className="feature-card-box" 
          style={{ maxWidth: '480px', width: '100%', border: '1px solid var(--color-hairline-soft)', textAlign: 'center' }}
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <div className="brand-badge-p" style={{ width: '48px', height: '48px', fontSize: '24px', margin: '0 auto 16px auto' }}>
            P
          </div>
          <h1 className="heading-xl" style={{ marginBottom: '8px' }}>Sync Dashboard</h1>
          <p className="body-sm" style={{ color: 'var(--color-mute)', marginBottom: '24px' }}>
            Enter your Canvas Link session token to view and manage device board associations.
          </p>

          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <input
              type="text"
              value={inputToken}
              onChange={(e) => setInputToken(e.target.value)}
              placeholder="Paste session token (eyJhbGci...)"
              className="text-input"
              style={{ fontFamily: 'monospace', fontSize: '14px' }}
            />
            <button type="submit" className="btn-primary" style={{ width: '100%', height: '44px' }}>
              Access Dashboard
            </button>
          </form>

          <div style={{ marginTop: '24px', borderTop: '1px solid var(--color-hairline-soft)', paddingTop: '16px' }}>
            <Link to="/" className="link-inline" style={{ fontSize: '14px' }}>
              ← Return to Discovery Feed
            </Link>
          </div>
        </motion.div>
      </div>
    );
  }

  return (
    <div style={{ backgroundColor: 'var(--color-surface-soft)', minHeight: '100vh', padding: '48px 0 64px 0' }}>
      <div className="container">
        {/* Top Header Bar */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px', flexWrap: 'wrap', gap: '16px' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
              <span className="caption-sm" style={{ color: 'var(--color-primary)', fontWeight: 700, textTransform: 'uppercase' }}>
                Active Session
              </span>
            </div>
            <h1 className="display-lg">Your Pinterest Boards</h1>
            <p className="body-md" style={{ color: 'var(--color-mute)' }}>
              Choose which Pinterest board synchronizes with your PC and Android screens.
            </p>
          </div>

          <div style={{ display: 'flex', gap: '12px' }}>
            <button onClick={fetchBoards} className="btn-secondary">
              <RefreshCw size={16} />
              <span>Refresh</span>
            </button>
            <button onClick={handleLogout} className="btn-secondary">
              <LogOut size={16} />
              <span>Log out</span>
            </button>
          </div>
        </div>

        {error && (
          <div style={{ backgroundColor: 'var(--color-surface-card)', borderLeft: '4px solid var(--color-error)', padding: '16px', borderRadius: 'var(--rounded-sm)', color: 'var(--color-error)', marginBottom: '24px' }}>
            <p className="body-strong">{error}</p>
          </div>
        )}

        {isLoading ? (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '96px 0' }}>
            <motion.div animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1, ease: "linear" }}>
              <RefreshCw size={36} color="var(--color-primary)" />
            </motion.div>
          </div>
        ) : boards.length === 0 ? (
          <div className="feature-card-box" style={{ maxWidth: '640px', margin: '48px auto', textAlign: 'center', border: '1px solid var(--color-hairline-soft)' }}>
            <h3 className="heading-lg" style={{ marginBottom: '12px' }}>No Pinterest Boards Found</h3>
            <p className="body-md" style={{ color: 'var(--color-mute)', marginBottom: '24px' }}>
              Your connected Pinterest account does not have any boards with pins yet. Create a board on Pinterest, pin wallpapers to it, and refresh this page.
            </p>
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
              <a 
                href="https://www.pinterest.com" 
                target="_blank" 
                rel="noreferrer" 
                className="btn-primary"
              >
                <span>Open Pinterest</span>
                <ExternalLink size={14} />
              </a>
              <button onClick={fetchBoards} className="btn-secondary">
                Refresh Boards
              </button>
            </div>
          </div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '20px' }}>
            {boards.map((board) => {
              const isMobile = selectedBoards.mobile === board.id || (selectedBoards.mobile == null && selectedBoards.fallback === board.id);
              const isDesktop = selectedBoards.desktop === board.id || (selectedBoards.desktop == null && selectedBoards.fallback === board.id);

              return (
                <div 
                  key={board.id} 
                  className="feature-card-box" 
                  style={{ border: '1px solid var(--color-hairline-soft)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}
                >
                  <div style={{ marginBottom: '24px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                      <h3 className="heading-md" style={{ color: 'var(--color-ink)' }}>{board.name}</h3>
                      <span className="caption-sm">{board.pin_count ? `${board.pin_count} pins` : 'Board'}</span>
                    </div>
                    <p className="body-sm" style={{ color: 'var(--color-mute)' }}>
                      {board.description || 'Pinterest wallpaper collection'}
                    </p>
                  </div>
                  
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    <button 
                      onClick={() => setBoard(isMobile ? null : board.id, 'mobile')}
                      className={isMobile ? "btn-primary" : "btn-secondary"}
                      style={{ width: '100%', justifyContent: 'space-between' }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <Smartphone size={16} />
                        <span>{isMobile ? 'Active for Android' : 'Assign to Android'}</span>
                      </div>
                      {isMobile && <CheckCircle size={16} />}
                    </button>

                    <button 
                      onClick={() => setBoard(isDesktop ? null : board.id, 'desktop')}
                      className={isDesktop ? "btn-primary" : "btn-secondary"}
                      style={{ width: '100%', justifyContent: 'space-between' }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <Monitor size={16} />
                        <span>{isDesktop ? 'Active for PC' : 'Assign to Windows PC'}</span>
                      </div>
                      {isDesktop && <CheckCircle size={16} />}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
