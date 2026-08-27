import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE = (__ENV.BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
const API_KEY = __ENV.PDFGEN_API_KEY || '';
const errorsOk = new Rate('expected_error_hits');

export const options = {
  vus: 4,
  duration: '20s',
  thresholds: {
    expected_error_hits: ['rate>0.9'],
  },
};

function headers() {
  const h = { 'Content-Type': 'application/json' };
  if (API_KEY) {
    h['X-API-Key'] = API_KEY;
  }
  return h;
}

export default function () {
  const missing = http.post(
    `${BASE}/api/v1/generate`,
    JSON.stringify({ form: 'no-such-form', version: '9.9.9', fields: { name: 'x' } }),
    { headers: headers() },
  );
  errorsOk.add(check(missing, { '404 unknown form': (r) => r.status === 404 }));

  const invalidKey = http.post(
    `${BASE}/api/v1/generate`,
    JSON.stringify({ form: 'invoice', version: '2.0.0', fields: { 'bad-key!': 'x' } }),
    { headers: headers() },
  );
  errorsOk.add(check(invalidKey, { '400 invalid field key': (r) => r.status === 400 }));

  const huge = {};
  for (let i = 0; i < 250; i++) {
    huge[`field_${i}`] = 'x';
  }
  const tooMany = http.post(
    `${BASE}/api/v1/generate`,
    JSON.stringify({ form: 'invoice', version: '2.0.0', fields: huge }),
    { headers: headers() },
  );
  errorsOk.add(check(tooMany, { '413 too many fields': (r) => r.status === 413 }));

  const hugeValue = http.post(
    `${BASE}/api/v1/generate`,
    JSON.stringify({
      form: 'invoice',
      version: '2.0.0',
      fields: { name: 'Acme', date: '2024-04-13', text1: 'x'.repeat(9000) },
    }),
    { headers: headers() },
  );
  errorsOk.add(check(hugeValue, { '413 oversized field': (r) => r.status === 413 }));

  const compileFail = http.post(
    `${BASE}/api/v1/generate`,
    JSON.stringify({ form: 'broken', version: '1.0.0', fields: { name: 'x' } }),
    { headers: headers() },
  );
  let compileStatus = compileFail.status;
  if (compileStatus === 202) {
    let body;
    try {
      body = compileFail.json();
    } catch (e) {
      body = {};
    }
    const path = body.poll_url || `/api/v1/jobs/${body.job_id}/result`;
    for (let i = 0; i < 20; i++) {
      const polled = http.get(`${BASE}${path}`, { headers: headers() });
      if (polled.status === 422 || polled.status === 200 || polled.status >= 500) {
        compileStatus = polled.status;
        break;
      }
      sleep(0.1);
    }
  }
  errorsOk.add(check({ status: compileStatus }, { '422 compile error': (r) => r.status === 422 }));

  const pollMissing = http.get(`${BASE}/api/v1/jobs/does-not-exist/result`, {
    headers: headers(),
  });
  errorsOk.add(check(pollMissing, { '404 missing job': (r) => r.status === 404 }));
}
