// Smoke-test a built Flutter web app in a disposable headless Chrome profile.
// Node 22+ (built-in WebSocket), no npm dependencies. No login or production writes.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, mkdtemp, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { resolve, join, sep, extname } from 'node:path';
import { tmpdir } from 'node:os';

const root = resolve('build/web');
await readFile(join(root, 'index.html'));
const mime = {'.html':'text/html', '.js':'application/javascript', '.json':'application/json',
  '.wasm':'application/wasm', '.png':'image/png', '.svg':'image/svg+xml', '.css':'text/css',
  '.ttf':'font/ttf', '.otf':'font/otf'};
const server = createServer(async (req, res) => {
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    if (pathname === '/favicon.ico') { res.writeHead(204); res.end(); return; }
    const file = resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
    if (!file.startsWith(root + sep)) { res.writeHead(403); res.end(); return; }
    const data = await readFile(file);
    res.writeHead(200, {'Content-Type':mime[extname(file)] || 'application/octet-stream'});
    res.end(data);
  } catch { res.writeHead(404); res.end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const profile = await mkdtemp(join(tmpdir(), 'prm-web-smoke-'));
const chromePath = process.env.CHROME_EXECUTABLE ||
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const browser = spawn(chromePath, ['--headless=new', '--no-first-run',
  '--no-default-browser-check', '--disable-extensions', '--disable-background-networking',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank'],
  {windowsHide:true,stdio:'ignore'});
let browserError;
browser.on('error', error => { browserError = error; });
let socket;
let sequence = 0;
const pending = new Map();
const errors = [];
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function waitFor(action, description) {
  for (let attempt = 0; attempt < 150; attempt++) {
    if (browserError) throw browserError;
    try { const result = await action(); if (result) return result; } catch {}
    await delay(400);
  }
  throw Error(`Timed out waiting for ${description}`);
}
function command(method, params = {}) {
  const id = ++sequence;
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => { pending.delete(id); reject(Error(`CDP timeout: ${method}`)); },15000);
    pending.set(id, {resolve, reject, timeout});
    socket.send(JSON.stringify({id,method,params}));
  });
}
async function evaluate(expression) {
  const result = await command('Runtime.evaluate', {expression,returnByValue:true});
  if (result.exceptionDetails) throw Error(result.exceptionDetails.text);
  return result.result.value;
}
try {
  const port = await waitFor(async () => (await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0], 'Chrome debug port');
  const pages = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  socket = new WebSocket(pages.find(page => page.type === 'page').webSocketDebuggerUrl);
  await new Promise((resolve,reject) => { socket.onopen = resolve; socket.onerror = reject; });
  socket.onmessage = event => {
    const message = JSON.parse(event.data);
    const task = pending.get(message.id);
    if (task) {
      clearTimeout(task.timeout);
      pending.delete(message.id);
      if (message.error) task.reject(Error(message.error.message)); else task.resolve(message.result);
    }
    if (message.method === 'Runtime.exceptionThrown') {
      const detail = message.params.exceptionDetails;
      errors.push(detail.exception?.description || detail.text);
    }
    if (message.method === 'Log.entryAdded' && message.params.entry.level === 'error') {
      errors.push(message.params.entry.text + ' ' + (message.params.entry.url || ''));
    }
  };
  await command('Runtime.enable');
  await command('Log.enable');
  await command('Page.enable');
  await command('Accessibility.enable');
  const origin = `http://127.0.0.1:${server.address().port}`;
  await command('Page.navigate',{url:origin});
  await waitFor(async () => {
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
    const tree = await command('Accessibility.getFullAXTree');
    return tree.nodes.some(node => node.name?.value?.includes('Đăng nhập'));
  }, 'Flutter login screen');
  const tree = await command('Accessibility.getFullAXTree');
  const textFields = tree.nodes.filter(node => node.role?.value === 'textbox');
  assert.ok(textFields.length >= 2, 'Login should expose email and password fields');
  const login = tree.nodes.find(node => node.role?.value === 'button' &&
    /^đăng nhập$/i.test((node.name?.value || '').trim()));
  assert.ok(login, 'Login button must be visible');
  // Submit an empty form through real browser mouse events; no authentication request.
  const box = await command('DOM.getBoxModel',{backendNodeId:login.backendDOMNodeId});
  const quad = box.model.content;
  const x = (quad[0] + quad[4])/2;
  const y = (quad[1] + quad[5])/2;
  await command('Input.dispatchMouseEvent',{type:'mousePressed',x,y,button:'left',clickCount:1});
  await command('Input.dispatchMouseEvent',{type:'mouseReleased',x,y,button:'left',clickCount:1});
  await waitFor(async () => {
    const current = await command('Accessibility.getFullAXTree');
    return current.nodes.some(node => /Email không được để trống/i.test(node.name?.value || ''))
      && current.nodes.some(node => /Mật khẩu không được để trống/i.test(node.name?.value || ''));
  }, 'empty form validation');
  await delay(500);
  assert.deepEqual(errors, [], 'No JavaScript/runtime/resource errors during startup and validation');
  const screenshot = await command('Page.captureScreenshot',{format:'png'});
  await writeFile(resolve('build/web-smoke.png'), Buffer.from(screenshot.data,'base64'));
  console.log('PASS: web release starts, accessible login renders, empty form validates, no runtime errors');
  console.log('Screenshot: build/web-smoke.png');
} finally {
  if (socket?.readyState === WebSocket.OPEN) {
    try { await command('Browser.close'); } catch {}
    socket.close();
  }
  if (browser.exitCode === null) browser.kill();
  for (const task of pending.values()) clearTimeout(task.timeout);
  await new Promise(resolve => server.close(resolve));
  // Keep the disposable profile in TEMP for diagnostics; never touch the user's Chrome profile.
}
