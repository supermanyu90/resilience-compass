// smoke.js — load-time regression guard.
//
// Loads logic.js and index.html's inline app script in a stubbed DOM (via `vm`) and asserts the app
// initialises with no reference/DOM errors. This catches the classic extraction bug: a symbol that
// moved to logic.js but wasn't wired back as a global. It is NOT a visual/behavioural test.
const fs = require('fs');
const path = require('path');
const vm = require('vm');

// A DOM node stub that swallows any property access / method call gracefully.
function fakeNode() {
  const store = {};
  return new Proxy(function () {}, {
    get(_t, prop) {
      if (prop === 'classList') return { add() {}, remove() {}, toggle() {}, contains() { return false; } };
      if (prop === 'style' || prop === 'dataset') return {};
      if (['innerHTML', 'textContent', 'value', 'className', 'title', 'lang', 'src'].includes(prop)) return store[prop] || '';
      if (['parentNode', 'firstChild', 'nextSibling'].includes(prop)) return null;
      if (prop === 'toString' || prop === Symbol.toPrimitive) return () => '';
      return (...args) => {
        if (prop === 'querySelectorAll' || prop === 'getElementsByClassName') return [];
        if (prop === 'querySelector' || prop === 'closest' || prop === 'getAttribute') return null;
        if (prop === 'appendChild' || prop === 'insertBefore') return args[0];
        return undefined;
      };
    },
    set(_t, prop, val) { store[prop] = val; return true; },
  });
}

const doc = {
  getElementById: () => fakeNode(), querySelector: () => null, querySelectorAll: () => [],
  createElement: () => fakeNode(), createElementNS: () => fakeNode(),
  addEventListener() {}, removeEventListener() {},
  body: fakeNode(), documentElement: fakeNode(), head: fakeNode(),
};

const sandbox = {
  console, setTimeout: () => 0, clearTimeout() {}, setInterval: () => 0, clearInterval() {},
  document: doc,
  localStorage: { s: {}, getItem(k) { return this.s[k] ?? null; }, setItem(k, v) { this.s[k] = String(v); }, removeItem(k) { delete this.s[k]; } },
  navigator: { mediaDevices: { getUserMedia: () => Promise.reject(new Error('no mic')) }, language: 'en' },
  matchMedia: () => ({ matches: false, addEventListener() {}, removeEventListener() {} }),
  requestAnimationFrame: () => 0, cancelAnimationFrame() {},
  fetch: () => new Promise(() => {}),
  URL, Blob: class {}, File: class {},
  Audio: class { constructor() { this.play = () => Promise.resolve(); } },
  AudioContext: class { decodeAudioData() { return Promise.resolve({ sampleRate: 48000, numberOfChannels: 1, getChannelData: () => new Float32Array(0) }); } close() {} },
  MediaRecorder: class { constructor() { this.state = 'inactive'; } start() {} stop() {} },
  alert() {}, atob: (s) => Buffer.from(s, 'base64').toString('binary'), btoa: (s) => Buffer.from(s, 'binary').toString('base64'),
};
sandbox.window = sandbox; sandbox.self = sandbox; sandbox.globalThis = sandbox;
vm.createContext(sandbox);

const dir = __dirname;
vm.runInContext(fs.readFileSync(path.join(dir, 'logic.js'), 'utf8'), sandbox, { filename: 'logic.js' });

const html = fs.readFileSync(path.join(dir, 'index.html'), 'utf8');
// only the attribute-less <script> is the inline app code (the other is <script src="logic.js">)
const inline = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
if (!inline.length) { console.error('smoke: no inline <script> found'); process.exit(1); }

try {
  vm.runInContext(inline[inline.length - 1], sandbox, { filename: 'index-inline.js' });
} catch (e) {
  console.error('SMOKE FAILED — app script threw at load:\n', e && e.stack ? e.stack : e);
  process.exit(1);
}
console.log('SMOKE OK — logic.js + app script initialised with no reference/DOM errors');
