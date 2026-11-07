# KisanAI Admin Web Dashboard — Deployment & Hosting Guide

## 1. Hosting Architecture Overview
- **Live URL**: [https://harish7273.github.io/KisanLinkAI/](https://harish7273.github.io/KisanLinkAI/)
- **Repository**: [https://github.com/harish7273/KisanLinkAI.git](https://github.com/harish7273/KisanLinkAI.git)
- **Deployment Folder**: `/admin-web`
- **Hosting Provider**: GitHub Pages (Free Tier on Public Repo)
- **Deployment Automation**: GitHub Actions (`.github/workflows/pages.yml`)

---

## 2. Enabling GitHub Pages on the Repository (One-Time Setup)

If GitHub Pages is not already active on the repository:

1. Open the repository on GitHub: [https://github.com/harish7273/KisanLinkAI/settings/pages](https://github.com/harish7273/KisanLinkAI/settings/pages)
2. Under **Build and deployment**:
   - **Source**: Select **GitHub Actions** from the dropdown menu.
3. Save changes.
4. Any push to `main` or `web-deploy` will immediately trigger the workflow under the **Actions** tab and publish the site.

---

## 3. How to Roll Back to a Previous Version

If a deployment needs to be rolled back to an earlier stable state:

### Method A: Via GitHub Web UI (Instant)
1. Go to **Actions** tab on GitHub: [https://github.com/harish7273/KisanLinkAI/actions](https://github.com/harish7273/KisanLinkAI/actions)
2. Select a previous successful run of **Deploy Admin Web Dashboard to GitHub Pages**.
3. Click **Re-run all jobs**. GitHub Pages will re-deploy that exact artifact immediately.

### Method B: Via Git Revert
```bash
git checkout main
git revert <commit-hash-to-revert>
git push origin main
```
The automated GitHub Actions workflow will trigger and redeploy the reverted version within 60 seconds.

---

## 4. How to Attach a Custom Domain (Optional)

To serve the dashboard at a custom domain (e.g. `admin.kisanai.in`):

1. **DNS Configuration**:
   - Add a `CNAME` record in your DNS provider:
     - **Host**: `admin`
     - **Value**: `harish7273.github.io`
2. **GitHub Repository Settings**:
   - Go to [https://github.com/harish7273/KisanLinkAI/settings/pages](https://github.com/harish7273/KisanLinkAI/settings/pages)
   - In **Custom domain**, enter `admin.kisanai.in`.
   - Click **Save**.
   - Check **Enforce HTTPS** (issued automatically via Let's Encrypt).
3. **Commit CNAME**:
   - Add a file named `CNAME` containing `admin.kisanai.in` into `admin-web/CNAME`.
