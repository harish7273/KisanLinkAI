const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

const screenshotDir = path.join(__dirname, 'screenshots');
if (!fs.existsSync(screenshotDir)) {
  fs.mkdirSync(screenshotDir, { recursive: true });
}

async function testAllMaps() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    '--user-data-dir=C:\\Users\\haris\\AppData\\Local\\Temp\\chrome-all-maps-e2e',
    'http://localhost:8080/index.html'
  ]);

  await new Promise(r => setTimeout(r, 2000));

  http.get('http://127.0.0.1:9222/json/list', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', async () => {
      const tabs = JSON.parse(data);
      const tab = tabs.find(t => t.url.includes('8080'));
      if (!tab) { console.error('Tab not found'); chrome.kill(); return; }

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

      const consoleErrors = [];
      const networkRequests = [];

      ws.addEventListener('open', async () => {
        await send('Page.enable');
        await send('Runtime.enable');
        await send('Network.enable');

        ws.addEventListener('message', (evt) => {
          const msg = JSON.parse(evt.data);
          if (msg.method === 'Runtime.consoleAPICalled' && msg.params.type === 'error') {
            consoleErrors.push(msg.params.args.map(a => a.value || a.description).join(' '));
          }
          if (msg.method === 'Runtime.exceptionThrown') {
            consoleErrors.push(msg.params.exceptionDetails.exception ? (msg.params.exceptionDetails.exception.description || msg.params.exceptionDetails.text) : msg.params.exceptionDetails.text);
          }
          if (msg.method === 'Network.requestWillBeSent') {
            const url = msg.params.request.url;
            networkRequests.push(url);
          }
        });

        await new Promise(r => setTimeout(r, 1200));

        const testResults = [];

        async function verifyMap(testName, selector, minH = 200, filename = null) {
          await new Promise(r => setTimeout(r, 600));
          const res = await send('Runtime.evaluate', {
            expression: `(() => {
              const el = document.querySelector('${selector}');
              if (!el) return { found: false, error: 'Element ${selector} not found' };
              const rect = el.getBoundingClientRect();
              const hasLeaflet = !!el.querySelector('.leaflet-pane') || !!el.querySelector('.leaflet-container');
              const tiles = Array.from(el.querySelectorAll('.leaflet-tile')).map(t => t.src);
              const markers = el.querySelectorAll('.leaflet-marker-icon').length;
              const paths = el.querySelectorAll('path').length;
              const hasFallback = !!el.querySelector('svg text');
              return {
                found: true,
                width: rect.width,
                height: rect.height,
                hasLeaflet,
                tilesCount: tiles.length,
                markersCount: markers,
                pathsCount: paths,
                hasFallback,
                firstTileUrl: tiles[0] || 'none'
              };
            })()`,
            returnByValue: true
          });
          const val = res.result.value;
          const passed = val.found && val.width > 200 && val.height >= minH && (val.tilesCount > 0 || val.hasLeaflet || val.hasFallback);
          testResults.push({ testName, selector, passed, details: val });
          console.log(`[${passed ? 'PASS' : 'FAIL'}] ${testName}:`, val);

          if (filename) {
            const shot = await send('Page.captureScreenshot', { format: 'png' });
            if (shot && shot.data) {
              const outPath = path.join(screenshotDir, filename);
              fs.writeFileSync(outPath, Buffer.from(shot.data, 'base64'));
              console.log(`  --> Screenshot saved: ${filename}`);
            }
          }

          return passed;
        }

        // ==========================================
        // 0. ENTERPRISE LOGIN GATE
        // ==========================================
        console.log('\n--- 0. Testing Enterprise Login Gate ---');
        const loginCheck = await send('Runtime.evaluate', {
          expression: `(() => {
            const auth = document.getElementById('authScreen');
            return {
              authVisible: auth && auth.style.display !== 'none',
              hasEmailInput: !!document.getElementById('authEmailInput'),
              hasPassInput: !!document.getElementById('authPasswordInput')
            };
          })()`,
          returnByValue: true
        });
        console.log('Login gate check:', loginCheck.result.value);

        const shot0 = await send('Page.captureScreenshot', { format: 'png' });
        if (shot0 && shot0.data) {
          fs.writeFileSync(path.join(screenshotDir, '00_enterprise_login_gate.png'), Buffer.from(shot0.data, 'base64'));
          console.log('  --> Screenshot saved: 00_enterprise_login_gate.png');
        }

        // Authenticate via Quick Login
        await send('Runtime.evaluate', {
          expression: `window.quickLogin('super_admin')`
        });
        await new Promise(r => setTimeout(r, 600));

        // ==========================================
        // 1. SUPER ADMIN / HEAD MAPS
        // ==========================================
        console.log('\n--- 1. Testing Super Admin / Head Maps ---');
        await send('Runtime.evaluate', { expression: `window.navigateTo('#/admin/executive')` });
        await verifyMap("Super Admin Executive Map", "#adminMap", 350, "01_super_admin_executive_map.png");

        await send('Runtime.evaluate', { expression: `window.navigateTo('#/admin/settings')` });
        await verifyMap("Super Admin Platform Controls Regional Map", "#regionalCoverageMap", 350, "02_super_admin_regional_map.png");

        // Open Order Inspect Drawer
        await send('Runtime.evaluate', { expression: `window.inspectOrderAction('ORD-LIVE-01')` });
        await verifyMap("Order Dossier Drawer Mini-Map", "#orderInspectMap", 180, "03_order_dossier_drawer_map.png");
        await send('Runtime.evaluate', { expression: `window.closeDrawer('orderInspectDrawer')` });

        // Open KYC Drawer
        await send('Runtime.evaluate', { expression: `window.openKycDrawer('farmer_erod_001')` });
        await verifyMap("Farmer KYC Boundary Mini-Map", "#kycDrawerMap", 180, "04_kyc_boundary_drawer_map.png");
        await send('Runtime.evaluate', { expression: `window.closeDrawer('kycDrawer')` });

        // ==========================================
        // 2. OPERATIONS MANAGER MAPS
        // ==========================================
        console.log('\n--- 2. Testing Operations Manager Maps ---');
        await send('Runtime.evaluate', { expression: `window.kisanRoleStore.switchRole('ops_manager')` });
        await send('Runtime.evaluate', { expression: `window.navigateTo('#/admin/operations')` });
        await verifyMap("Operations Dispatch Telematics Map", "#adminMap", 350, "05_ops_manager_telematics_map.png");

        // Open Dispute Drawer
        await send('Runtime.evaluate', { expression: `window.openDisputeDrawer('DSP-2026-104')` });
        await verifyMap("Delivery Dispute GPS Audit Trail Map", "#disputeMap", 180, "06_delivery_dispute_audit_map.png");
        await send('Runtime.evaluate', { expression: `window.closeDrawer('disputeDrawer')` });

        // ==========================================
        // 3. SUPPORT AGENT MAPS
        // ==========================================
        console.log('\n--- 3. Testing Support Agent Maps ---');
        await send('Runtime.evaluate', { expression: `window.kisanRoleStore.switchRole('support_agent')` });
        await send('Runtime.evaluate', { expression: `window.navigateTo('#/admin/support')` });
        await send('Runtime.evaluate', { expression: `window.openSupportChatDrawer('TCK-2026-501')` });
        await verifyMap("Customer Support Ticket Telematics Mini-Map", "#supportChatMap", 160, "07_support_chat_telematics_map.png");
        await send('Runtime.evaluate', { expression: `window.closeDrawer('supportChatDrawer')` });

        // ==========================================
        // 4. QUALITY / AGRONOMIST MAPS
        // ==========================================
        console.log('\n--- 4. Testing Quality Officer Maps ---');
        await send('Runtime.evaluate', { expression: `window.kisanRoleStore.switchRole('quality_officer')` });
        await send('Runtime.evaluate', { expression: `window.navigateTo('#/admin/quality')` });
        await verifyMap("Quality Farm Harvest Origin Map", "#qualityOriginMap", 350, "08_quality_origin_harvest_map.png");

        // ==========================================
        // 5. FIELD VERIFICATION OFFICER MAPS
        // ==========================================
        console.log('\n--- 5. Testing Field Officer Maps ---');
        await send('Runtime.evaluate', { expression: `window.kisanRoleStore.switchRole('field_officer')` });
        await send('Runtime.evaluate', { expression: `window.navigateTo('#/admin/field-kyc?tab=map')` });
        await verifyMap("Field Land Parcels & Depots Map", "#fieldKycMap", 350, "09_field_parcels_depots_map.png");

        // ==========================================
        // 6. ROLE SWITCH BACK AND RE-INIT CHECK
        // ==========================================
        console.log('\n--- 6. Testing Return to Super Admin & Clean Re-Init ---');
        await send('Runtime.evaluate', { expression: `window.kisanRoleStore.switchRole('super_admin')` });
        await send('Runtime.evaluate', { expression: `window.navigateTo('#/admin/executive')` });
        await verifyMap("Super Admin Return Re-Init", "#adminMap", 350, "10_super_admin_return_reinit_map.png");

        // Check for any carto requests
        const cartoRequests = networkRequests.filter(u => u.includes('carto.com') || u.includes('cartocdn'));
        const osmRequests = networkRequests.filter(u => u.includes('tile.openstreetmap.org') || u.includes('openstreetmap.fr') || u.includes('openstreetmap.de'));
        console.log('\n--- TILE SECURITY AUDIT ---');
        console.log('Total Carto Network Requests:', cartoRequests.length);
        console.log('Total OSM Tile Requests:', osmRequests.length);
        if (cartoRequests.length > 0) {
          console.error('LEAKED CARTO REQUESTS:', cartoRequests);
        }

        console.log('Total Console Errors:', consoleErrors.length);
        if (consoleErrors.length > 0) {
          console.error('CONSOLE ERRORS:', consoleErrors);
        }

        const allPassed = testResults.every(t => t.passed) && cartoRequests.length === 0 && consoleErrors.length === 0;

        console.log('\n=============================================');
        console.log(`E2E SUITE RESULT: ${allPassed ? 'ALL PASSED (100% GREEN)' : 'SOME FAILED'}`);
        console.log(`Total Maps Verified: ${testResults.filter(t => t.passed).length} / ${testResults.length}`);
        console.log('=============================================');

        chrome.kill();
        process.exit(allPassed ? 0 : 1);
      });
    });
  });
}

testAllMaps();
