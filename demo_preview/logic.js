// logic.js — pure, framework-agnostic domain logic for Resilience Compass.
//
// Zero DOM / zero network / zero global state: every function here is a pure function of its inputs.
// This is the source of truth for scoring, concentration risk, LLM-output parsing, and gamification —
// shared by the browser app (index.html loads this as globals) and the Node test suite (logic.test.js).

(function (global) {
  'use strict';

  /** Tag the BCM assistant appends before its structured self-assessment JSON. */
  const ASSESS = '[[ASSESSMENT]]';

  /** Gamification ladder (Resilience Points -> rank). */
  const RANKS = [
    { xp: 0, name: 'Trainee' },
    { xp: 60, name: 'Analyst' },
    { xp: 150, name: 'Specialist' },
    { xp: 300, name: 'Resilience Lead' },
    { xp: 500, name: 'Chief Resilience Officer' },
  ];

  /** Incident Scanner categories (stable keys). */
  const DEFAULT_CATEGORIES = ['people', 'process', 'technology', 'third-party', 'cyber', 'facilities'];

  /** Severity label -> 1..3 weight. */
  function sevWeight(s) { return s === 'low' ? 1 : s === 'high' ? 3 : 2; }

  /**
   * Deterministic 0..100 resilience score.
   * inherentRisk = severity*likelihood (normalised), reduced by control effectiveness.
   */
  function computeScore(sev, lik, ctrl) {
    const s = sevWeight(sev), l = Math.min(3, Math.max(1, lik)), c = Math.min(4, Math.max(1, ctrl));
    const inh = (s * l - 1) / 8, cf = (c - 1) / 3, res = inh * (1 - cf);
    return Math.max(0, Math.min(100, Math.round(100 * (1 - res))));
  }

  /**
   * Nth-party concentration risk: any provider shared by >= 2 distinct vendors is a single point of
   * failure. Returns [{display, vendors[]}] sorted by how many vendors share it (desc).
   */
  function concentrationRisksFrom(vendors) {
    const by = {};
    (vendors || []).forEach((v) => {
      const seen = new Set();
      (v.nth || []).forEach((p) => {
        const k = ('' + p).trim().toLowerCase();
        if (!k || seen.has(k)) return;
        seen.add(k);
        if (!by[k]) by[k] = { display: ('' + p).trim(), vendors: [] };
        if (!by[k].vendors.includes(v.vendor)) by[k].vendors.push(v.vendor);
      });
    });
    return Object.values(by).filter((a) => a.vendors.length >= 2).sort((a, b) => b.vendors.length - a.vendors.length);
  }

  /** Cosine similarity of two equal-length numeric vectors (for on-device DORA retrieval). */
  function cosine(a, b) {
    let d = 0, na = 0, nb = 0;
    for (let i = 0; i < a.length; i++) { d += a[i] * b[i]; na += a[i] * a[i]; nb += b[i] * b[i]; }
    return d / (Math.sqrt(na) * Math.sqrt(nb) + 1e-9);
  }

  /** Parse the Gemma major version from a model tag ("gemma3:4b" -> 3), else 0. */
  function gemmaVer(n) { const m = ('' + n).match(/gemma\s*([0-9]+)/i); return m ? parseInt(m[1], 10) : 0; }

  /** First balanced {...} JSON object substring (brace-aware, string/escape-aware), or null. */
  function firstJsonObject(s) {
    const st = s.indexOf('{'); if (st < 0) return null;
    let d = 0, ins = false, esc2 = false;
    for (let i = st; i < s.length; i++) {
      const ch = s[i];
      if (ins) { if (esc2) { esc2 = false; } else if (ch === '\\') { esc2 = true; } else if (ch === '"') { ins = false; } continue; }
      if (ch === '"') { ins = true; } else if (ch === '{') { d++; } else if (ch === '}') { d--; if (d === 0) return s.slice(st, i + 1); }
    }
    return null;
  }

  /** Model reply with the trailing [[ASSESSMENT]] block stripped (what the user sees). */
  function displayText(raw) { const i = raw.indexOf(ASSESS); return (i >= 0 ? raw.slice(0, i) : raw).trim(); }

  /**
   * Parse the BCM self-assessment out of a reply: {maturity:1..4|null, citations:[], rationale}.
   * Tries JSON first, then a lenient regex fallback for malformed model output.
   */
  function extractAssessment(raw) {
    const i = raw.indexOf(ASSESS); if (i < 0) return null;
    const tail = raw.slice(i + ASSESS.length);
    let m = null; const obj = firstJsonObject(tail); if (obj) { try { m = JSON.parse(obj); } catch (e) {} }
    if (!m) {
      const mm = tail.match(/"maturity"\s*:\s*(\d)/); if (!mm) return null;
      const rr = tail.match(/"rationale"\s*:\s*"([^"]*)"/), cc = tail.match(/"citations"\s*:\s*\[([^\]]*)\]/);
      m = { maturity: parseInt(mm[1], 10), rationale: rr ? rr[1] : '', citations: cc ? (cc[1].match(/"([^"]*)"/g) || []).map((x) => x.replace(/"/g, '')) : [] };
    }
    let mat = m.maturity; if (typeof mat === 'string') mat = parseInt(mat, 10);
    mat = (typeof mat === 'number' && !isNaN(mat)) ? Math.max(1, Math.min(4, Math.round(mat))) : null;
    const cites = Array.isArray(m.citations) ? m.citations.map((x) => ('' + x).trim()).filter(Boolean) : [];
    return { maturity: mat, citations: cites, rationale: (m.rationale || '').toString() };
  }

  /**
   * Parse an incident classification JSON into {category, severity, impactArea, rationale}, coercing
   * to known category/severity values.
   */
  function extractIncident(raw, categories) {
    categories = categories || DEFAULT_CATEGORIES;
    const obj = firstJsonObject(raw); if (!obj) return null;
    let m; try { m = JSON.parse(obj); } catch (e) { return null; }
    let cat = (m.category || '').toString().trim().toLowerCase();
    if (!categories.includes(cat)) cat = categories.find((c) => cat.includes(c) || c.includes(cat)) || (/(vendor|supplier|party)/.test(cat) ? 'third-party' : /(tech|system|it)/.test(cat) ? 'technology' : 'process');
    let sev = (m.severity || '').toString().trim().toLowerCase(); if (sev === 'moderate') sev = 'medium';
    if (!['low', 'medium', 'high'].includes(sev)) sev = 'medium';
    return { category: cat, severity: sev, impactArea: (m.impactArea || m.impact_area || '').toString().trim(), rationale: (m.rationale || '').toString().trim() };
  }

  /** Index of the highest rank the given XP has reached. */
  function rankFor(xp, ranks) { ranks = ranks || RANKS; let i = 0; for (let k = 0; k < ranks.length; k++) { if (xp >= ranks[k].xp) i = k; } return i; }

  /** {level, name, pct} progress toward the next rank (pct 100 at the top rank). */
  function xpProgress(xp, ranks) {
    ranks = ranks || RANKS;
    const i = rankFor(xp, ranks), cur = ranks[i], next = ranks[i + 1];
    return { level: i + 1, name: cur.name, pct: next ? Math.max(4, Math.round((xp - cur.xp) / (next.xp - cur.xp) * 100)) : 100 };
  }

  const API = {
    ASSESS, RANKS, DEFAULT_CATEGORIES,
    sevWeight, computeScore, concentrationRisksFrom, cosine, gemmaVer,
    firstJsonObject, displayText, extractAssessment, extractIncident, rankFor, xpProgress,
  };

  if (typeof module === 'object' && module.exports) {
    module.exports = API; // Node / tests
  } else {
    global.RCLogic = API; // browser: also expose each name as a global so index.html uses them unchanged
    Object.keys(API).forEach((k) => { if (!(k in global)) global[k] = API[k]; });
  }
})(typeof globalThis !== 'undefined' ? globalThis : this);
