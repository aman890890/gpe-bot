# GPE Neon Cloud (gpealgo.app)

Source for **https://gpealgo.app** — Neon Cloud web app.

## v6.5.7 — Join Kelas + Class Analytics

### What clients see
- On **History → Board**, Class / Webinar posts show **JOIN KELAS**
- Tap records attendance, then opens the **Google Meet** link

### What admins see
- **Settings → POST TO APP**: Class/Webinar requires a Google Meet URL
- **Settings → CLASS ANALYTICS**: live list of who joined (auto-refresh every 5s when maximized)

### Deploy
1. Supabase → SQL Editor → run [`sql/neon-cloud-v6.5.7-class-join.sql`](sql/neon-cloud-v6.5.7-class-join.sql)
2. Upload / publish this folder’s `index.html` (and assets) to the host behind **gpealgo.app**
3. Hard refresh the app (or clear PWA cache)

### Local preview
```bash
python3 -m http.server 8000 --bind 127.0.0.1
# open http://127.0.0.1:8000
```
