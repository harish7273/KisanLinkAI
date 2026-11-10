with open('admin-web/build_index.py', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Bump cache version to 20261110-v5
text = text.replace('v=20261107-v3', 'v=20261110-v5')

# 2. Update logout to record explicit logout in sessionStorage
old_logout = """      logout() {
        localStorage.removeItem(this.SESSION_KEY);
        window.location.hash = '';
        window.location.reload();
      }"""

new_logout = """      logout() {
        localStorage.removeItem(this.SESSION_KEY);
        sessionStorage.setItem('kisanai_explicit_logout', 'true');
        window.location.hash = '';
        window.location.reload();
      }"""
text = text.replace(old_logout, new_logout)

# 3. Clear explicit logout on login
old_login_success = """        localStorage.setItem(this.SESSION_KEY, JSON.stringify(session));
        return { success: true, session };"""

new_login_success = """        localStorage.setItem(this.SESSION_KEY, JSON.stringify(session));
        sessionStorage.removeItem('kisanai_explicit_logout');
        return { success: true, session };"""
text = text.replace(old_login_success, new_login_success)

# 4. Update bootstrapApp to auto-login in Demo mode if not explicitly logged out
old_bootstrap = """    function bootstrapApp() {
      if (!window.kisanAuth.isAuthenticated()) {
        const shell = document.getElementById('appShell');
        const auth = document.getElementById('authScreen');
        if (shell) shell.style.display = 'none';
        if (auth) auth.style.display = 'flex';
        return;
      }
      const shell = document.getElementById('appShell');
      const auth = document.getElementById('authScreen');
      if (auth) auth.style.display = 'none';
      if (shell) shell.style.display = 'flex';
      initRoleDropdown();
      renderActiveWorkspace();
    }"""

new_bootstrap = """    function bootstrapApp() {
      // Demo Mode: auto-authenticate default session unless explicitly signed out
      if (!window.kisanAuth.isAuthenticated()) {
        const explicitLogout = sessionStorage.getItem('kisanai_explicit_logout') === 'true';
        if (!explicitLogout) {
          window.kisanAuth.login('directorate@kisanai.in', 'KisanAI@2026');
        } else {
          const shell = document.getElementById('appShell');
          const auth = document.getElementById('authScreen');
          if (shell) shell.style.display = 'none';
          if (auth) auth.style.display = 'flex';
          return;
        }
      }
      const shell = document.getElementById('appShell');
      const auth = document.getElementById('authScreen');
      if (auth) auth.style.display = 'none';
      if (shell) shell.style.display = 'flex';
      initRoleDropdown();
      renderActiveWorkspace();
    }"""
text = text.replace(old_bootstrap, new_bootstrap)

with open('admin-web/build_index.py', 'w', encoding='utf-8') as f:
    f.write(text)

print('build_index.py updated successfully.')
