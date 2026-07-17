import React from 'react';
import { motion } from 'framer-motion';
import { 
  BookOpen, 
  Monitor, 
  Smartphone, 
  FastForward, 
  RefreshCw,
  Zap,
  ShieldCheck,
  Download
} from 'lucide-react';

const Guide = () => {
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
                <BookOpen size={40} className="text-gradient" />
              </div>
            </motion.div>
            <motion.h1 className="hero-title" variants={fadeInUp} style={{ fontSize: '3rem' }}>
              Canvas Link <span className="text-gradient">User Guide</span>
            </motion.h1>
            <motion.p className="hero-subtitle" variants={fadeInUp} style={{ fontSize: '1.2rem' }}>
              Everything you need to know about the magic powering your daily wallpapers, from installation to advanced features.
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
            style={{ display: 'flex', flexDirection: 'column', gap: '3rem' }}
          >
            {/* How It Works */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <Zap size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>How the Magic Works</h2>
              </div>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)', marginBottom: '1.5rem' }}>
                Canvas Link uses a <strong>Stateless Deterministic Shuffle</strong> algorithm to select your daily wallpapers. 
                Instead of randomly picking an image (which inevitably leads to seeing the same image twice), the app builds a 
                mathematical cycle based on the exact number of pins on your board.
              </p>
              <ul style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)', paddingLeft: '1.5rem', marginBottom: '1.5rem' }}>
                <li style={{ marginBottom: '0.5rem' }}><strong>No Repeats:</strong> If you have 50 pins, it guarantees you will see 50 unique wallpapers over 50 days before the cycle restarts.</li>
                <li style={{ marginBottom: '0.5rem' }}><strong>Dynamic Scaling:</strong> If you add 5 more pins to your Pinterest board, the algorithm instantly detects it and expands your cycle to 55 days!</li>
                <li style={{ marginBottom: '0.5rem' }}><strong>Perfect Sync:</strong> Because it relies purely on mathematics and dates, your PC and Mobile phone calculate the exact same image on the same day without needing to constantly talk to each other.</li>
              </ul>
            </div>

            {/* Skipping */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <FastForward size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>The "Skip" Feature</h2>
              </div>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)', marginBottom: '1.5rem' }}>
                Not feeling today's vibe? You can easily skip it without breaking the cycle.
              </p>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                When you click <strong>"Skip Wallpaper"</strong> on either your PC or Mobile app, the backend securely increments a personalized offset for your account. 
                This literally fast-forwards your timeline by one day! Your current device will instantly refresh with tomorrow's image, and your other devices 
                will automatically jump ahead the next time they sync.
              </p>
            </div>

            {/* Installation PC */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <Monitor size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>PC Client Setup</h2>
              </div>
              <div style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                <ol style={{ paddingLeft: '1.5rem' }}>
                  <li style={{ marginBottom: '1rem' }}>Download the <code>Canvas Link.exe</code> from the dashboard.</li>
                  <li style={{ marginBottom: '1rem' }}>Run the executable. The settings window will appear.</li>
                  <li style={{ marginBottom: '1rem' }}>Click <strong>"Log In"</strong>. This will open your web browser to securely authenticate with Pinterest.</li>
                  <li style={{ marginBottom: '1rem' }}>Once logged in, check the box to <strong>"Enable Daily Sync at"</strong> and pick a time (e.g., 09:00 for 9 AM).</li>
                  <li style={{ marginBottom: '1rem' }}>The app will automatically inject a lightweight task into Windows Task Scheduler. It will run silently in the background every day without slowing down your PC!</li>
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
                  <li style={{ marginBottom: '1rem' }}>Install the Canvas Link Android app.</li>
                  <li style={{ marginBottom: '1rem' }}>Log in with Pinterest via the secure in-app browser.</li>
                  <li style={{ marginBottom: '1rem' }}>Go to the Settings menu (gear icon in the top right).</li>
                  <li style={{ marginBottom: '1rem' }}>Under <strong>Auto-Sync Frequency</strong>, choose how often you want the app to check for updates (e.g., Every 24 hours).</li>
                  <li style={{ marginBottom: '1rem' }}>The app uses Android's native <code>WorkManager</code>, which means it respects your battery life and only syncs when your phone is in an optimal state.</li>
                </ol>
              </div>
            </div>
            
            {/* Privacy */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px', marginBottom: '4rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <ShieldCheck size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>Privacy & Security</h2>
              </div>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                We believe your data is exactly that—yours. Canvas Link is entirely open-source, and our backend 
                uses industry-standard AES-GCM encryption to safely store your OAuth tokens. We only request read-only 
                access to your public boards and pins, and we never track your browsing data or sell your information.
              </p>
            </div>

          </motion.div>
        </div>
      </section>
    </div>
  );
};

export default Guide;
