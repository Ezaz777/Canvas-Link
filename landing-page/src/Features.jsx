import React from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { 
  Zap, 
  FastForward, 
  Cloud, 
  Code2, 
  ShieldCheck, 
  CheckCircle2, 
  ArrowLeft, 
  Download,
  Calendar,
  Layers,
  Sparkles
} from 'lucide-react';

const Features = ({ onOpenDownloadModal }) => {
  return (
    <div style={{ backgroundColor: 'var(--color-surface-soft)', minHeight: '100vh', paddingBottom: '64px' }}>
      {/* Editorial Header */}
      <section style={{ backgroundColor: 'var(--color-canvas)', borderBottom: '1px solid var(--color-hairline)', padding: '64px 0 48px 0' }}>
        <div className="container" style={{ maxWidth: '880px', textAlign: 'center' }}>
          <Link 
            to="/" 
            className="btn-tertiary" 
            style={{ marginBottom: '24px', display: 'inline-flex' }}
          >
            <ArrowLeft size={16} />
            <span>Back to Discovery Feed</span>
          </Link>

          <span style={{ color: 'var(--color-primary)', fontWeight: 700, fontSize: '14px', textTransform: 'uppercase', letterSpacing: '1px', display: 'block', marginBottom: '12px' }}>
            System Architecture & Features
          </span>
          <h1 className="display-lg">
            Built for photographers, art collectors, and wallpaper enthusiasts.
          </h1>
          <p className="hero-subheading" style={{ margin: '16px auto 32px auto' }}>
            Discover the mathematics, security model, and background orchestration powering your seamless wallpaper sync.
          </p>

          <div style={{ display: 'flex', justifyContent: 'center', gap: '12px' }}>
            <button 
              className="btn-primary"
              onClick={() => onOpenDownloadModal && onOpenDownloadModal('all')}
            >
              <Download size={16} />
              <span>Download Free Client</span>
            </button>
            <Link to="/installation" className="btn-secondary">
              <span>Setup Guide</span>
            </Link>
          </div>
        </div>
      </section>

      {/* Main Feature Cards */}
      <div className="container" style={{ maxWidth: '880px', paddingTop: '48px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>

          {/* Feature 1: Deterministic Cycle */}
          <div className="feature-card-box" style={{ border: '1px solid var(--color-hairline-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: 'var(--rounded-full)', backgroundColor: 'var(--color-surface-card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)' }}>
                <Zap size={20} />
              </div>
              <h2 className="heading-xl">The Stateless Deterministic Shuffle</h2>
            </div>
            
            <p className="body-md" style={{ color: 'var(--color-body)', marginBottom: '20px', lineHeight: '1.6' }}>
              Instead of picking wallpapers at random (which frequently serves duplicate images), Canvas Link implements a deterministic cyclical permutation based on the exact pin count of your chosen board and calendar day.
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px' }}>
              <div style={{ padding: '16px', backgroundColor: 'var(--color-surface-card)', borderRadius: 'var(--rounded-md)' }}>
                <p className="body-strong" style={{ marginBottom: '6px' }}>No Repeat Guarantee</p>
                <p className="body-sm">If your Pinterest board has 60 pins, you are guaranteed 60 unique daily wallpapers before the cycle resets.</p>
              </div>

              <div style={{ padding: '16px', backgroundColor: 'var(--color-surface-card)', borderRadius: 'var(--rounded-md)' }}>
                <p className="body-strong" style={{ marginBottom: '6px' }}>Dynamic Board Expansion</p>
                <p className="body-sm">Whenever you save new pins to your board, the cycle automatically recalculates and extends without resetting your progress.</p>
              </div>

              <div style={{ padding: '16px', backgroundColor: 'var(--color-surface-card)', borderRadius: 'var(--rounded-md)' }}>
                <p className="body-strong" style={{ marginBottom: '6px' }}>Zero Peer Communication</p>
                <p className="body-sm">Both your Windows PC and Android phone derive the exact same wallpaper independently, saving network calls and battery.</p>
              </div>
            </div>
          </div>

          {/* Feature 2: Fast-forward Skip */}
          <div className="feature-card-box" style={{ border: '1px solid var(--color-hairline-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: 'var(--rounded-full)', backgroundColor: 'var(--color-surface-card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)' }}>
                <FastForward size={20} />
              </div>
              <h2 className="heading-xl">Instant Timeline Fast-Forward</h2>
            </div>
            
            <p className="body-md" style={{ color: 'var(--color-body)', marginBottom: '16px', lineHeight: '1.6' }}>
              Not in the mood for today's wallpaper? Clicking <strong>"Skip Wallpaper"</strong> on your desktop widget or mobile app safely increments your account's offset cursor.
            </p>
            <p className="body-md" style={{ color: 'var(--color-mute)', lineHeight: '1.6' }}>
              Your current device updates immediately with the next pin in sequence, and all other paired devices naturally transition to the new timeline on their next scheduled refresh.
            </p>
          </div>

          {/* Feature 3: Cloudflare Edge Backend */}
          <div className="feature-card-box" style={{ border: '1px solid var(--color-hairline-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: 'var(--rounded-full)', backgroundColor: 'var(--color-surface-card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)' }}>
                <Cloud size={20} />
              </div>
              <h2 className="heading-xl">Cloudflare Edge & Serverless D1</h2>
            </div>
            
            <p className="body-md" style={{ color: 'var(--color-body)', lineHeight: '1.6', marginBottom: '16px' }}>
              Built on Cloudflare Workers deployed across 300+ edge locations worldwide. Responses take milliseconds, and your OAuth session tokens are heavily protected using AES-GCM 256-bit encryption before hitting persistent storage.
            </p>

            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <span className="pin-overlay-pill" style={{ position: 'static' }}>Cloudflare Workers</span>
              <span className="pin-overlay-pill" style={{ position: 'static' }}>D1 Serverless SQLite</span>
              <span className="pin-overlay-pill" style={{ position: 'static' }}>AES-GCM Encryption</span>
              <span className="pin-overlay-pill" style={{ position: 'static' }}>Sub-50ms Latency</span>
            </div>
          </div>

          {/* Feature 4: Open Source Integrity */}
          <div className="feature-card-box" style={{ border: '1px solid var(--color-hairline-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: 'var(--rounded-full)', backgroundColor: 'var(--color-surface-card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)' }}>
                <Code2 size={20} />
              </div>
              <h2 className="heading-xl">100% Free & Open Source</h2>
            </div>
            
            <p className="body-md" style={{ color: 'var(--color-body)', lineHeight: '1.6', marginBottom: '20px' }}>
              Canvas Link is licensed under the permissive MIT license. You can inspect every single line of code, run your own private server if desired, or contribute enhancements via GitHub pull requests.
            </p>

            <a 
              href="https://github.com/Ezaz777/Canvas-Link" 
              target="_blank" 
              rel="noreferrer"
              className="btn-secondary"
              style={{ display: 'inline-flex' }}
            >
              <span>Explore GitHub Repository</span>
              <Code2 size={16} />
            </a>
          </div>

        </div>
      </div>
    </div>
  );
};

export default Features;
