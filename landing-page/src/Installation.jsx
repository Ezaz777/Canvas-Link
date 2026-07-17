import React from 'react';
import { motion } from 'framer-motion';
import { 
  Monitor, 
  Smartphone, 
  ShieldCheck,
  DownloadCloud
} from 'lucide-react';

const Installation = () => {
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
    <div style={{ paddingTop: '80px', minHeight: '100vh' }}>
      <section className="hero" style={{ padding: '6rem 0 3rem 0', minHeight: 'auto' }}>
        <div className="hero-bg-blob-1" style={{ opacity: 0.5 }}></div>
        <div className="hero-bg-blob-2" style={{ opacity: 0.5 }}></div>
        
        <div className="container">
          <motion.div 
            className="hero-content"
            initial="initial"
            animate="animate"
            variants={stagger}
            style={{ maxWidth: '800px', margin: '0 auto', textAlign: 'center' }}
          >
            <motion.div variants={fadeInUp} style={{ display: 'flex', justifyContent: 'center', marginBottom: '1.5rem' }}>
              <div style={{ 
                background: 'rgba(139, 92, 246, 0.2)', 
                padding: '1rem', 
                borderRadius: '20px',
                display: 'inline-block'
              }}>
                <DownloadCloud size={40} className="text-gradient" />
              </div>
            </motion.div>
            <motion.h1 className="hero-title" variants={fadeInUp} style={{ fontSize: '3rem' }}>
              Installation <span className="text-gradient">Guide</span>
            </motion.h1>
            <motion.p className="hero-subtitle" variants={fadeInUp} style={{ fontSize: '1.2rem' }}>
              Follow these simple steps to bring your Pinterest boards to your Windows and Android devices.
            </motion.p>
          </motion.div>
        </div>
      </section>

      <section className="section" style={{ paddingTop: '2rem' }}>
        <div className="container" style={{ maxWidth: '900px' }}>
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            style={{ display: 'flex', flexDirection: 'column', gap: '3rem', paddingBottom: '4rem' }}
          >

            {/* Installation PC */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <Monitor size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>PC Client Setup</h2>
              </div>
              <div style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                <ol style={{ paddingLeft: '1.5rem' }}>
                  <li style={{ marginBottom: '1rem' }}>Download the <code>Canvas Link.exe</code> from your dashboard.</li>
                  <li style={{ marginBottom: '1rem' }}>Run the executable. The Canvas Link Settings window will appear.</li>
                  <li style={{ marginBottom: '1rem' }}>Click <strong>"Log In"</strong>. This will automatically open your web browser to securely authenticate with Pinterest.</li>
                  <li style={{ marginBottom: '1rem' }}>Once you have successfully logged in, check the box to <strong>"Enable Daily Sync at"</strong> and select your preferred time from the dropdown (e.g., 09:00 for 9 AM).</li>
                  <li style={{ marginBottom: '1rem' }}>That's it! The app will automatically inject a lightweight task into the Windows Task Scheduler. It will run silently in the background every day without draining resources or slowing down your PC.</li>
                </ol>
              </div>
            </div>

            {/* Installation Mobile */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <Smartphone size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>Mobile App Setup</h2>
              </div>
              <div style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                <ol style={{ paddingLeft: '1.5rem' }}>
                  <li style={{ marginBottom: '1rem' }}>Install the Canvas Link Android app (APK available on the dashboard).</li>
                  <li style={{ marginBottom: '1rem' }}>Launch the app and tap "Log in with Pinterest" to authenticate via the secure in-app browser.</li>
                  <li style={{ marginBottom: '1rem' }}>Open the Settings menu by tapping the gear icon in the top right corner.</li>
                  <li style={{ marginBottom: '1rem' }}>Under <strong>Auto-Sync Frequency</strong>, choose how often you want the app to check for and apply updates (e.g., Every 24 hours).</li>
                  <li style={{ marginBottom: '1rem' }}>The app uses Android's native <code>WorkManager</code> technology. This ensures it completely respects your device's battery life and only syncs when your phone is in an optimal state.</li>
                </ol>
              </div>
            </div>
            
            {/* Privacy */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <ShieldCheck size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>Privacy & Security Guarantee</h2>
              </div>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                We believe your data is exactly that—yours. Canvas Link is entirely open-source, allowing anyone to verify our code. 
                Our backend relies on industry-standard AES-GCM encryption to safely store your OAuth tokens. We only request read-only 
                access to your public boards and pins; we never track your browsing data, serve ads, or sell your personal information.
              </p>
            </div>

          </motion.div>
        </div>
      </section>
    </div>
  );
};

export default Installation;
