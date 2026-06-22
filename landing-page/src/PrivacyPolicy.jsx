import React from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft } from 'lucide-react';

function PrivacyPolicy({ onBack }) {
  return (
    <motion.div 
      className="container section"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0 }}
      style={{ paddingTop: '8rem', minHeight: '100vh' }}
    >
      <button 
        onClick={onBack} 
        className="btn btn-secondary" 
        style={{ marginBottom: '2rem' }}
      >
        <ArrowLeft size={18} />
        Back to Home
      </button>

      <div className="glass-panel" style={{ padding: '3rem' }}>
        <h1 style={{ marginBottom: '2rem', fontSize: '2.5rem' }}>Privacy Policy</h1>
        
        <div style={{ color: 'var(--color-text-muted)', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <p>Last updated: {new Date().toLocaleDateString()}</p>
          
          <section>
            <h2 style={{ color: 'var(--color-text)', marginBottom: '0.5rem' }}>1. Introduction</h2>
            <p>Welcome to Canvas-Link ("we", "our", or "us"). We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about this privacy notice, or our practices with regards to your personal information, please contact us.</p>
          </section>

          <section>
            <h2 style={{ color: 'var(--color-text)', marginBottom: '0.5rem' }}>2. Information We Collect</h2>
            <p>We only collect the minimum amount of data necessary to provide you with the Canvas-Link synchronization service. We do not store your Pinterest password or any sensitive credentials. We use standard OAuth tokens securely encrypted and stored locally on your device to fetch your wallpapers.</p>
          </section>

          <section>
            <h2 style={{ color: 'var(--color-text)', marginBottom: '0.5rem' }}>3. How We Use Your Information</h2>
            <p>Your OAuth tokens and Pinterest data (like board IDs and images) are used strictly for:</p>
            <ul style={{ paddingLeft: '1.5rem', marginTop: '0.5rem' }}>
              <li>Fetching images to set as your device wallpaper.</li>
              <li>Managing the synchronization schedule you set up.</li>
            </ul>
            <p style={{ marginTop: '0.5rem' }}>We do not sell, rent, or share your data with any third parties.</p>
          </section>

          <section>
            <h2 style={{ color: 'var(--color-text)', marginBottom: '0.5rem' }}>4. Third-Party Services</h2>
            <p>Our app integrates with Pinterest via their official API and handles payments (donations) via Razorpay. Please refer to their respective Privacy Policies for how they handle your data.</p>
          </section>

          <section>
            <h2 style={{ color: 'var(--color-text)', marginBottom: '0.5rem' }}>5. Open Source</h2>
            <p>Canvas-Link is an open-source project. You can inspect all our code on GitHub to verify our data handling practices yourself!</p>
          </section>
        </div>
      </div>
    </motion.div>
  );
}

export default PrivacyPolicy;
