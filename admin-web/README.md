# KisanAI Enterprise Admin Web Dashboard

> High-governance, calm white administrative command console for statewide agricultural telematics, supply-chain settlements, AGMARK computer-vision quality audits, and field land parcel inspections.

---

## 1. Live Permanent Public URL
- **Public Production Link**: [https://harish7273.github.io/KisanLinkAI/](https://harish7273.github.io/KisanLinkAI/)
- **Hosting Tier**: GitHub Pages (Official Automated GitHub Actions Pipeline)
- **Availability**: 24/7/365 Always-On (Zero laptop / local server dependency)
- **SSL / Security**: Enforced HTTPS with Strict Session Authentication Gate

---

## 2. Authorized Demonstration Staff Accounts

To protect sensitive agricultural data and administrative controls, the public deployment requires authenticated session access. Use any of the following verified staff credentials:

| Administrative Role | Staff Email | Security Passcode | Scope & Permissions |
| :--- | :--- | :---: | :--- |
| **Directorate / Super Admin** | `directorate@kisanai.in` | `KisanAI@2026` | Full platform governance, GMV volume, RBAC, telematics, and audit ledger. |
| **Operations Manager** | `karthik.ops@kisanai.in` | `KisanAI@2026` | Live highway fleet dispatch, reefer temperature monitoring, and driver reassignment. |
| **Support Agent** | `divya.support@kisanai.in` | `KisanAI@2026` | Real-time dispute queue, SLA timers, customer order lookups, and support chat. |
| **Quality / Agronomist** | `priya.quality@kisanai.in` | `KisanAI@2026` | Computer vision scan oversight (HITL), AGMARK standards gate, and crop catalogue. |
| **Finance Officer** | `venkatesh.fin@kisanai.in` | `KisanAI@2026` | UPI/Bank settlement approvals, payouts ledger, and GST reconciliation. |
| **Field Verification Officer** | `anitha.field@kisanai.in` | `KisanAI@2026` | Cadastral land patta deeds verification, GPS coordinates, and vehicle RC audits. |

*(Quick-Access buttons are also provided on the login portal for one-click reviewer evaluation).*

---

## 3. Architecture & Key Features

- **Pure Client-Side Architecture**: Built with lightweight Vanilla ES6+, HTML5, and CSS3 custom properties matching the quiet-luxury design standard. Requires zero backend server or database instances to operate.
- **Unified Keyless Map Engine (`js/kisan-map.js`)**: Matches the mobile app (`APP/lib/widgets/live_map_widget.dart`). Powered by Leaflet 1.9.4 and standard OpenStreetMap tiles (`tile.openstreetmap.org`) with mirror failovers (`osmfr`, `osmde`, `hot`) and automatic SVG vector schematic fallback. ZERO CARTO watermarks and ZERO commercial SDK keys required.
- **Role-Based Access Control (RBAC)**: Centralized permission matrix (`js/role-store.js`) with locked route guards. In production (`ROLE_SWITCHER_MODE: "head-only"`), non-head roles cannot switch view contexts.
- **Trilingual Localization (`js/i18n.js`)**: Instant runtime language switching across Tamil (தமிழ்), English, and Hindi (हिन्दी).
- **Zero Emoji Policy**: Enforced via automated lint scanner (`scan_emojis.py`). All UI indicators utilize SVG icons.
- **SPA GitHub Pages Routing**: `404.html` fallback ensures direct URL refreshes and hash routes (`#/admin/...`) persist seamlessly.

---

## 4. Local Development & Testing

To run and preview the dashboard locally:

```bash
# 1. Navigate to the admin-web directory
cd admin-web

# 2. Start the local server
python server.py

# 3. Open in your browser:
# http://localhost:8080/index.html
```

### Running the End-to-End Test Suite

The automated headless Chrome test suite verifies all 10 maps across all 6 roles, the login gate, tile HTTP responses, and carto request elimination:

```bash
node test_all_maps_e2e.js
```

---

## 5. Deployment & CI/CD Pipeline

The dashboard automatically deploys to GitHub Pages on every push to the `main` or `web-deploy` branch via `.github/workflows/pages.yml`.

### Deployment Steps:
1. Automated workflow triggers on push.
2. Runs `scan_emojis.py` to ensure 0 pictographs in code.
3. Builds bundle and validates syntax via `build_index.py`.
4. Packages artifact and deploys directly to GitHub Pages CDN.
