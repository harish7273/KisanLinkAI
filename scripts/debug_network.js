const { spawn } = require('child_process');
const http = require('http');

async function debugNetwork() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    '--user-data-dir=C:\\Users\\haris\\AppData\\Local\\Temp\\chrome-debug-net',
    'https://harish7273.github.io/KisanLinkAI/'
  ]);

  await new Promise(r => setTimeout(r, 3000));

  http.get('http://127.0.0.1:9222/json/list', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', async () => {
      const tabs = JSON.parse(data);
      const tab = tabs.find(t => t.url.includes('KisanLinkAI') || t.url.includes('github.io'));
      if (!tab) {
        console.error('KisanLinkAI tab not found.');
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

      const responses = [];
      const failures = [];
      const consoleEvents = [];

      ws.addEventListener('open', async () => {
        await send('Page.enable');
        await send('Runtime.enable');
        await send('Network.enable');

        ws.addEventListener('message', (evt) => {
          const msg = JSON.parse(evt.data);
          if (msg.method === 'Network.responseReceived') {
            responses.push(`${msg.params.response.status} ${msg.params.response.url}`);
          }
          if (msg.method === 'Network.loadingFailed') {
            failures.push(`FAILED: ${msg.params.errorText} ${msg.params.requestId}`);
          }
          if (msg.method === 'Runtime.consoleAPICalled') {
            consoleEvents.push(`[CONSOLE ${msg.params.type}] ` + (msg.params.args || []).map(a => a.value || a.description).join(' '));
          }
          if (msg.method === 'Runtime.exceptionThrown') {
            consoleEvents.push(`[EXCEPTION] ` + JSON.stringify(msg.params.exceptionDetails));
          }
        });

        // Reload page to catch all network requests from beginning
        await send('Page.reload');

        await new Promise(r => setTimeout(r, 6000));

        console.log('=== NETWORK RESPONSES ===');
        console.log(responses.join('\n'));
        console.log('=== NETWORK FAILURES ===');
        console.log(failures.join('\n'));
        console.log('=== CONSOLE EVENTS ===');
        console.log(consoleEvents.join('\n'));

        // Check global variables
        const globals = await send('Runtime.evaluate', {
          expression: `({
            L: typeof L,
            Chart: typeof Chart,
            KI_SEED_DATA: typeof window.KI_SEED_DATA,
            kisanDataStore: typeof window.kisanDataStore,
            kisanMapRegistry: typeof window.kisanMapRegistry,
            kisanRoleStore: typeof window.kisanRoleStore,
            kisanAuth: typeof window.kisanAuth,
            documentReady: document.readyState
          })`,
          returnByValue: true
        });

        console.log('=== GLOBALS ===');
        console.log(JSON.stringify(globals.result ? globals.result.result.value : globals, null, 2));

        chrome.kill();
        process.exit(0);
      });
    });
  });
}

debugNetwork().catch(err => { console.error(err); process.exit(1); });
