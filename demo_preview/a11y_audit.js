// a11y_audit.js — renders the real app DOM in a stubbed context and asserts:
//  (1) every interactive control has an accessible name, and
//  (2) clickable <div> controls (tabs/segments/framework rows) get focus/role/keyboard wiring at bind().
// A programmatic stand-in for a manual screen-reader/keyboard pass. Run: `node a11y_audit.js`.
const fs = require('fs'), path = require('path'), vm = require('vm');
const DIR = __dirname;

function recNode(tag) {
  const attrs = {};
  return { tagName: tag, dataset: {}, onkeydown: null, onclick: null, click() {},
    getAttribute: (k) => attrs[k] ?? null, setAttribute: (k, v) => { attrs[k] = v; }, _attrs: attrs,
    classList: { add() {}, remove() {}, toggle() {}, contains() { return false; } } };
}
const keyopNodes = [recNode('DIV')];
const KEYOP_SEL = '[data-adv],[data-seg],[data-jtoggle],[data-helptab]';

function fakeNode() {
  const store = {};
  return new Proxy(function () {}, {
    get(_t, p) {
      if (p === 'classList') return { add() {}, remove() {}, toggle() {}, contains() { return false; } };
      if (p === 'style' || p === 'dataset') return {};
      if (['innerHTML', 'textContent', 'value', 'className', 'title', 'lang'].includes(p)) return store[p] || '';
      if (p === 'toString' || p === Symbol.toPrimitive) return () => '';
      return (...a) => (p === 'querySelectorAll' ? [] : (p === 'querySelector' ? null : (p === 'appendChild' ? a[0] : undefined)));
    },
    set(_t, p, v) { store[p] = v; return true; },
  });
}
const appEl = { _html: '', set innerHTML(v) { this._html = v; }, get innerHTML() { return this._html; },
  insertAdjacentHTML() {}, querySelector: () => null,
  querySelectorAll: (sel) => (sel === KEYOP_SEL ? keyopNodes : []),
  classList: { add() {}, remove() {}, toggle() {}, contains() { return false; } } };
const doc = { getElementById: (id) => (id === 'app' ? appEl : fakeNode()), querySelector: () => null,
  querySelectorAll: () => [], createElement: () => fakeNode(), addEventListener() {},
  body: fakeNode(), documentElement: fakeNode(), head: fakeNode() };
const sandbox = { console, setTimeout: () => 0, clearTimeout() {}, setInterval: () => 0, clearInterval() {},
  document: doc, localStorage: { s: {}, getItem(k) { return this.s[k] ?? null; }, setItem(k, v) { this.s[k] = String(v); }, removeItem(k) { delete this.s[k]; } },
  navigator: { mediaDevices: { getUserMedia: () => Promise.reject() }, language: 'en' },
  matchMedia: () => ({ matches: false, addEventListener() {} }), requestAnimationFrame: () => 0,
  fetch: () => new Promise(() => {}), URL, Blob: class {}, Audio: class { play() { return Promise.resolve(); } },
  AudioContext: class { decodeAudioData() { return Promise.resolve({ sampleRate: 48000, getChannelData: () => new Float32Array(0) }); } close() {} },
  MediaRecorder: class { start() {} stop() {} }, alert() {} };
sandbox.window = sandbox; sandbox.self = sandbox; sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(fs.readFileSync(path.join(DIR, 'logic.js'), 'utf8'), sandbox, { filename: 'logic.js' });

const html = fs.readFileSync(path.join(DIR, 'index.html'), 'utf8');
const inline = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]).pop();
const snippet = `try{ globalThis.__audit={}; state.voice.enabled=true;
  __audit.intro=viewShell();
  state.view='adv'; state.advTab='assistant'; __audit.assistant=viewShell();
  state.advTab='scanner'; __audit.scanner=viewAdvisor();
  state.advTab='tools'; __audit.tools=viewAdvisor();
  __audit.frameworks=frameworksModal();
  state.helpTab='howto'; __audit.helpHowto=helpModal();
  state.helpTab='faq'; __audit.helpFaq=helpModal();
  __audit.about=aboutModal();
  sim.phase='running'; sim.log=[{role:'fac',text:'SCENARIO: x'},{role:'dec',text:'y'}]; __audit.running=viewSim();
  sim.phase='report'; sim.report='## Scenario\\nx'; __audit.report=viewSim();
}catch(e){ globalThis.__auditErr=(e&&e.stack)||(''+e); }`;
vm.runInContext(inline + '\n' + snippet, sandbox, { filename: 'index-inline.js' });
if (sandbox.__auditErr) { console.error('RENDER ERROR:\n', sandbox.__auditErr); process.exit(1); }

const kn = keyopNodes[0];
const keyopOk = kn._attrs.tabindex === '0' && kn._attrs.role === 'button' && typeof kn.onkeydown === 'function';
console.log('[keyboard] clickable <div> controls get tabindex/role/keydown at bind:', keyopOk ? 'PASS' : 'FAIL');

const LETTER = /[A-Za-zÀ-ɏЀ-ӿऀ-ॿ一-鿿]/;
const violations = [];
for (const [view, h] of Object.entries(sandbox.__audit)) {
  for (const m of h.matchAll(/<button([^>]*)>([\s\S]*?)<\/button>/g)) {
    const named = /aria-label\s*=\s*["'][^"']+["']/.test(m[1]) || LETTER.test(m[2].replace(/<[^>]*>/g, ''));
    if (!named) violations.push(`${view}: <button${m[1]}> has no accessible name`);
  }
  for (const m of h.matchAll(/<(select|textarea)([^>]*)>/g)) {
    if (!/aria-label\s*=/.test(m[2])) violations.push(`${view}: <${m[1]}> lacks aria-label`);
  }
  for (const m of h.matchAll(/<input([^>]*)>/g)) {
    if (/type\s*=\s*["'](file|hidden)["']/.test(m[1])) continue;
    if (!/aria-label\s*=/.test(m[1])) violations.push(`${view}: <input> lacks aria-label`);
  }
}
const btnCount = Object.values(sandbox.__audit).reduce((n, h) => n + (h.match(/<button/g) || []).length, 0);
console.log(`[names] scanned ${Object.keys(sandbox.__audit).length} views, ${btnCount} buttons`);
console.log(violations.length ? 'VIOLATIONS:\n' + violations.map((v) => ' - ' + v).join('\n')
  : '[names] every button / select / textarea / input has an accessible name: PASS');
process.exit(keyopOk && !violations.length ? 0 : 1);
