# GPE Neon Cloud (gpealgo.app)

Source for **https://gpealgo.app** — Neon Cloud web app.

## v6.5.7 — Join Kelas + Class Analytics

### What clients see
- On **History → Board**, Class / Webinar posts show **JOIN KELAS**
- Tap records attendance, then opens the **Google Meet** link

### What admins see
- **Settings → POST TO APP**: Class/Webinar requires a Google Meet URL
- **Settings → CLASS ANALYTICS**: live list of who joined (auto-refresh every 5s when maximized)

### Deploy (Cloudflare + Supabase — no GitHub required)

**1. Supabase**
- Open project → SQL Editor
- Paste & run [`sql/neon-cloud-v6.5.7-class-join.sql`](sql/neon-cloud-v6.5.7-class-join.sql)

**2. Cloudflare (static site for gpealgo.app)**
Upload / replace these files at the site root (Pages, R2 public bucket, or whatever currently serves the domain):

| File | Action |
|------|--------|
| `index.html` | replace (Join Kelas + Class Analytics) |
| `gpe/manifest.json` | replace (web version 6.5.7) |
| `site.webmanifest` | keep/replace |
| `gpe-logo.png` | keep |
| `sw.js` | keep/replace |
| `user-guide.html` | keep |
| `contest/borang-penyertaan.html` | keep |

**3. Cache**
- Cloudflare → Caching → Purge Everything for `gpealgo.app` (or purge `index.html`)
- On phone: close PWA / hard refresh so SW picks the new HTML

### Local preview
```bash
python3 -m http.server 8000 --bind 127.0.0.1
# open http://127.0.0.1:8000
```
