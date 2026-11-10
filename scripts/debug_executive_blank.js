const { spawn } = require('child_process');
const http = require('http');

async function debugBlank() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    '--user-data-dir=C:\\Users\\haris\\AppData\\Local\\Temp\\chrome-debug-blank',
    'https://harish7273.github.io/KisanLinkAI/#/admin/executive'
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

      const logs = [];

      ws.addEventListener('open', async () => {
        await send('Page.enable');
        await send('Runtime.enable');

        ws.addEventListener('message', (evt) => {
          const msg = JSON.parse(evt.data);
          if (msg.method === 'Runtime.consoleAPICalled') {
            logs.push(`CONSOLE [${msg.params.type}]: ` + (msg.params.args || []).map(a => a.value || a.description).join(' '));
          }
          if (msg.method === 'Runtime.exceptionThrown') {
            logs.push(`EXCEPTION: ` + JSON.stringify(msg.params.exceptionDetails));
          }
        });

        // Quick login as super_admin
        await send('Runtime.evaluate', {
          expression: `
            if (window.quickLogin) window.quickLogin('super_admin');
          `
        });

        await new Promise(r => setTimeout(r, 2000));

        // Now evaluate router and view elements
        const r1 = await send('Runtime.evaluate', {
          expression: `
            (() => {
              const res = {};
              res.hash = window.location.hash;
              res.mainContent = document.getElementById('mainContent') ? document.getElementById('mainContent').outerHTML.substring(0, 500) : 'NO_MAIN_CONTENT';
              res.allViewPanels = Array.from(document.querySelectorAll('.view-panel, [id$=\"View\"], [id$=\"-view\"]')).map(el => ({
                id: el.id,
                display: el.style.display,
                classList: Array.from(el.classList),
                htmlLen: el.innerHTML.length
              }));
              res.routerCurrent = window.location.hash;
              res.kisanDataStore = !!window.kisanDataStore;
              return JSON.stringify(res);
            })()
          `,
          returnByValue: true
        });

        console.log('--- LOGS & EXCEPTIONS ---');
        console.log(logs.join('\n'));

        console.log('--- ROUTER & VIEWS ---');
        console.log(r1.result ? r1.result.result.value : r1);

        chrome.kill();
        process.exit(0);
      });
    });
  });
}

debugBlank().catch(err => { console.error(err); process.exit(1); });
