const { spawn } = require('child_process');
const http = require('http');

async function testLiveAllRoles() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    '--user-data-dir=C:\\Users\\haris\\AppData\\Local\\Temp\\chrome-test-live-roles-' + Date.now(),
    'https://harish7273.github.io/KisanLinkAI/#/admin/executive'
  ]);

  await new Promise(r => setTimeout(r, 4000));

  http.get('http://127.0.0.1:9222/json/list', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', async () => {
      const tabs = JSON.parse(data);
      const tab = tabs.find(t => t.url.includes('KisanLinkAI') || t.url.includes('github.io'));
      if (!tab) {
        console.error('Tab not found.');
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

        await new Promise(r => setTimeout(r, 4000));

        const roles = ['super_admin', 'ops_manager', 'support_agent', 'quality_officer', 'finance_officer', 'field_officer'];
        const results = [];

        for (const role of roles) {
          await send('Runtime.evaluate', {
            expression: `window.kisanRoleStore.switchRole('${role}');`
          });
          await new Promise(r => setTimeout(r, 1500));

          const res = await send('Runtime.evaluate', {
            expression: `({
              role: window.kisanRoleStore.getRole(),
              hash: window.location.hash,
              contentLen: document.getElementById('workspaceView') ? document.getElementById('workspaceView').innerHTML.length : 0,
              heading: document.querySelector('#workspaceView h2, #workspaceView h3') ? document.querySelector('#workspaceView h2, #workspaceView h3').innerText : 'NO_HEADING'
            })`,
            returnByValue: true
          });

          results.push(res.result.result.value);
        }

        console.log('=== LIVE ROLES REPORT ===');
        console.log(JSON.stringify(results, null, 2));

        console.log('=== CONSOLE ERRORS ===');
        console.log(consoleErrors.length === 0 ? 'ZERO ERRORS' : consoleErrors.join('\n'));

        chrome.kill();
        process.exit(0);
      });
    });
  });
}

testLiveAllRoles().catch(err => { console.error(err); process.exit(1); });
