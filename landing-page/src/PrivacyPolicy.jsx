import React from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft, Shield } from 'lucide-react';
import { Link } from 'react-router-dom';

function PrivacyPolicy() {
  return (
    <div style={{ backgroundColor: 'var(--color-surface-soft)', minHeight: '100vh', padding: '48px 0 64px 0' }}>
      <div className="container" style={{ maxWidth: '840px' }}>
        <Link 
          to="/" 
          className="btn-tertiary" 
          style={{ marginBottom: '24px', display: 'inline-flex' }}
          onClick={() => window.scrollTo(0, 0)}
        >
          <ArrowLeft size={16} />
          <span>Back to Discovery Feed</span>
        </Link>

        <div className="feature-card-box" style={{ border: '1px solid var(--color-hairline-soft)', padding: '40px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
            <div style={{ width: '40px', height: '40px', borderRadius: 'var(--rounded-full)', backgroundColor: 'var(--color-surface-card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)' }}>
              <Shield size={20} />
            </div>
            <div>
              <h1 className="heading-xl">Privacy Policy</h1>
              <p className="caption-sm">Last updated: {new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}</p>
            </div>
          </div>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', marginTop: '24px' }}>
            <section>
              <h2 className="heading-md" style={{ marginBottom: '8px' }}>1. Introduction</h2>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Welcome to Canvas Link. We are committed to protecting your privacy and giving you complete control over your data. This policy explains what information is processed when using our synchronization tools.
              </p>
            </section>

            <section>
              <h2 className="heading-md" style={{ marginBottom: '8px' }}>2. Information We Collect & Store</h2>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                We collect only the bare minimum technical data necessary to query your Pinterest boards and set wallpapers:
              </p>
              <ul style={{ paddingLeft: '20px', marginTop: '8px', color: 'var(--color-mute)', lineHeight: '1.6' }}>
                <li><strong>No Passwords:</strong> We never see, ask for, or store your Pinterest password. Authentication is completed directly through Pinterest's official OAuth 2.0 flow.</li>
                <li><strong>Local Device Storage:</strong> Session tokens and board preferences are encrypted using AES-GCM and stored locally on your own PC and phone.</li>
                <li><strong>Zero Behavioral Tracking:</strong> We do not track your browsing habits, inject ads, or log analytics cookies.</li>
              </ul>
            </section>

            <section>
              <h2 className="heading-md" style={{ marginBottom: '8px' }}>3. How We Use Data</h2>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Your OAuth access token is exclusively used to:
              </p>
              <ul style={{ paddingLeft: '20px', marginTop: '8px', color: 'var(--color-mute)', lineHeight: '1.6' }}>
                <li>Fetch board metadata and image URLs to apply as your background.</li>
                <li>Advance the deterministic shuffle offset when you click "Skip Wallpaper".</li>
              </ul>
              <p className="body-md" style={{ color: 'var(--color-mute)', marginTop: '8px' }}>
                We do not sell, rent, monetize, or distribute your information to any third party.
              </p>
            </section>

            <section>
              <h2 className="heading-md" style={{ marginBottom: '8px' }}>4. Third-Party Services</h2>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Canvas Link interacts with the official Pinterest Developer API to fetch pins from boards you explicitly grant access to. Please refer to Pinterest's Privacy Policy regarding their data handling.
              </p>
            </section>

            <section>
              <h2 className="heading-md" style={{ marginBottom: '8px' }}>5. Security & Data Protection</h2>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Canvas Link adheres to industry-standard security practices. All authentication credentials are encrypted using platform security vaults (Windows Credential Locker and Android KeyStore), and we never sell, monetize, or track your personal usage data.
              </p>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}

export default PrivacyPolicy;
