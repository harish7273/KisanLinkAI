const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

async function testFreshVisitor() {
  const tempProfileDir = path.join('C:\\Users\\haris\\AppData\\Local\\Temp', 'chrome-fresh-' + Date.now());
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  
  console.log('Launching Chrome with fresh profile...');
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    `--user-data-dir=${tempProfileDir}`,
    'http://localhost:8080/index.html#/admin/executive'
  ]);

  await new Promise(r => setTimeout(r, 3000));

  http.get('http://127.0.0.1:9222/json/list', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', async () => {
      const tabs = JSON.parse(data);
      const tab = tabs.find(t => t.url.includes('8080'));
      if (!tab) {
        console.error('8080 tab not found.');
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
            resolve(msg);
          }
        };
        ws.addEventListener('message', handler);
        ws.send(JSON.stringify({ id: msgId, method, params }));
      });

      const consoleErrors = [];

      ws.addEventListener('open', async () => {
        await send('Page.enable');
        await send('Runtime.enable');

        ws.addEventListener('message', (evt) => {
          const msg = JSON.parse(evt.data);
          if (msg.method === 'Runtime.consoleAPICalled' && msg.params.type === 'error') {
            consoleErrors.push((msg.params.args || []).map(a => a.value || a.description).join(' '));
          }
          if (msg.method === 'Runtime.exceptionThrown') {
            consoleErrors.push('EXCEPTION: ' + JSON.stringify(msg.params.exceptionDetails));
          }
        });

        // Wait for page to initialize
        await new Promise(r => setTimeout(r, 4000));

        // Evaluate fresh visitor state without any manual login
        const state = await send('Runtime.evaluate', {
          expression: `({
            hash: window.location.hash,
            authScreenDisplay: document.getElementById('authScreen') ? document.getElementById('authScreen').style.display : 'none',
            appShellDisplay: document.getElementById('appShell') ? document.getElementById('appShell').style.display : 'none',
            activeRole: window.kisanRoleStore ? window.kisanRoleStore.getRole() : null,
            heading: document.querySelector('#workspaceView h2, #workspaceView h3') ? document.querySelector('#workspaceView h2, #workspaceView h3').innerText : 'NONE',
            metricCards: Array.from(document.querySelectorAll('.metric-card, .luxury-card h3, .metric-value')).map(el => el.innerText.trim()).filter(Boolean).slice(0, 8),
            mapTilesCount: document.querySelectorAll('.leaflet-tile-loaded').length,
            tableRows: document.querySelectorAll('table tbody tr').length,
            htmlLen: document.getElementById('workspaceView') ? document.getElementById('workspaceView').innerHTML.length : 0
          })`,
          returnByValue: true
        });

        // Capture screenshot
        const screenshot = await send('Page.captureScreenshot', { format: 'png' });
        fs.writeFileSync('fresh_visitor_executive.png', Buffer.from(screenshot.result.data, 'base64'));

        console.log('=== FRESH VISITOR STATE ===');
        console.log(JSON.stringify(state.result.value, null, 2));

        console.log('=== CONSOLE ERRORS ===');
        console.log(consoleErrors.length === 0 ? 'ZERO ERRORS' : consoleErrors.join('\n'));

        chrome.kill();
        process.exit(0);
      });
    });
  });
}

testFreshVisitor().catch(err => { console.error(err); process.exit(1); });
