// logic.test.js — unit tests for the pure domain logic. Run: `node --test` (Node 18+, no deps).
const test = require('node:test');
const assert = require('node:assert/strict');
const L = require('./logic.js');

test('sevWeight maps severity labels', () => {
  assert.equal(L.sevWeight('low'), 1);
  assert.equal(L.sevWeight('medium'), 2);
  assert.equal(L.sevWeight('high'), 3);
  assert.equal(L.sevWeight('anything-else'), 2); // defaults to medium
});

test('computeScore: bounds and monotonicity', () => {
  assert.equal(L.computeScore('high', 3, 1), 0);   // worst case -> 0
  assert.equal(L.computeScore('low', 1, 4), 100);  // best case -> 100
  const s = L.computeScore('medium', 2, 2);
  assert.ok(s >= 0 && s <= 100);
  // better controls never lower the score
  assert.ok(L.computeScore('high', 3, 4) >= L.computeScore('high', 3, 1));
  // higher inherent risk never raises the score
  assert.ok(L.computeScore('high', 3, 2) <= L.computeScore('low', 1, 2));
});

test('computeScore clamps out-of-range inputs', () => {
  assert.equal(L.computeScore('high', 99, 0), L.computeScore('high', 3, 1));
  assert.equal(L.computeScore('low', -5, 9), L.computeScore('low', 1, 4));
});

test('concentrationRisksFrom flags providers shared by >=2 vendors, sorted desc', () => {
  const vendors = [
    { vendor: 'FIS', nth: ['AWS', 'Cloudflare'] },
    { vendor: 'Temenos', nth: ['AWS'] },
    { vendor: 'nCino', nth: ['AWS', 'Cloudflare'] },
    { vendor: 'Solo', nth: ['GCP'] },
  ];
  const r = L.concentrationRisksFrom(vendors);
  assert.equal(r[0].display, 'AWS');
  assert.deepEqual(r[0].vendors, ['FIS', 'Temenos', 'nCino']);
  assert.equal(r[1].display, 'Cloudflare');
  assert.ok(!r.find((x) => x.display === 'GCP')); // used by only one vendor -> not flagged
});

test('concentrationRisksFrom is case-insensitive and de-dupes within a vendor', () => {
  const r = L.concentrationRisksFrom([
    { vendor: 'A', nth: ['aws', 'AWS ', ' Aws'] }, // same provider 3x within one vendor
    { vendor: 'B', nth: ['AWS'] },
  ]);
  assert.equal(r.length, 1);
  assert.deepEqual(r[0].vendors, ['A', 'B']); // A counted once
});

test('concentrationRisksFrom handles empty / missing input', () => {
  assert.deepEqual(L.concentrationRisksFrom([]), []);
  assert.deepEqual(L.concentrationRisksFrom(undefined), []);
  assert.deepEqual(L.concentrationRisksFrom([{ vendor: 'X' }]), []); // no nth array
});

test('cosine similarity', () => {
  assert.ok(Math.abs(L.cosine([1, 0], [1, 0]) - 1) < 1e-6);
  assert.ok(Math.abs(L.cosine([1, 0], [0, 1])) < 1e-6);
  assert.ok(L.cosine([1, 1], [1, 0]) > 0 && L.cosine([1, 1], [1, 0]) < 1);
});

test('gemmaVer extracts major version', () => {
  assert.equal(L.gemmaVer('gemma3:4b'), 3);
  assert.equal(L.gemmaVer('gemma2:2b'), 2);
  assert.equal(L.gemmaVer('llama3'), 0);
});

test('firstJsonObject: balanced, string-aware extraction', () => {
  assert.equal(L.firstJsonObject('noise {"a":1} tail'), '{"a":1}');
  assert.equal(L.firstJsonObject('{"a":{"b":2}}x'), '{"a":{"b":2}}');
  assert.equal(L.firstJsonObject('{"s":"has } brace and \\" quote"}'), '{"s":"has } brace and \\" quote"}');
  assert.equal(L.firstJsonObject('no json here'), null);
});

test('displayText strips the assessment tag', () => {
  assert.equal(L.displayText('Hello.  [[ASSESSMENT]] {"maturity":3}'), 'Hello.');
  assert.equal(L.displayText('No tag here'), 'No tag here');
});

test('extractAssessment parses valid JSON and clamps maturity', () => {
  const a = L.extractAssessment('x [[ASSESSMENT]] {"maturity":3,"citations":["ISO 22301 8.4"],"rationale":"ok"}');
  assert.equal(a.maturity, 3);
  assert.deepEqual(a.citations, ['ISO 22301 8.4']);
  assert.equal(a.rationale, 'ok');
  assert.equal(L.extractAssessment('x [[ASSESSMENT]] {"maturity":9}').maturity, 4); // clamped to 1..4
});

test('extractAssessment regex fallback for malformed JSON (the "2>" placeholder bug)', () => {
  // model emitted an unquoted placeholder that breaks JSON.parse
  const a = L.extractAssessment('reply [[ASSESSMENT]] {"maturity": 2>, "citations": ["APRA CPS 230"], "rationale": "partial"}');
  assert.equal(a.maturity, 2);
  assert.deepEqual(a.citations, ['APRA CPS 230']);
  assert.equal(a.rationale, 'partial');
});

test('extractAssessment returns null when no tag', () => {
  assert.equal(L.extractAssessment('just text, no tag'), null);
});

test('extractIncident coerces category and severity', () => {
  const i = L.extractIncident('{"category":"technology","severity":"high","impactArea":"payments","rationale":"db down"}');
  assert.equal(i.category, 'technology');
  assert.equal(i.severity, 'high');
  assert.equal(i.impactArea, 'payments');

  // "moderate" -> "medium"; unknown severity -> "medium"
  assert.equal(L.extractIncident('{"category":"cyber","severity":"moderate"}').severity, 'medium');
  assert.equal(L.extractIncident('{"category":"cyber","severity":"catastrophic"}').severity, 'medium');

  // fuzzy category coercion
  assert.equal(L.extractIncident('{"category":"vendor outage"}').category, 'third-party');
  assert.equal(L.extractIncident('{"category":"IT system"}').category, 'technology');
  assert.equal(L.extractIncident('{"category":"totally unknown"}').category, 'process');

  // snake_case impact_area alias
  assert.equal(L.extractIncident('{"category":"people","impact_area":"branch ops"}').impactArea, 'branch ops');
});

test('extractIncident returns null on non-JSON', () => {
  assert.equal(L.extractIncident('the model refused to answer'), null);
});

test('rankFor / xpProgress ladder', () => {
  assert.equal(L.rankFor(0), 0);
  assert.equal(L.rankFor(59), 0);
  assert.equal(L.rankFor(60), 1);
  assert.equal(L.rankFor(10000), L.RANKS.length - 1);

  const p0 = L.xpProgress(0);
  assert.equal(p0.level, 1);
  assert.equal(p0.name, 'Trainee');
  assert.ok(p0.pct >= 4 && p0.pct <= 100);

  const top = L.xpProgress(999999);
  assert.equal(top.pct, 100); // top rank pinned at 100
  assert.equal(top.name, 'Chief Resilience Officer');
});
