import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE = (__ENV.BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
const API_KEY = __ENV.PDFGEN_API_KEY || '';
const accepted = new Rate('async_accepted');

export const options = {
  scenarios: {
    flood: {
      executor: 'constant-arrival-rate',
      rate: 40,
      timeUnit: '1s',
      duration: '20s',
      preAllocatedVUs: 40,
      maxVUs: 80,
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.2'],
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
  const res = http.post(
    `${BASE}/api/v1/generate`,
    JSON.stringify({
      form: 'legal',
      version: '1.0.0',
      fields: { name: 'Rabbit flood', date: '2024-04-13', text1: 'queue saturation' },
    }),
    { headers: headers(), timeout: '15s' },
  );
  accepted.add(
    check(res, {
      '200, 202, or 503 under saturation': (r) =>
        r.status === 200 || r.status === 202 || r.status === 503,
    }),
  );
  if (res.status === 202) {
    sleep(0.05);
  }
}
