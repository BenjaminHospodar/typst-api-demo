import http from 'k6/http';
import { check } from 'k6';
import { Rate } from 'k6/metrics';

const BASE = (__ENV.BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
const API_KEY = __ENV.PDFGEN_API_KEY || '';
const breakerHits = new Rate('sidecar_unavailable');

export const options = {
  vus: 8,
  duration: '20s',
  thresholds: {
    sidecar_unavailable: ['rate>0.8'],
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
      form: 'minimal',
      version: '1.0.0',
      fields: { name: 'sidecar-kill', date: '2024-04-13' },
    }),
    { headers: headers(), timeout: '10s' },
  );
  breakerHits.add(
    check(res, {
      '503 circuit breaker or unavailable': (r) => r.status === 503,
    }),
  );
}
