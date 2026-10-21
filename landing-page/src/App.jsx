import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Routes, Route, Link, useLocation } from 'react-router-dom';
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
  Search,
  Download,
  ExternalLink,
  ChevronRight,
  Menu,
  X,
  Heart,
  CheckCircle2,
  Sparkles,
  Layers,
  ArrowRight
} from 'lucide-react';

// Curated high-resolution Pinterest-style wallpaper pins
const WALLPAPER_PINS = [
  {
    id: 1,
    title: "Tokyo Shinjuku After Rain",
    category: "Tokyo Neon",
    tag: "Tokyo Neon",
    aspect: "portrait-tall",
    author: "Hiroshi Sato",
    authorAvatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=800&q=80",
    resolution: "4K UHD"
  },
  {
    id: 2,
    title: "Nordic Minimalist Daylight Studio",
    category: "Nordic Cozy",
    tag: "Nordic Living",
    aspect: "square",
    author: "Freja Lindqvist",
    authorAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=800&q=80",
    resolution: "OLED Ready"
  },
  {
    id: 3,
    title: "Misty Alpine Forest in Dawn",
    category: "Nature & Earthy",
    tag: "Earthy Warmth",
    aspect: "portrait-medium",
    author: "Elena Rostova",
    authorAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80",
    resolution: "5K Retina"
  },
  {
    id: 4,
    title: "Neo-Seoul Cyberpunk Passage",
    category: "Cyberpunk",
    tag: "Cyberpunk",
    aspect: "portrait-tall",
    author: "Min-Jun Kim",
    authorAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=800&q=80",
    resolution: "Ultra-Wide"
  },
  {
    id: 5,
    title: "Golden Hour Sahara Contours",
    category: "Minimalist 4K",
    tag: "Minimalist 4K",
    aspect: "portrait-medium",
    author: "Amira Zahra",
    authorAvatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80",
    resolution: "4K Wallpaper"
  },
  {
    id: 6,
    title: "Anime Floating Clouds & Cerulean Sky",
    category: "Anime & Studio Ghibli",
    tag: "Studio Ghibli",
    aspect: "portrait-tall",
    author: "Kenji Arai",
    authorAvatar: "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=800&q=80",
    resolution: "Vibrant HDR"
  },
  {
    id: 7,
    title: "Brutalist Concrete Geometry",
    category: "Dark AMOLED",
    tag: "Dark Mode",
    aspect: "portrait-tall",
    author: "Marcus Vane",
    authorAvatar: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=800&q=80",
    resolution: "Pure OLED"
  },
  {
    id: 8,
    title: "Pour-Over Coffee & Morning Pages",
    category: "Nordic Cozy",
    tag: "Cozy Aesthetic",
    aspect: "portrait-medium",
    author: "Chloe Dubois",
    authorAvatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80",
    resolution: "Warm Tone"
  },
  {
    id: 9,
    title: "Deep Cosmos Nebula & Starlight",
    category: "Dark AMOLED",
    tag: "Starlight Deep",
    aspect: "portrait-tall",
    author: "Dr. Neil Vance",
    authorAvatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=800&q=80",
    resolution: "Deep AMOLED"
  },
  {
    id: 10,
    title: "Pacific Coast Turquoise Crest",
    category: "Nature & Earthy",
    tag: "Ocean Solitude",
    aspect: "portrait-medium",
    author: "Kai Walker",
    authorAvatar: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
    resolution: "4K Landscape"
  },
  {
    id: 11,
    title: "Emerald Mountain Mirror Lake",
    category: "Nature & Earthy",
    tag: "Alpine Serenity",
    aspect: "portrait-tall",
    author: "Lucas Berg",
    authorAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80",
    resolution: "5K Panorama"
  },
  {
    id: 12,
    title: "Metropolis Glass & Sunset Reflections",
    category: "Minimalist 4K",
    tag: "Metropolis 4K",
    aspect: "portrait-tall",
    author: "Sarah Jenkins",
    authorAvatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=120&q=80",
    image: "https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80",
    resolution: "4K Desktop"
  }
];

const CATEGORIES = [
  "All",
  "Minimalist 4K",
  "Tokyo Neon",
  "Studio Ghibli",
  "Nature & Earthy",
  "Dark AMOLED",
  "Nordic Cozy"
];

function Home({ onOpenDownloadModal }) {
  const [activeCategory, setActiveCategory] = useState("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [syncedPin, setSyncedPin] = useState(null);

  const filteredPins = useMemo(() => {
    return WALLPAPER_PINS.filter(pin => {
      const matchesCategory = activeCategory === "All" || pin.category === activeCategory || pin.tag === activeCategory;
      const matchesSearch = searchQuery === "" || 
        pin.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
        pin.tag.toLowerCase().includes(searchQuery.toLowerCase()) ||
        pin.category.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    });
  }, [activeCategory, searchQuery]);

  const handleQuickSync = (pin, e) => {
    e.stopPropagation();
    setSyncedPin(pin.id);
    setTimeout(() => {
      setSyncedPin(null);
    }, 2500);
  };

  return (
    <>
      {/* Magazine Display Hero Section per DESIGN.md */}
      <section className="hero-wrapper">
        <div className="container">
          <div className="hero-header-box">
            <h1 className="display-xl">
              Create the wallpaper aesthetic you love every morning.
            </h1>
            <p className="hero-subheading">
              A photography-first wallpaper synchronization system that brings your curated Pinterest boards directly to your Windows desktop and Android screen automatically.
            </p>
            
            <div className="hero-cta-group">
              <button 
                className="btn-primary" 
                onClick={() => onOpenDownloadModal('windows')}
              >
                <Monitor size={18} />
                <span>Download for Windows</span>
              </button>
              
              <button 
                className="btn-secondary" 
                onClick={() => onOpenDownloadModal('android')}
              >
                <Smartphone size={18} />
                <span>Download for Android</span>
              </button>

              <Link to="/features" className="btn-tertiary">
                <span>Explore all features</span>
                <ChevronRight size={16} />
              </Link>
            </div>
          </div>

          {/* Interactive Discovery Filter Strip per DESIGN.md */}
          <div style={{ marginTop: '48px', marginBottom: '16px' }}>
            <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '8px', justifyContent: 'flex-start', scrollbarWidth: 'none' }}>
              {CATEGORIES.map(category => (
                <button
                  key={category}
                  className={`filter-chip ${activeCategory === category ? 'active' : ''}`}
                  onClick={() => setActiveCategory(category)}
                >
                  {category}
                </button>
              ))}
            </div>
          </div>

          {/* Masonry Pin Grid - Load Bearing Visual Element per DESIGN.md */}
          <div className="pin-grid">
            {filteredPins.map((pin) => (
              <div 
                key={pin.id} 
                className="pin-tile-wrapper"
                onClick={() => onOpenDownloadModal('quick-sync', pin)}
              >
                <img 
                  src={pin.image} 
                  alt={pin.title} 
                  className="pin-image"
                  loading="lazy"
                />

                {/* Always-visible Pinterest Overlay Pill per DESIGN.md */}
                <div style={{ position: 'absolute', top: '12px', left: '12px', zIndex: 2 }}>
                  <div className="pin-overlay-pill">
                    {pin.tag}
                  </div>
                </div>

                {/* Hover Interaction Overlay */}
                <div className="pin-hover-overlay">
                  <div className="pin-overlay-top">
                    <div></div>
                    <button 
                      className="btn-primary" 
                      style={{ height: '36px', padding: '6px 14px', borderRadius: '9999px', fontSize: '13px' }}
                      onClick={(e) => handleQuickSync(pin, e)}
                    >
                      {syncedPin === pin.id ? (
                        <>
                          <CheckCircle2 size={16} />
                          <span>Board Synced!</span>
                        </>
                      ) : (
                        <>
                          <RefreshCw size={14} />
                          <span>Sync Now</span>
                        </>
                      )}
                    </button>
                  </div>

                  <div className="pin-overlay-bottom">
                    <div className="pin-creator-tag">
                      <img src={pin.authorAvatar} alt={pin.author} className="pin-avatar" />
                      <span>{pin.author}</span>
                    </div>

                    <div className="btn-pill-on-image" style={{ padding: '4px 10px', fontSize: '12px' }}>
                      {pin.resolution}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {filteredPins.length === 0 && (
            <div style={{ textAlign: 'center', padding: '64px 0', backgroundColor: 'var(--color-surface-card)', borderRadius: 'var(--rounded-md)', margin: '24px 0' }}>
              <p className="heading-md" style={{ marginBottom: '8px' }}>No wallpapers matched your search.</p>
              <p className="body-sm">Try resetting the category filter or searching for another term.</p>
              <button 
                className="btn-secondary" 
                style={{ marginTop: '16px' }}
                onClick={() => { setActiveCategory("All"); setSearchQuery(""); }}
              >
                Reset filters
              </button>
            </div>
          )}
        </div>
      </section>

      {/* Alternating Feature Section 1 (Image Left, Text Right) per DESIGN.md */}
      <section className="section-block" style={{ backgroundColor: 'var(--color-canvas)' }}>
        <div className="container">
          <div className="feature-split-row">
            <div className="feature-image-card">
              <img 
                src="https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1000&q=80" 
                alt="Automatic Wallpaper Sync" 
              />
              <div style={{ position: 'absolute', bottom: '20px', left: '20px' }}>
                <span className="pin-overlay-pill" style={{ padding: '8px 16px', fontSize: '13px' }}>
                  Daily Sync at 07:00 AM
                </span>
              </div>
            </div>

            <div className="feature-card-box">
              <span style={{ color: 'var(--color-primary)', fontWeight: 700, fontSize: '14px', textTransform: 'uppercase', letterSpacing: '1px' }}>
                Automated Scheduler
              </span>
              <h2 className="heading-xl" style={{ margin: '12px 0 16px 0' }}>
                Wake up to brand new Pinterest art every morning.
              </h2>
              <p className="body-md" style={{ color: 'var(--color-mute)', marginBottom: '24px' }}>
                Never waste time searching for wallpapers again. Canvas Link connects directly to your boards, picks the highest resolution pins, and silently applies them to both your PC and smartphone at your chosen daily hour.
              </p>
              <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                <button className="btn-primary" onClick={() => onOpenDownloadModal('windows')}>
                  <span>Get Started</span>
                  <ArrowRight size={16} />
                </button>
                <Link to="/installation" className="btn-secondary">
                  <span>Setup Guide</span>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Alternating Feature Section 2 (Text Left, Image Right) per DESIGN.md */}
      <section className="section-block" style={{ backgroundColor: 'var(--color-surface-soft)' }}>
        <div className="container">
          <div className="feature-split-row">
            <div className="feature-card-box">
              <span style={{ color: 'var(--color-primary)', fontWeight: 700, fontSize: '14px', textTransform: 'uppercase', letterSpacing: '1px' }}>
                Privacy & Security
              </span>
              <h2 className="heading-xl" style={{ margin: '12px 0 16px 0' }}>
                Official Pinterest OAuth. Safe, private, and yours.
              </h2>
              <p className="body-md" style={{ color: 'var(--color-mute)', marginBottom: '24px' }}>
                Your credentials never touch our servers. We use standard, modern OAuth 2.0 through Pinterest's developer API. Your session tokens are encrypted and kept locally on your own machine.
              </p>
              <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '24px' }}>
                <li style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '15px', color: 'var(--color-ink)' }}>
                  <ShieldCheck size={18} color="var(--color-primary)" />
                  <span>No passwords requested or stored</span>
                </li>
                <li style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '15px', color: 'var(--color-ink)' }}>
                  <CheckCircle2 size={18} color="var(--color-primary)" />
                  <span>100% Free & Open-source client</span>
                </li>
                <li style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '15px', color: 'var(--color-ink)' }}>
                  <Battery size={18} color="var(--color-primary)" />
                  <span>Zero trackers, no battery-draining background loops</span>
                </li>
              </ul>
              <Link to="/privacy" className="link-inline">
                Read our full Privacy Policy →
              </Link>
            </div>

            <div className="feature-image-card">
              <img 
                src="https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=1000&q=80" 
                alt="Secure OAuth" 
              />
              <div style={{ position: 'absolute', bottom: '20px', right: '20px' }}>
                <span className="pin-overlay-pill" style={{ padding: '8px 16px', fontSize: '13px' }}>
                  Encrypted Local Storage
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Category Tiles ("Bring your favorite ideas to life" per DESIGN.md lines 489-492) */}
      <section className="section-block" style={{ backgroundColor: 'var(--color-canvas)' }}>
        <div className="container">
          <div style={{ textAlign: 'center', maxWidth: '720px', margin: '0 auto 40px auto' }}>
            <h2 className="heading-xl">Bring your favorite board themes to life</h2>
            <p className="body-md" style={{ color: 'var(--color-mute)', marginTop: '8px' }}>
              Choose specific boards for desktop ultra-wides or phone lockscreens.
            </p>
          </div>

          <div className="category-grid">
            <div className="category-tile-card" onClick={() => setActiveCategory("Minimalist 4K")}>
              <img 
                src="https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=150&q=80" 
                alt="Minimalist" 
                className="category-tile-thumb"
              />
              <div>
                <p className="body-strong">Minimalist 4K</p>
                <p className="body-sm">Clean lines, dunes, architecture</p>
              </div>
            </div>

            <div className="category-tile-card" onClick={() => setActiveCategory("Tokyo Neon")}>
              <img 
                src="https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=150&q=80" 
                alt="Tokyo Neon" 
                className="category-tile-thumb"
              />
              <div>
                <p className="body-strong">Tokyo & Cyberpunk</p>
                <p className="body-sm">Neon nights, rain, alleyways</p>
              </div>
            </div>

            <div className="category-tile-card" onClick={() => setActiveCategory("Nature & Earthy")}>
              <img 
                src="https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=150&q=80" 
                alt="Nature" 
                className="category-tile-thumb"
              />
              <div>
                <p className="body-strong">Earthy & Botanical</p>
                <p className="body-sm">Pine forests, lakes, mountains</p>
              </div>
            </div>

            <div className="category-tile-card" onClick={() => setActiveCategory("Studio Ghibli")}>
              <img 
                src="https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=150&q=80" 
                alt="Anime" 
                className="category-tile-thumb"
              />
              <div>
                <p className="body-strong">Studio Ghibli & Anime</p>
                <p className="body-sm">Pastel skies, trains, nostalgia</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works in 3 Steps */}
      <section className="section-block" style={{ backgroundColor: 'var(--color-surface-soft)' }}>
        <div className="container">
          <div style={{ textAlign: 'center', maxWidth: '720px', margin: '0 auto 40px auto' }}>
            <h2 className="heading-xl">How Canvas Link works in 3 simple steps</h2>
            <p className="body-md" style={{ color: 'var(--color-mute)', marginTop: '8px' }}>
              Set up once in 60 seconds and enjoy synchronized backgrounds forever.
            </p>
          </div>

          <div className="steps-grid">
            <div className="step-card">
              <div className="step-number-badge">1</div>
              <h3 className="heading-md">Connect your Pinterest</h3>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Authenticate securely through official Pinterest OAuth to view your public and private wallpaper boards.
              </p>
            </div>

            <div className="step-card">
              <div className="step-number-badge">2</div>
              <h3 className="heading-md">Assign boards to screens</h3>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Map a portrait aesthetic board to your Android phone and an ultra-wide board to your Windows setup.
              </p>
            </div>

            <div className="step-card">
              <div className="step-number-badge">3</div>
              <h3 className="heading-md">Sit back & enjoy</h3>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Every morning, native OS scheduler pulls a fresh pin and sets your wallpaper. No manual downloads needed.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Frequently Asked Questions */}
      <section className="section-block" style={{ backgroundColor: 'var(--color-canvas)' }}>
        <div className="container" style={{ maxWidth: '840px' }}>
          <div style={{ textAlign: 'center', marginBottom: '40px' }}>
            <h2 className="heading-xl">Frequently Asked Questions</h2>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div className="faq-card">
              <h3 className="heading-md" style={{ marginBottom: '8px' }}>Does this drain my PC or phone battery?</h3>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Not at all. Canvas Link does not run an idle resident loop. On Android, it leverages native WorkManager with network constraints; on Windows, it registers an optimized Task Scheduler event that exits immediately after applying the wallpaper.
              </p>
            </div>

            <div className="faq-card">
              <h3 className="heading-md" style={{ marginBottom: '8px' }}>What if I want to skip a wallpaper?</h3>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                You can easily click "Skip Wallpaper" on your client or web dashboard. It will instantly fast-forward to the next pin and sync across your devices.
              </p>
            </div>

            <div className="faq-card">
              <h3 className="heading-md" style={{ marginBottom: '8px' }}>Is Canvas Link free and open source?</h3>
              <p className="body-md" style={{ color: 'var(--color-mute)' }}>
                Yes! The entire project — the Windows client, Android client, and backend worker — is 100% open source under the MIT license on GitHub.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Hero CTA Strip per DESIGN.md lines 502-505 */}
      <div className="container" style={{ padding: '0 24px 64px 24px' }}>
        <div className="hero-cta-strip" style={{ borderRadius: 'var(--rounded-lg)' }}>
          <div>
            <h2 className="hero-cta-strip-title">
              Ready to wake up to your favorite Pinterest inspiration?
            </h2>
            <p style={{ color: 'var(--color-on-dark-mute)', marginTop: '8px', fontSize: '16px' }}>
              Download the free client today for Windows and Android.
            </p>
          </div>
          <button 
            className="btn-primary" 
            style={{ height: '48px', padding: '8px 24px', fontSize: '16px' }}
            onClick={() => onOpenDownloadModal('all')}
          >
            <span>Get Started for Free</span>
            <ArrowRight size={18} />
          </button>
        </div>
      </div>
    </>
  );
}

function App() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [downloadModal, setDownloadModal] = useState({ isOpen: false, platform: 'all', pin: null });
  const location = useLocation();

  const openDownloadModal = (platform = 'all', pin = null) => {
    setDownloadModal({ isOpen: true, platform, pin });
  };

  const closeDownloadModal = () => {
    setDownloadModal({ isOpen: false, platform: 'all', pin: null });
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* Primary Sticky Nav per DESIGN.md lines 508-515 */}
      <header className="primary-nav">
        <div className="container nav-inner">
          <div className="nav-left">
            <Link to="/" className="brand-wordmark">
              <div className="brand-badge-p">P</div>
              <span>Canvas Link</span>
            </Link>

            <nav className="desktop-nav-cluster" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Link to="/" className={`nav-link ${location.pathname === '/' ? 'active-link' : ''}`}>
                Explore
              </Link>
              <Link to="/features" className={`nav-link ${location.pathname === '/features' ? 'active-link' : ''}`}>
                Features
              </Link>
              <Link to="/installation" className={`nav-link ${location.pathname === '/installation' ? 'active-link' : ''}`}>
                Installation
              </Link>
              <Link to="/dashboard" className={`nav-link ${location.pathname === '/dashboard' ? 'active-link' : ''}`}>
                Dashboard
              </Link>
            </nav>
          </div>

          {/* Search Bar centered per DESIGN.md lines 471-475 */}
          <div className="search-bar-container">
            <Search size={18} className="search-icon-nav" />
            <input 
              type="text" 
              placeholder="Search for wallpapers, aesthetics, anime..." 
              className="search-bar"
              onClick={() => {
                if (location.pathname !== '/') {
                  window.location.href = '/';
                }
              }}
            />
          </div>

          <div className="nav-right">
            <a 
              href="https://github.com/Ezaz777/Canvas-Link" 
              target="_blank" 
              rel="noreferrer"
              className="btn-secondary desktop-nav-cluster"
              style={{ height: '36px' }}
            >
              <span>GitHub</span>
              <ExternalLink size={14} />
            </a>

            {/* Always-Red Sign Up / Download CTA per DESIGN.md line 298 */}
            <button 
              className="btn-primary"
              onClick={() => openDownloadModal('all')}
            >
              <Download size={16} />
              <span>Download</span>
            </button>

            <button 
              className="mobile-nav-toggle"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              aria-label="Toggle navigation menu"
            >
              {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Nav Drawer */}
      {isMobileMenuOpen && (
        <div className="mobile-nav-dropdown">
          <Link to="/" className="nav-link" onClick={() => setIsMobileMenuOpen(false)}>
            Explore Wallpapers
          </Link>
          <Link to="/features" className="nav-link" onClick={() => setIsMobileMenuOpen(false)}>
            Features
          </Link>
          <Link to="/installation" className="nav-link" onClick={() => setIsMobileMenuOpen(false)}>
            Installation Guide
          </Link>
          <Link to="/dashboard" className="nav-link" onClick={() => setIsMobileMenuOpen(false)}>
            Dashboard
          </Link>
          <a 
            href="https://github.com/Ezaz777/Canvas-Link" 
            target="_blank" 
            rel="noreferrer" 
            className="nav-link"
            onClick={() => setIsMobileMenuOpen(false)}
          >
            GitHub Repository ↗
          </a>
        </div>
      )}

      {/* Main Content Area */}
      <main style={{ flex: 1 }}>
        <Routes>
          <Route path="/" element={<Home onOpenDownloadModal={openDownloadModal} />} />
          <Route path="/features" element={<Features onOpenDownloadModal={openDownloadModal} />} />
          <Route path="/installation" element={<Installation />} />
          <Route path="/privacy" element={<PrivacyPolicy />} />
          <Route path="/dashboard" element={<Dashboard />} />
        </Routes>
      </main>

      {/* 4-Column Footer per DESIGN.md lines 518-522 */}
      <footer className="footer-section">
        <div className="container">
          <div className="footer-columns-grid">
            <div>
              <h4 className="footer-col-header">Get the App</h4>
              <ul className="footer-links-list">
                <li><a href="#" onClick={(e) => { e.preventDefault(); openDownloadModal('windows'); }}>Windows Client (.exe)</a></li>
                <li><a href="#" onClick={(e) => { e.preventDefault(); openDownloadModal('android'); }}>Android App (.apk)</a></li>
                <li><a href="https://github.com/Ezaz777/Canvas-Link/releases" target="_blank" rel="noreferrer">Release Notes</a></li>
                <li><Link to="/installation">Step-by-step Setup</Link></li>
              </ul>
            </div>

            <div>
              <h4 className="footer-col-header">Quick Links</h4>
              <ul className="footer-links-list">
                <li><Link to="/">Explore Feed</Link></li>
                <li><Link to="/features">Core Features</Link></li>
                <li><Link to="/dashboard">Sync Dashboard</Link></li>
                <li><a href="https://pinterest.com" target="_blank" rel="noreferrer">Pinterest.com ↗</a></li>
              </ul>
            </div>

            <div>
              <h4 className="footer-col-header">Technology</h4>
              <ul className="footer-links-list">
                <li><a href="https://github.com/Ezaz777/Canvas-Link" target="_blank" rel="noreferrer">Open Source (MIT)</a></li>
                <li><span>Cloudflare Workers Backend</span></li>
                <li><span>Pinterest REST API</span></li>
                <li><span>Local SQLite Storage</span></li>
              </ul>
            </div>

            <div>
              <h4 className="footer-col-header">About & Legal</h4>
              <ul className="footer-links-list">
                <li><Link to="/privacy">Privacy Policy</Link></li>
                <li><a href="https://github.com/Ezaz777/Canvas-Link/issues" target="_blank" rel="noreferrer">Report an Issue</a></li>
                <li><a href="https://github.com/Ezaz777/Canvas-Link" target="_blank" rel="noreferrer">GitHub Repository</a></li>
                <li><span>Built for Pinterest lovers</span></li>
              </ul>
            </div>
          </div>

          <div className="footer-bottom-row">
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <div className="brand-badge-p" style={{ width: '24px', height: '24px', fontSize: '13px' }}>P</div>
              <span style={{ fontWeight: 700, color: 'var(--color-ink)', fontSize: '14px' }}>Canvas Link</span>
            </div>
            <p className="caption-sm">
              © {new Date().getFullYear()} Canvas Link. Open source project inspired by Pinterest design system.
            </p>
          </div>
        </div>
      </footer>

      {/* Modal Card Overlay per DESIGN.md lines 497-500 */}
      <AnimatePresence>
        {downloadModal.isOpen && (
          <div className="modal-scrim" onClick={closeDownloadModal}>
            <motion.div 
              className="modal-card"
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              transition={{ duration: 0.2 }}
              onClick={(e) => e.stopPropagation()}
            >
              <button 
                className="btn-icon-circular modal-close-btn"
                onClick={closeDownloadModal}
                aria-label="Close modal"
              >
                <X size={20} />
              </button>

              <div style={{ textAlign: 'center', marginBottom: '24px' }}>
                <div className="brand-badge-p" style={{ width: '48px', height: '48px', fontSize: '24px', margin: '0 auto 16px auto' }}>
                  P
                </div>
                <h3 className="heading-lg">Get Canvas Link</h3>
                <p className="body-sm" style={{ marginTop: '6px' }}>
                  Choose your platform to start daily wallpaper synchronization.
                </p>
              </div>

              {downloadModal.pin && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', backgroundColor: 'var(--color-surface-card)', borderRadius: 'var(--rounded-md)', marginBottom: '20px' }}>
                  <img src={downloadModal.pin.image} alt={downloadModal.pin.title} style={{ width: '48px', height: '48px', borderRadius: 'var(--rounded-sm)', objectFit: 'cover' }} />
                  <div>
                    <p className="body-strong" style={{ fontSize: '14px' }}>{downloadModal.pin.title}</p>
                    <span className="caption-sm">Tag: {downloadModal.pin.tag}</span>
                  </div>
                </div>
              )}

              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <a 
                  href="https://github.com/Ezaz777/Canvas-Link/releases" 
                  target="_blank" 
                  rel="noreferrer"
                  className="btn-primary"
                  style={{ height: '44px', textDecoration: 'none' }}
                >
                  <Monitor size={18} />
                  <span>Download Windows Client (.exe)</span>
                </a>

                <a 
                  href="https://github.com/Ezaz777/Canvas-Link/releases" 
                  target="_blank" 
                  rel="noreferrer"
                  className="btn-secondary"
                  style={{ height: '44px', textDecoration: 'none' }}
                >
                  <Smartphone size={18} />
                  <span>Download Android App (.apk)</span>
                </a>

                <Link 
                  to="/installation" 
                  className="btn-tertiary"
                  style={{ justifyContent: 'center', marginTop: '8px' }}
                  onClick={closeDownloadModal}
                >
                  <span>View Installation Guide</span>
                  <ChevronRight size={16} />
                </Link>
              </div>

              <div style={{ textAlign: 'center', marginTop: '20px', borderTop: '1px solid var(--color-hairline-soft)', paddingTop: '16px' }}>
                <p className="caption-sm">
                  100% Free & Open Source · No Ads · Secure OAuth
                </p>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default App;
