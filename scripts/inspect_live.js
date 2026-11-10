const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');

async function inspectLive() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    '--user-data-dir=C:\\Users\\haris\\AppData\\Local\\Temp\\chrome-inspect-live',
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
      const networkFailures = [];

      ws.addEventListener('open', async () => {
        await send('Page.enable');
        await send('Runtime.enable');
        await send('Network.enable');

        ws.addEventListener('message', (evt) => {
          const msg = JSON.parse(evt.data);
          if (msg.method === 'Runtime.consoleAPICalled') {
            const text = (msg.params.args || []).map(a => a.value !== undefined ? a.value : (a.description || '')).join(' ');
            if (msg.params.type === 'error') {
              consoleErrors.push(text);
            } else {
              consoleLogs.push(`[${msg.params.type}] ${text}`);
            }
          }
          if (msg.method === 'Runtime.exceptionThrown') {
            consoleErrors.push('EXCEPTION: ' + JSON.stringify(msg.params.exceptionDetails));
          }
          if (msg.method === 'Network.loadingFailed') {
            networkFailures.push(`${msg.params.errorText}: ${msg.params.requestId}`);
          }
        });

        // Wait for page load and execution
        await new Promise(r => setTimeout(r, 6000));

        // Evaluate state
        const evalResult = await send('Runtime.evaluate', {
          expression: `({
            title: document.title,
            hash: window.location.hash,
            bodyText: document.body.innerText.substring(0, 500),
            kisanMapRegistry: window.kisanMapRegistry ? Object.keys(window.kisanMapRegistry) : 'missing',
            kisanDataStore: !!window.kisanDataStore,
            farmersCount: (window.kisanDataStore && window.kisanDataStore.getFarmers) ? window.kisanDataStore.getFarmers().length : 0,
            ordersCount: (window.kisanDataStore && window.kisanDataStore.getOrders) ? window.kisanDataStore.getOrders().length : 0,
            hasMapContainer: !!document.getElementById('executive-map'),
            activeRole: window.kisanRoleStore ? window.kisanRoleStore.getCurrentRole() : null
          })`,
          returnByValue: true
        });

        // Take a screenshot
        const screenshot = await send('Page.captureScreenshot', { format: 'png' });
        fs.writeFileSync('live_inspect_executive.png', Buffer.from(screenshot.data, 'base64'));

        console.log('--- CONSOLE LOGS ---');
        console.log(consoleLogs.join('\n'));
        console.log('--- CONSOLE ERRORS ---');
        console.log(consoleErrors.join('\n'));
        console.log('--- NETWORK FAILURES ---');
        console.log(networkFailures.join('\n'));
        console.log('--- PAGE STATE ---');
        console.log(JSON.stringify(evalResult ? evalResult.result.value : null, null, 2));

        chrome.kill();
        process.exit(0);
      });
    });
  });
}

inspectLive().catch(err => { console.error(err); process.exit(1); });
