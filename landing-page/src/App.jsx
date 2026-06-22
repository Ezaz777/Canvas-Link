import React from 'react';
import { motion } from 'framer-motion';
import { Routes, Route, Link } from 'react-router-dom';
import PrivacyPolicy from './PrivacyPolicy';
import { 
  Monitor, 
  Smartphone, 
  RefreshCw, 
  ShieldCheck, 
  Battery, 
  Code,
  Heart
} from 'lucide-react';

function Home() {
  const fadeInUp = {
    initial: { opacity: 0, y: 30 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.6 }
  };

  const stagger = {
    animate: {
      transition: {
        staggerChildren: 0.2
      }
    }
  };

  return (
    <>
      {/* Hero Section */}
      <section className="hero">
        <div className="hero-bg-blob-1"></div>
        <div className="hero-bg-blob-2"></div>
        
        <div className="container">
          <motion.div 
            className="hero-content"
            initial="initial"
            animate="animate"
            variants={stagger}
          >
            <motion.h1 className="hero-title" variants={fadeInUp}>
              Your Daily <span className="text-gradient">Pinterest</span> Inspiration
            </motion.h1>
            
            <motion.p className="hero-subtitle" variants={fadeInUp}>
              A seamless, cross-platform wallpaper synchronization system that brings your favorite Pinterest boards right to your screens every single day.
            </motion.p>
            
            <motion.div className="hero-actions" variants={fadeInUp}>
              <button className="btn btn-primary" onClick={() => alert('Download coming soon!')}>
                <Monitor size={20} />
                Download for Windows
              </button>
              <button className="btn btn-secondary" onClick={() => alert('Download coming soon!')}>
                <Smartphone size={20} />
                Download for Android
              </button>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section className="section" id="features">
        <div className="container">
          <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
            <h2>Powerful Features, <span className="text-gradient">Zero Distractions</span></h2>
          </div>
          
          <div className="features-grid">
            <div className="feature-card glass-panel">
              <div className="feature-icon-wrapper">
                <RefreshCw size={28} />
              </div>
              <h3 className="feature-title">Automated Daily Sync</h3>
              <p className="feature-desc">Wake up to a brand new wallpaper every day. The app automatically fetches and applies an image from your selected Pinterest board.</p>
            </div>
            
            <div className="feature-card glass-panel">
              <div className="feature-icon-wrapper">
                <ShieldCheck size={28} />
              </div>
              <h3 className="feature-title">Secure OAuth</h3>
              <p className="feature-desc">Your credentials are never stored. We use industry-standard OAuth to securely connect to Pinterest, managed by a robust Cloudflare backend.</p>
            </div>
            
            <div className="feature-card glass-panel">
              <div className="feature-icon-wrapper">
                <Battery size={28} />
              </div>
              <h3 className="feature-title">Battery Friendly</h3>
              <p className="feature-desc">Built using modern OS APIs like Android WorkManager and PC Task Scheduler, it syncs quietly without draining your battery or hogging CPU.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Why Us Section */}
      <section className="section why-section">
        <div className="container why-grid">
          <div>
            <h2 style={{ fontSize: '2.5rem', marginBottom: '1.5rem' }}>Why choose <br/><span className="text-gradient">Canvas-Link?</span></h2>
            <p className="feature-desc" style={{ fontSize: '1.125rem', marginBottom: '2rem' }}>
              Unlike other wallpaper apps that bombard you with ads or drain your device resources, Canvas-Link is entirely open-source, lightweight, and focused purely on bringing you joy.
            </p>
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <li style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                <ShieldCheck size={20} className="text-gradient" />
                <span>100% Free and Open Source</span>
              </li>
              <li style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                <Monitor size={20} className="text-gradient" />
                <span>Synchronized experience across Mobile and Desktop</span>
              </li>
              <li style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                <Heart size={20} className="text-gradient" />
                <span>Support development with built-in Razorpay integration</span>
              </li>
            </ul>
          </div>
          
          <div className="why-image-placeholder glass-panel">
            <div style={{ textAlign: 'center' }}>
              <Monitor size={64} style={{ color: 'rgba(255,255,255,0.5)', marginBottom: '1rem' }} />
              <Smartphone size={48} style={{ color: 'rgba(255,255,255,0.3)' }} />
              <p style={{ marginTop: '1rem', color: 'rgba(255,255,255,0.7)', fontWeight: '600' }}>Cross-Platform Synergy</p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="container footer-content">
          <div>
            <div className="nav-brand" style={{ fontSize: '1.2rem', marginBottom: '0.5rem' }}>
              <img src="/logo.png" alt="Logo" style={{ width: 24, height: 24, borderRadius: '6px' }} />
              <span>Canvas-Link</span>
            </div>
            <p>© {new Date().getFullYear()} Canvas-Link. All rights reserved.</p>
          </div>
          
          <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
            <Link 
              to="/privacy"
              className="feature-desc" 
              style={{ background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: '1rem' }}
              onClick={() => window.scrollTo(0, 0)}
            >
              Privacy Policy
            </Link>
            <a href="https://github.com/Ezaz777/Canvas-Link" className="feature-desc" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Code size={16} /> GitHub
            </a>
          </div>
        </div>
      </footer>
    </>
  );
}

function App() {
  return (
    <>
      {/* Navbar */}
      <nav className="navbar">
        <div className="container">
          <div className="nav-brand">
            <img src="/logo.png" alt="Logo" style={{ width: 32, height: 32, borderRadius: '8px', boxShadow: '0 0 10px rgba(139, 92, 246, 0.5)' }} />
            <Link to="/" style={{ color: 'inherit' }}>Canvas-Link</Link>
          </div>
          <div>
            <a href="https://github.com/Ezaz777/Canvas-Link" target="_blank" rel="noreferrer" className="btn btn-secondary">
              <Code size={18} />
              <span>GitHub</span>
            </a>
          </div>
        </div>
      </nav>

      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/privacy" element={<PrivacyPolicy />} />
      </Routes>
    </>
  );
}

export default App;
