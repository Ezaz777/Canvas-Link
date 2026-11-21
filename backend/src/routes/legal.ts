import { AutoRouter } from 'itty-router';

export function registerLegalRoutes(router: ReturnType<typeof AutoRouter>) {
  // Account & Data Deletion Request Page (Google Play Store compliant)
  router.get('/delete-account', () => {
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Account & Data Deletion Request - Pinterest Auto Wallpaper</title>
  <style>
    :root {
      --bg: #0F172A;
      --card: #1E293B;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
      --primary: #E60023;
      --primary-hover: #CC001F;
      --border: #334155;
      --accent: #38BDF8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.6;
      padding: 32px 16px;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: flex-start;
    }
    .container {
      max-width: 720px;
      width: 100%;
      background: var(--card);
      border-radius: 16px;
      border: 1px solid var(--border);
      padding: 36px 32px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.4);
    }
    .header {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 24px;
      padding-bottom: 20px;
      border-bottom: 1px solid var(--border);
    }
    .logo-badge {
      width: 48px;
      height: 48px;
      background: var(--primary);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 900;
      font-size: 24px;
      color: white;
    }
    h1 { font-size: 24px; font-weight: 800; color: #FFFFFF; }
    .app-tag { font-size: 13px; color: var(--text-muted); font-weight: 500; }
    h2 { font-size: 18px; font-weight: 700; margin: 24px 0 10px 0; color: #F1F5F9; }
    p { margin-bottom: 12px; color: var(--text-muted); font-size: 15px; }
    ul, ol { margin: 10px 0 16px 20px; color: var(--text-muted); font-size: 15px; }
    li { margin-bottom: 6px; }
    .badge-box {
      background: rgba(230, 0, 35, 0.1);
      border: 1px solid rgba(230, 0, 35, 0.3);
      padding: 16px;
      border-radius: 10px;
      margin: 16px 0;
      color: #FECDD3;
      font-size: 14px;
    }
    .btn-action {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: var(--primary);
      color: white;
      text-decoration: none;
      padding: 12px 24px;
      border-radius: 9999px;
      font-weight: 600;
      font-size: 15px;
      margin-top: 10px;
      transition: background 0.2s;
    }
    .btn-action:hover { background: var(--primary-hover); }
    .contact-box {
      margin-top: 28px;
      padding-top: 20px;
      border-top: 1px solid var(--border);
      font-size: 13px;
      color: var(--text-muted);
    }
    code {
      background: #0F172A;
      padding: 2px 6px;
      border-radius: 4px;
      color: var(--accent);
      font-size: 13px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">P</div>
      <div>
        <h1>Account & Data Deletion Request</h1>
        <div class="app-tag">Pinterest Auto Wallpaper &bull; Package: com.wallpapersync.app</div>
      </div>
    </div>

    <div class="badge-box">
      <strong>Your Data Privacy:</strong> Pinterest Auto Wallpaper does not collect passwords, contacts, location, or private photos. We only store authorization tokens strictly to sync wallpapers from the boards you select.
    </div>

    <h2>1. What Data Will Be Deleted?</h2>
    <p>When you delete your account or request data removal, the following data is permanently purged:</p>
    <ul>
      <li>Your Pinterest OAuth access token and refresh token</li>
      <li>Your saved Pinterest user ID and profile nickname</li>
      <li>Selected board configuration (e.g., target boards, sync frequencies, screen targets)</li>
      <li>Sync history and wallpaper rotation offsets</li>
    </ul>

    <h2>2. How to Delete Your Account & Associated Data</h2>
    <p>You can delete your data through any of the following convenient methods:</p>

    <h3>Method A: Directly Inside the App (Instant)</h3>
    <ol>
      <li>Open the <strong>Pinterest Auto Wallpaper</strong> mobile app on your Android device.</li>
      <li>Tap the <strong>Settings (Gear) icon</strong> in the top header.</li>
      <li>Scroll to the bottom and tap <strong>"Log Out & Clear Local Data"</strong>.</li>
      <li>All local authentication tokens, cached board metadata, and wallpaper configurations are deleted immediately from your device.</li>
    </ol>

    <h3>Method B: Revoke Access via Pinterest (Immediate Token Invalidation)</h3>
    <ol>
      <li>Log in to your account at <a href="https://www.pinterest.com/settings/apps" target="_blank" style="color: var(--accent);">pinterest.com/settings/apps</a> (or open Pinterest App &rarr; Settings &rarr; Apps and Integrations).</li>
      <li>Find <strong>"Pinterest Auto Wallpaper"</strong> in your connected apps list.</li>
      <li>Click <strong>Revoke Access</strong>. This immediately destroys our authorization token and stops all background syncing.</li>
    </ol>

    <h3>Method C: Submit an Email Deletion Request</h3>
    <p>If you uninstalled the app or wish to request immediate manual deletion of all backend database records associated with your Pinterest account, email our support directly:</p>
    
    <a class="btn-action" href="mailto:info.ezazahmed@gmail.com?subject=Account%20and%20Data%20Deletion%20Request%20-%20Pinterest%20Auto%20Wallpaper&body=Hello,%0D%0A%0D%0APlease%20delete%20my%20account%20and%20all%20associated%20data%20for%20Pinterest%20Auto%20Wallpaper.%0D%0A%0D%0AMy%20Pinterest%20Username%20or%20Account%20Email:%20">
      Request Account Deletion via Email
    </a>
    <p style="margin-top: 10px; font-size: 13px;">Or email directly: <code>info.ezazahmed@gmail.com</code> with the subject <em>"Account and Data Deletion Request"</em>.</p>

    <h2>3. Data Retention Policy & Timeline</h2>
    <p>
      Requests are processed within <strong>24 to 48 hours</strong>. Upon verification, all database records, tokens, and metadata associated with your account are permanently deleted from our servers. We do not retain any residual copies or backups of deleted user data.
    </p>

    <div class="contact-box">
      <strong>Developer Contact:</strong><br>
      Ezaz Ahmed &bull; <a href="mailto:info.ezazahmed@gmail.com" style="color: var(--accent);">info.ezazahmed@gmail.com</a><br>
      Application: <em>Pinterest Auto Wallpaper</em> (Android)
    </div>
  </div>
</body>
</html>`;
    return new Response(html, {
      headers: { 'Content-Type': 'text/html; charset=utf-8' },
    });
  });

  // Privacy Policy Page
  router.get('/privacy', () => {
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy - Pinterest Auto Wallpaper</title>
  <style>
    :root {
      --bg: #0F172A;
      --card: #1E293B;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
      --primary: #E60023;
      --border: #334155;
      --accent: #38BDF8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.6;
      padding: 32px 16px;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: flex-start;
    }
    .container {
      max-width: 720px;
      width: 100%;
      background: var(--card);
      border-radius: 16px;
      border: 1px solid var(--border);
      padding: 36px 32px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.4);
    }
    h1 { font-size: 24px; font-weight: 800; color: #FFFFFF; margin-bottom: 6px; }
    .caption { font-size: 13px; color: var(--text-muted); margin-bottom: 24px; }
    h2 { font-size: 18px; font-weight: 700; margin: 20px 0 8px 0; color: #F1F5F9; }
    p { margin-bottom: 12px; color: var(--text-muted); font-size: 15px; }
    ul { margin: 10px 0 16px 20px; color: var(--text-muted); font-size: 15px; }
    li { margin-bottom: 6px; }
    a { color: var(--accent); }
  </style>
</head>
<body>
  <div class="container">
    <h1>Privacy Policy</h1>
    <div class="caption">Pinterest Auto Wallpaper &bull; Last updated: November 2026</div>

    <h2>1. Introduction</h2>
    <p>Welcome to Pinterest Auto Wallpaper. We are committed to protecting your privacy and giving you complete control over your data. This policy explains what information is processed when using our synchronization tools.</p>

    <h2>2. Information We Collect & Store</h2>
    <p>We collect only the bare minimum technical data necessary to query your Pinterest boards and set wallpapers:</p>
    <ul>
      <li><strong>No Passwords:</strong> We never see, ask for, or store your Pinterest password. Authentication is completed directly through Pinterest's official OAuth 2.0 flow.</li>
      <li><strong>Local Device Storage:</strong> Session tokens and board preferences are encrypted using AES-GCM and stored locally on your device.</li>
      <li><strong>Zero Behavioral Tracking:</strong> We do not track your browsing habits, record location, or sell personal data.</li>
    </ul>

    <h2>3. How We Use Data</h2>
    <p>Your OAuth access token is exclusively used to fetch board metadata and image URLs to apply as your background and rotate according to your schedule. We do not sell, rent, monetize, or distribute your information to any third party.</p>

    <h2>4. Advertising</h2>
    <p>This app displays non-intrusive advertisements provided by Google AdMob to keep all features 100% free for everyone. Google AdMob may collect standard device identifiers and diagnostics in accordance with Google's Privacy Policy.</p>

    <h2>5. Account & Data Deletion</h2>
    <p>Users may request complete deletion of their account and associated data at any time. For instructions, visit our <a href="/delete-account">Account Deletion Page</a> or email <a href="mailto:info.ezazahmed@gmail.com">info.ezazahmed@gmail.com</a>.</p>
  </div>
</body>
</html>`;
    return new Response(html, {
      headers: { 'Content-Type': 'text/html; charset=utf-8' },
    });
  });
}
