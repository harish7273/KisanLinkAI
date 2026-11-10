const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');

async function inspectExecutiveAfterLogin() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    '--user-data-dir=C:\\Users\\haris\\AppData\\Local\\Temp\\chrome-inspect-exec',
    'https://harish7273.github.io/KisanLinkAI/#/admin/executive'
  ]);

  await new Promise(r => setTimeout(r, 4000));

  http.get('http://127.0.0.1:9222/json/list', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', async () => {
      let tabs = [];
      try { tabs = JSON.parse(data); } catch(e) { console.error('Failed to parse tabs:', data); chrome.kill(); return; }
      const tab = tabs.find(t => t.url.includes('KisanLinkAI') || t.url.includes('github.io'));
      if (!tab) {
        console.error('KisanLinkAI tab not found. Tabs:', tabs.map(t => t.url));
        chrome.kill();
        return;
      }

      const ws = new WebSocket(tab.webSocketDebuggerUrl);
      let id = 1;
      const send = (method, params = {}) => new Promise((resolve) => {
        const msgId = id++;
        const handler = (evt) => {
          const msg = JSON.parse(evt.data);
          if (msg.id === msgId) {
            ws.removeEventListener('message', handler);
            resolve(msg.result);
          }
        };
        ws.addEventListener('message', handler);
        ws.send(JSON.stringify({ id: msgId, method, params }));
      });

      const consoleLogs = [];
      const consoleErrors = [];

      ws.addEventListener('open', async () => {
        await send('Page.enable');
        await send('Runtime.enable');
        await send('Network.enable');

        ws.addEventListener('message', (evt) => {
          const msg = JSON.parse(evt.data);
          if (msg.method === 'Runtime.consoleAPICalled') {
            const text = (msg.params.args || []).map(a => a.value !== undefined ? String(a.value) : (a.description || '')).join(' ');
            if (msg.params.type === 'error') {
              consoleErrors.push(text);
            } else {
              consoleLogs.push(`[${msg.params.type}] ${text}`);
            }
          }
          if (msg.method === 'Runtime.exceptionThrown') {
            consoleErrors.push('EXCEPTION: ' + JSON.stringify(msg.params.exceptionDetails));
          }
        });

        // 1. Perform quickLogin as super_admin
        await send('Runtime.evaluate', {
          expression: `
            if (window.quickLogin) {
              window.quickLogin('super_admin');
            } else if (window.kisanAuth) {
              window.kisanAuth.login('superadmin@kisanai.in', 'KisanAI@2026');
              document.getElementById('authScreen').style.display = 'none';
              window.location.hash = '#/admin/executive';
            }
          `
        });

        await new Promise(r => setTimeout(r, 4000));

        // Evaluate state
        const state = await send('Runtime.evaluate', {
          expression: `({
            hash: window.location.hash,
            activeRole: window.kisanRoleStore ? window.kisanRoleStore.getCurrentRole() : null,
            visibleViews: Array.from(document.querySelectorAll('.view-panel')).filter(v => v.style.display !== 'none').map(v => v.id),
            kisanMaps: window.kisanMapRegistry ? Object.keys(window.kisanMapRegistry) : [],
            executiveMapHtml: document.getElementById('executive-map') ? document.getElementById('executive-map').innerHTML.length : 0,
            tablesCount: document.querySelectorAll('table').length,
            errorsOnPage: Array.from(document.querySelectorAll('*')).filter(el => (el.className && typeof el.className === 'string' && el.className.includes('error')) || (el.innerText && el.innerText.toLowerCase().includes('error'))).map(el => el.innerText.substring(0, 100))
          })`,
          returnByValue: true
        });

        // Take a screenshot
        const screenshot = await send('Page.captureScreenshot', { format: 'png' });
        fs.writeFileSync('logged_in_executive.png', Buffer.from(screenshot.data, 'base64'));

        console.log('=== CONSOLE LOGS ===');
        console.log(consoleLogs.join('\n'));
        console.log('=== CONSOLE ERRORS ===');
        console.log(consoleErrors.join('\n'));
        console.log('=== STATE ===');
        console.log(JSON.stringify(state.result.value, null, 2));

        chrome.kill();
        process.exit(0);
      });
    });
  });
}

inspectExecutiveAfterLogin().catch(err => { console.error(err); process.exit(1); });
