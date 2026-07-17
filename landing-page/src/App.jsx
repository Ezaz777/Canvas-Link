import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Routes, Route, Link } from 'react-router-dom';
import PrivacyPolicy from './PrivacyPolicy';
import Dashboard from './Dashboard';
import Features from './Features';
import Installation from './Installation';
import { 
  Monitor, 
  Smartphone, 
  RefreshCw, 
  ShieldCheck, 
  Battery, 
  Code,
  Heart,
  Menu,
  X
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

      {/* How It Works Section */}
      <section className="section" style={{ background: 'var(--color-bg-secondary)' }}>
        <div className="container">
          <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
            <h2>How It Works in <span className="text-gradient">3 Simple Steps</span></h2>
          </div>
          
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '2rem', textAlign: 'center' }}>
            <div className="glass-panel" style={{ padding: '2rem' }}>
              <div style={{ fontSize: '3rem', fontWeight: 'bold', color: 'rgba(139, 92, 246, 0.5)', marginBottom: '1rem' }}>1</div>
              <h3 style={{ marginBottom: '1rem' }}>Connect Pinterest</h3>
              <p className="feature-desc">Log in securely and select the board you want to sync your wallpapers from.</p>
            </div>
            
            <div className="glass-panel" style={{ padding: '2rem' }}>
              <div style={{ fontSize: '3rem', fontWeight: 'bold', color: 'rgba(139, 92, 246, 0.5)', marginBottom: '1rem' }}>2</div>
              <h3 style={{ marginBottom: '1rem' }}>Set Schedule</h3>
              <p className="feature-desc">Choose what time of day your PC and mobile devices should fetch the next image.</p>
            </div>
            
            <div className="glass-panel" style={{ padding: '2rem' }}>
              <div style={{ fontSize: '3rem', fontWeight: 'bold', color: 'rgba(139, 92, 246, 0.5)', marginBottom: '1rem' }}>3</div>
              <h3 style={{ marginBottom: '1rem' }}>Enjoy</h3>
              <p className="feature-desc">Sit back and relax. Your devices will silently and seamlessly update your background every day.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Why Us Section */}
      <section className="section why-section" style={{ background: 'var(--color-bg)' }}>
        <div className="container why-grid">
          <div>
            <h2 style={{ fontSize: '2.5rem', marginBottom: '1.5rem' }}>Why choose <br/><span className="text-gradient">Canvas Link?</span></h2>
            <p className="feature-desc" style={{ fontSize: '1.125rem', marginBottom: '2rem' }}>
              Unlike other wallpaper apps that bombard you with ads or drain your device resources, Canvas Link is entirely open-source, lightweight, and focused purely on bringing you joy.
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

      {/* FAQ Section */}
      <section className="section" style={{ background: 'var(--color-bg-secondary)' }}>
        <div className="container" style={{ maxWidth: '800px' }}>
          <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
            <h2>Frequently Asked <span className="text-gradient">Questions</span></h2>
          </div>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <div className="glass-panel" style={{ padding: '2rem' }}>
              <h3 style={{ marginBottom: '0.5rem' }}>Does this drain my battery?</h3>
              <p className="feature-desc">Not at all! We use native OS APIs (Android WorkManager and Windows Task Scheduler) which are highly optimized to run in the background without hogging resources.</p>
            </div>
            
            <div className="glass-panel" style={{ padding: '2rem' }}>
              <h3 style={{ marginBottom: '0.5rem' }}>What if I don't like today's wallpaper?</h3>
              <p className="feature-desc">You can use the "Skip Wallpaper" button on the dashboard. It instantly fast-forwards your cycle to the next image and syncs that choice across your devices.</p>
            </div>
            
            <div className="glass-panel" style={{ padding: '2rem' }}>
              <h3 style={{ marginBottom: '0.5rem' }}>Is Canvas Link really free?</h3>
              <p className="feature-desc">Yes! It is 100% free and open-source. However, if you'd like to support the developer and server costs, there is a built-in Razorpay donation option in the dashboard!</p>
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
              <span>Canvas Link</span>
            </div>
            <p>© {new Date().getFullYear()} Canvas Link. All rights reserved.</p>
          </div>
          
          <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
            <Link 
              to="/features"
              className="feature-desc" 
              style={{ background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: '1rem' }}
              onClick={() => window.scrollTo(0, 0)}
            >
              Features
            </Link>
            <Link 
              to="/installation"
              className="feature-desc" 
              style={{ background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: '1rem' }}
              onClick={() => window.scrollTo(0, 0)}
            >
              Installation
            </Link>
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
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  return (
    <>
      {/* Navbar */}
      <nav className="navbar">
        <div className="container" style={{ position: 'relative' }}>
          <div className="nav-brand">
            <img src="/logo.png" alt="Logo" style={{ width: 32, height: 32, borderRadius: '8px', boxShadow: '0 0 10px rgba(139, 92, 246, 0.5)' }} />
            <Link to="/" style={{ color: 'inherit' }}>Canvas Link</Link>
          </div>
          
          <div className="desktop-nav-links">
            {/* Desktop nav links removed as requested - mobile menu used globally */}
          </div>

          <button 
            className="mobile-menu-btn" 
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          >
            {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>

          {isMobileMenuOpen && (
            <div className="mobile-menu open">
              <Link to="/features" className="btn" style={{ background: 'rgba(255,255,255,0.05)', color: '#fff', padding: '8px 16px', borderRadius: '8px', textDecoration: 'none', fontWeight: '600', justifyContent: 'center' }} onClick={() => setIsMobileMenuOpen(false)}>
                Features
              </Link>
              <Link to="/installation" className="btn" style={{ background: 'rgba(255,255,255,0.05)', color: '#fff', padding: '8px 16px', borderRadius: '8px', textDecoration: 'none', fontWeight: '600', justifyContent: 'center' }} onClick={() => setIsMobileMenuOpen(false)}>
                Installation
              </Link>
              <Link to="/dashboard" className="btn" style={{ background: 'rgba(255,255,255,0.1)', color: '#fff', padding: '8px 16px', borderRadius: '8px', textDecoration: 'none', fontWeight: '600', justifyContent: 'center' }} onClick={() => setIsMobileMenuOpen(false)}>
                Dashboard
              </Link>
              <a href="https://github.com/Ezaz777/Canvas-Link" target="_blank" rel="noreferrer" className="btn btn-secondary" style={{ justifyContent: 'center' }} onClick={() => setIsMobileMenuOpen(false)}>
                <Code size={18} />
                <span>GitHub</span>
              </a>
            </div>
          )}
        </div>
      </nav>

      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/features" element={<Features />} />
        <Route path="/installation" element={<Installation />} />
        <Route path="/privacy" element={<PrivacyPolicy />} />
        <Route path="/dashboard" element={<Dashboard />} />
      </Routes>
    </>
  );
}

export default App;
