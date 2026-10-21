import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { 
  Monitor, 
  Smartphone, 
  ShieldCheck, 
  Download, 
  ArrowLeft, 
  Check, 
  Copy,
  Terminal,
  ExternalLink
} from 'lucide-react';

const Installation = () => {
  const [copiedCode, setCopiedCode] = useState(false);

  const handleCopy = (text) => {
    navigator.clipboard.writeText(text);
    setCopiedCode(true);
    setTimeout(() => setCopiedCode(false), 2000);
  };

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
            Setup Documentation
          </span>
          <h1 className="display-lg">
            Install and synchronize your screens in minutes.
          </h1>
          <p className="hero-subheading" style={{ margin: '16px auto 0 auto' }}>
            Official guides for running the Windows Desktop Client and Android APK.
          </p>
        </div>
      </section>

      {/* Main Content */}
      <div className="container" style={{ maxWidth: '880px', paddingTop: '48px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>

          {/* Windows Setup Card */}
          <div className="feature-card-box" style={{ border: '1px solid var(--color-hairline-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ width: '44px', height: '44px', borderRadius: 'var(--rounded-full)', backgroundColor: 'var(--color-surface-card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)' }}>
                  <Monitor size={22} />
                </div>
                <div>
                  <h2 className="heading-xl">Windows Desktop Client</h2>
                  <span className="caption-sm">Supports Windows 10 & 11 (64-bit)</span>
                </div>
              </div>

              <a 
                href="https://github.com/Ezaz777/Canvas-Link/releases" 
                target="_blank" 
                rel="noreferrer"
                className="btn-primary"
              >
                <Download size={16} />
                <span>Download .EXE</span>
              </a>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start' }}>
                <div className="step-number-badge" style={{ width: '32px', height: '32px', fontSize: '15px', flexShrink: 0 }}>1</div>
                <div>
                  <p className="body-strong">Download and Launch</p>
                  <p className="body-sm">Download <code>Canvas Link.exe</code> from the official GitHub Releases and run it on your PC.</p>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start' }}>
                <div className="step-number-badge" style={{ width: '32px', height: '32px', fontSize: '15px', flexShrink: 0 }}>2</div>
                <div>
                  <p className="body-strong">Log in with Pinterest OAuth</p>
                  <p className="body-sm">Click <strong>"Log In"</strong> in the settings window. A browser tab will open to safely grant read-only board access.</p>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start' }}>
                <div className="step-number-badge" style={{ width: '32px', height: '32px', fontSize: '15px', flexShrink: 0 }}>3</div>
                <div>
                  <p className="body-strong">Set Preferred Sync Hour</p>
                  <p className="body-sm">Toggle <strong>"Enable Daily Sync at"</strong> and pick your time (e.g., 08:00 AM). Canvas Link creates a quiet Windows Task Scheduler trigger and closes.</p>
                </div>
              </div>
            </div>
          </div>

          {/* Android Setup Card */}
          <div className="feature-card-box" style={{ border: '1px solid var(--color-hairline-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ width: '44px', height: '44px', borderRadius: 'var(--rounded-full)', backgroundColor: 'var(--color-surface-card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)' }}>
                  <Smartphone size={22} />
                </div>
                <div>
                  <h2 className="heading-xl">Android Mobile App</h2>
                  <span className="caption-sm">Android 8.0 (Oreo) and above</span>
                </div>
              </div>

              <a 
                href="https://github.com/Ezaz777/Canvas-Link/releases" 
                target="_blank" 
                rel="noreferrer"
                className="btn-secondary"
              >
                <Download size={16} />
                <span>Download .APK</span>
              </a>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start' }}>
                <div className="step-number-badge" style={{ width: '32px', height: '32px', fontSize: '15px', flexShrink: 0 }}>1</div>
                <div>
                  <p className="body-strong">Install the APK</p>
                  <p className="body-sm">Download and install the APK on your device, allowing installation from unknown sources if prompted.</p>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start' }}>
                <div className="step-number-badge" style={{ width: '32px', height: '32px', fontSize: '15px', flexShrink: 0 }}>2</div>
                <div>
                  <p className="body-strong">Connect Account</p>
                  <p className="body-sm">Tap "Log in with Pinterest" to authenticate via the in-app secure browser.</p>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start' }}>
                <div className="step-number-badge" style={{ width: '32px', height: '32px', fontSize: '15px', flexShrink: 0 }}>3</div>
                <div>
                  <p className="body-strong">WorkManager Background Sync</p>
                  <p className="body-sm">Under Sync Frequency, set it to 24 hours. Android's native <code>WorkManager</code> handles updates automatically whenever unmetered Wi-Fi or charging conditions are met.</p>
                </div>
              </div>
            </div>
          </div>

          {/* Developers / CLI */}
          <div className="feature-card-box" style={{ border: '1px solid var(--color-hairline-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{ width: '44px', height: '44px', borderRadius: 'var(--rounded-full)', backgroundColor: 'var(--color-surface-card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-ink)' }}>
                <Terminal size={22} />
              </div>
              <div>
                <h2 className="heading-xl">Build From Source</h2>
                <span className="caption-sm">Python 3.10+ & Flutter 3.x</span>
              </div>
            </div>

            <p className="body-md" style={{ color: 'var(--color-mute)', marginBottom: '16px' }}>
              You can clone and build the PC client locally using standard Python tooling:
            </p>

            <div style={{ backgroundColor: 'var(--color-surface-card)', padding: '16px', borderRadius: 'var(--rounded-md)', position: 'relative', fontFamily: 'monospace', fontSize: '14px', color: 'var(--color-ink)' }}>
              <code>git clone https://github.com/Ezaz777/Canvas-Link.git<br/>cd "Canvas-Link/pc-client"<br/>pip install -r requirements.txt<br/>python main.py</code>
              <button 
                onClick={() => handleCopy('git clone https://github.com/Ezaz777/Canvas-Link.git\ncd "Canvas-Link/pc-client"\npip install -r requirements.txt\npython main.py')}
                style={{ position: 'absolute', top: '12px', right: '12px', background: 'var(--color-canvas)', border: '1px solid var(--color-hairline)', borderRadius: 'var(--rounded-sm)', padding: '6px 10px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px' }}
              >
                {copiedCode ? <Check size={14} color="green" /> : <Copy size={14} />}
                <span>{copiedCode ? 'Copied' : 'Copy'}</span>
              </button>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
};

export default Installation;
