import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Monitor, Smartphone, CheckCircle, RefreshCw } from 'lucide-react';

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
      
      if (!response.ok) throw new Error('Failed to set board');
      
      // Update local state to reflect change immediately
      setSelectedBoards(prev => ({ ...prev, [deviceType]: boardId }));
    } catch (err) {
      alert(err.message);
    }
  };

  if (!token) {
    return (
      <section className="section" style={{ minHeight: '80vh', display: 'flex', alignItems: 'center' }}>
        <div className="container" style={{ maxWidth: '500px', width: '100%' }}>
          <motion.div 
            className="glass-panel" 
            style={{ padding: '2.5rem', textAlign: 'center' }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <h2 style={{ marginBottom: '1.5rem', fontSize: '2rem' }}>Welcome Back</h2>
            <p className="feature-desc" style={{ marginBottom: '2rem' }}>
              Paste your JWT token to access your Canvas Link dashboard and manage your Pinterest boards.
            </p>
            <form onSubmit={handleLogin}>
              <input
                type="text"
                value={inputToken}
                onChange={(e) => setInputToken(e.target.value)}
                placeholder="eyJh..."
                style={{
                  width: '100%',
                  padding: '1rem',
                  borderRadius: '12px',
                  border: '1px solid rgba(255,255,255,0.2)',
                  background: 'rgba(0,0,0,0.2)',
                  color: '#fff',
                  fontFamily: 'monospace',
                  marginBottom: '1.5rem',
                  outline: 'none'
                }}
              />
              <button type="submit" className="btn btn-primary" style={{ width: '100%' }}>
                Access Dashboard
              </button>
            </form>
          </motion.div>
        </div>
      </section>
    );
  }

  return (
    <section className="section" style={{ minHeight: '80vh', paddingTop: '8rem' }}>
      <div className="container">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '3rem' }}>
          <div>
            <h1 style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>Your <span className="text-gradient">Boards</span></h1>
            <p className="feature-desc">Select which Pinterest board syncs to which device.</p>
          </div>
          <button onClick={handleLogout} className="btn btn-secondary">
            Logout
          </button>
        </div>

        {error && (
          <div style={{ background: 'rgba(239, 68, 68, 0.2)', border: '1px solid #ef4444', padding: '1rem', borderRadius: '12px', color: '#fca5a5', marginBottom: '2rem' }}>
            {error}
          </div>
        )}

        {isLoading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: '4rem' }}>
            <motion.div animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1, ease: "linear" }}>
              <RefreshCw size={32} className="text-gradient" />
            </motion.div>
          </div>
        ) : (
          <div className="features-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))' }}>
            {boards.map((board) => {
              const isMobile = selectedBoards.mobile === board.id || (selectedBoards.mobile == null && selectedBoards.fallback === board.id);
              const isDesktop = selectedBoards.desktop === board.id || (selectedBoards.desktop == null && selectedBoards.fallback === board.id);

              return (
                <motion.div 
                  key={board.id} 
                  className="feature-card glass-panel" 
                  style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column' }}
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                >
                  <h3 style={{ fontSize: '1.25rem', marginBottom: '1.5rem', fontWeight: '600' }}>{board.name}</h3>
                  
                  <div style={{ marginTop: 'auto', display: 'flex', gap: '1rem', flexDirection: 'column' }}>
                    <button 
                      onClick={() => setBoard(board.id, 'mobile')}
                      style={{
                        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem',
                        padding: '0.75rem', borderRadius: '10px',
                        background: isMobile ? 'rgba(124, 58, 237, 0.3)' : 'rgba(255,255,255,0.05)',
                        border: isMobile ? '1px solid #7c3aed' : '1px solid rgba(255,255,255,0.1)',
                        color: isMobile ? '#fff' : 'rgba(255,255,255,0.7)',
                        cursor: 'pointer', transition: 'all 0.2s',
                        fontWeight: '600'
                      }}
                    >
                      <Smartphone size={18} />
                      {isMobile ? 'Active on Mobile' : 'Set for Mobile'}
                      {isMobile && <CheckCircle size={16} color="#34d399" />}
                    </button>

                    <button 
                      onClick={() => setBoard(board.id, 'desktop')}
                      style={{
                        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem',
                        padding: '0.75rem', borderRadius: '10px',
                        background: isDesktop ? 'rgba(16, 185, 129, 0.2)' : 'rgba(255,255,255,0.05)',
                        border: isDesktop ? '1px solid #10b981' : '1px solid rgba(255,255,255,0.1)',
                        color: isDesktop ? '#fff' : 'rgba(255,255,255,0.7)',
                        cursor: 'pointer', transition: 'all 0.2s',
                        fontWeight: '600'
                      }}
                    >
                      <Monitor size={18} />
                      {isDesktop ? 'Active on PC' : 'Set for PC'}
                      {isDesktop && <CheckCircle size={16} color="#34d399" />}
                    </button>
                  </div>
                </motion.div>
              );
            })}
          </div>
        )}
      </div>
    </section>
  );
}
