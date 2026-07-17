import React from 'react';
import { motion } from 'framer-motion';
import { 
  FastForward, 
  Zap,
  Sparkles,
  Cloud,
  Code2,
  HeartHandshake
} from 'lucide-react';

const Features = () => {
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
                <Sparkles size={40} className="text-gradient" />
              </div>
            </motion.div>
            <motion.h1 className="hero-title" variants={fadeInUp} style={{ fontSize: '3rem' }}>
              Canvas Link <span className="text-gradient">Features</span>
            </motion.h1>
            <motion.p className="hero-subtitle" variants={fadeInUp} style={{ fontSize: '1.2rem' }}>
              Discover the magic that powers your cross-platform wallpaper experience.
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
            {/* How It Works */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <Zap size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>The Stateless Deterministic Shuffle</h2>
              </div>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)', marginBottom: '1.5rem' }}>
                Canvas Link uses a highly advanced algorithm to select your daily wallpapers. 
                Instead of randomly picking an image (which inevitably leads to seeing the same image twice), the app builds a 
                mathematical cycle based on the exact number of pins on your board.
              </p>
              <ul style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)', paddingLeft: '1.5rem', marginBottom: '1.5rem' }}>
                <li style={{ marginBottom: '0.5rem' }}><strong>No Repeats Guarantee:</strong> If you have 50 pins, it guarantees you will see 50 unique wallpapers over 50 days before the cycle restarts.</li>
                <li style={{ marginBottom: '0.5rem' }}><strong>Dynamic Scaling:</strong> If you add 5 more pins to your Pinterest board, the algorithm instantly detects it and expands your cycle to 55 days dynamically!</li>
                <li style={{ marginBottom: '0.5rem' }}><strong>Perfect Sync:</strong> Because it relies purely on mathematics and dates, your PC and Mobile phone calculate the exact same image on the same day without needing to constantly talk to each other, saving your battery.</li>
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
                will automatically jump ahead the next time they sync in the background.
              </p>
            </div>

            {/* Cloud Backend */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <Cloud size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>Secure Cloud Backend</h2>
              </div>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                Powered by Cloudflare Workers and D1 Serverless SQL databases, the Canvas Link backend is built for speed and security. Your Pinterest OAuth tokens are heavily encrypted using AES-GCM before being stored, ensuring that your Pinterest account remains completely safe and private.
              </p>
            </div>

            {/* Open Source */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <Code2 size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>100% Free & Open Source</h2>
              </div>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                Unlike other wallpaper apps filled with subscriptions and ads, Canvas Link is totally free and open-source. Anyone can view the code, verify its security, or contribute to making the project even better on GitHub.
              </p>
            </div>

            {/* Developer Support */}
            <div className="glass-panel" style={{ padding: '3rem', borderRadius: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <HeartHandshake size={28} className="text-gradient" />
                <h2 style={{ fontSize: '2rem', margin: 0 }}>Support the Developer</h2>
              </div>
              <p style={{ fontSize: '1.1rem', lineHeight: '1.8', color: 'rgba(255,255,255,0.8)' }}>
                If you love the app and want to help cover the costs of the cloud servers, Canvas Link has a built-in Razorpay integration in the mobile dashboard. You can securely and easily drop a tip to keep the project alive!
              </p>
            </div>

          </motion.div>
        </div>
      </section>
    </div>
  );
};

export default Features;
