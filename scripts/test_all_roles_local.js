const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');

async function testAllRoles() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    '--user-data-dir=C:\\Users\\haris\\AppData\\Local\\Temp\\chrome-test-all-roles',
    'http://localhost:8080/index.html'
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

        // Test login
        await send('Runtime.evaluate', { expression: `if (window.quickLogin) window.quickLogin('super_admin');` });
        await new Promise(r => setTimeout(r, 1000));

        const rolesToTest = [
          { role: 'super_admin', route: '#/admin/executive' },
          { role: 'ops_manager', route: '#/admin/operations' },
          { role: 'support_agent', route: '#/admin/support' },
          { role: 'quality_officer', route: '#/admin/quality-desk' },
          { role: 'finance_officer', route: '#/admin/finance-desk' },
          { role: 'field_officer', route: '#/admin/field-desk' }
        ];

        const results = [];

        for (const test of rolesToTest) {
          await send('Runtime.evaluate', {
            expression: `window.kisanRoleStore.switchRole('${test.role}');`
          });
          await new Promise(r => setTimeout(r, 1500));

          const res = await send('Runtime.evaluate', {
            expression: `({
              role: window.kisanRoleStore.getRole(),
              hash: window.location.hash,
              contentLength: document.getElementById('workspaceView') ? document.getElementById('workspaceView').innerHTML.length : 0,
              hasHeading: !!document.querySelector('#workspaceView h2, #workspaceView h3'),
              headingText: document.querySelector('#workspaceView h2, #workspaceView h3') ? document.querySelector('#workspaceView h2, #workspaceView h3').innerText : 'NONE',
              tables: document.querySelectorAll('#workspaceView table').length,
              cards: document.querySelectorAll('#workspaceView .luxury-card, #workspaceView .metric-card').length,
              mapContainers: Array.from(document.querySelectorAll('#workspaceView [id*=\"map\"]')).map(el => el.id)
            })`,
            returnByValue: true
          });

          results.push(res.result ? (res.result.value || res.result) : null);
        }

        console.log('=== ROLE TEST RESULTS ===');
        console.log(JSON.stringify(results, null, 2));

        console.log('=== CONSOLE ERRORS ===');
        console.log(consoleErrors.length === 0 ? 'ZERO ERRORS' : consoleErrors.join('\n'));

        chrome.kill();
        process.exit(0);
      });
    });
  });
}

testAllRoles().catch(err => { console.error(err); process.exit(1); });
