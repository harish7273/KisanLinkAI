const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');

async function testLocalAdmin() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    '--user-data-dir=C:\\Users\\haris\\AppData\\Local\\Temp\\chrome-test-local-admin',
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

      const consoleEvents = [];

      ws.addEventListener('open', async () => {
        await send('Page.enable');
        await send('Runtime.enable');

        ws.addEventListener('message', (evt) => {
          const msg = JSON.parse(evt.data);
          if (msg.method === 'Runtime.consoleAPICalled') {
            consoleEvents.push(`[${msg.params.type}] ` + (msg.params.args || []).map(a => a.value || a.description).join(' '));
          }
          if (msg.method === 'Runtime.exceptionThrown') {
            consoleEvents.push(`[EXCEPTION] ` + JSON.stringify(msg.params.exceptionDetails));
          }
        });

        // Quick login as super_admin
        await send('Runtime.evaluate', {
          expression: `
            if (window.quickLogin) {
              window.quickLogin('super_admin');
            }
          `
        });

        await new Promise(r => setTimeout(r, 4000));

        // Evaluate state
        const state = await send('Runtime.evaluate', {
          expression: `({
            hash: window.location.hash,
            activeRole: window.kisanRoleStore ? window.kisanRoleStore.getCurrentRole() : null,
            kisanDataStore: typeof window.kisanDataStore,
            ordersCount: window.kisanDataStore ? window.kisanDataStore.getOrders().length : 0,
            farmersCount: window.kisanDataStore ? window.kisanDataStore.getFarmers().length : 0,
            executiveMapExists: !!document.getElementById('executive-map'),
            executiveMapChildren: document.getElementById('executive-map') ? document.getElementById('executive-map').children.length : 0,
            tablesCount: document.querySelectorAll('table').length,
            metricCardsCount: document.querySelectorAll('.metric-card').length,
            bodyTextSample: document.body.innerText.substring(0, 300)
          })`,
          returnByValue: true
        });

        const screenshot = await send('Page.captureScreenshot', { format: 'png' });
        fs.writeFileSync('local_admin_executive_after_fix.png', Buffer.from(screenshot.result.data, 'base64'));

        console.log('=== CONSOLE EVENTS ===');
        console.log(consoleEvents.join('\n'));
        console.log('=== EVALUATED STATE ===');
        console.log(JSON.stringify(state.result ? state.result.result.value : state, null, 2));

        chrome.kill();
        process.exit(0);
      });
    });
  });
}

testLocalAdmin().catch(err => { console.error(err); process.exit(1); });
