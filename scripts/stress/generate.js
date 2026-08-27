import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const BASE = (__ENV.BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
const API_KEY = __ENV.PDFGEN_API_KEY || '';

const generateErrors = new Rate('generate_errors');
const generateDuration = new Trend('generate_wait_ms');

const TEMPLATES = [
  { form: 'invoice', version: '2.0.0' },
  { form: 'minimal', version: '1.0.0' },
  { form: 'report', version: '1.0.0' },
  { form: 'legal', version: '1.0.0' },
];

export const options = {
  scenarios: {
    warmup: {
      executor: 'constant-vus',
      vus: 2,
      duration: '15s',
      exec: 'generate',
      tags: { scenario: 'warmup' },
    },
    sustained: {
      executor: 'constant-arrival-rate',
      rate: 5,
      timeUnit: '1s',
      duration: '45s',
      preAllocatedVUs: 20,
      maxVUs: 40,
      startTime: '15s',
      exec: 'generate',
      tags: { scenario: 'sustained' },
    },
    spike: {
      executor: 'ramping-arrival-rate',
      startRate: 5,
      timeUnit: '1s',
      stages: [
        { duration: '10s', target: 20 },
        { duration: '15s', target: 20 },
        { duration: '10s', target: 5 },
      ],
      preAllocatedVUs: 30,
      maxVUs: 50,
      startTime: '60s',
      exec: 'generate',
      tags: { scenario: 'spike' },
    },
  },
  thresholds: {
    http_req_duration: ['p(50)<2000', 'p(95)<5000', 'p(99)<10000'],
    generate_errors: ['rate<0.05'],
  },
};

function headers() {
  const h = { 'Content-Type': 'application/json' };
  if (API_KEY) {
    h['X-API-Key'] = API_KEY;
  }
  return h;
}

export function generate() {
  const template = TEMPLATES[Math.floor(Math.random() * TEMPLATES.length)];
  const res = http.post(
    `${BASE}/api/v1/generate`,
    JSON.stringify({
      form: template.form,
      version: template.version,
      fields: {
        name: 'Load Test',
        date: '2024-04-13',
        text1: 'k6 mixed-template generate',
      },
    }),
    { headers: headers(), timeout: '30s' },
  );

  generateDuration.add(res.timings.duration);

  const ok = check(res, {
    'sync PDF or async accept': (r) => r.status === 200 || r.status === 202,
  });
  generateErrors.add(!ok);

  if (res.status === 202) {
    let body;
    try {
      body = res.json();
    } catch (e) {
      generateErrors.add(true);
      return;
    }
    const path = body.poll_url || `/api/v1/jobs/${body.job_id}/result`;
    poll(path);
  }
}

function poll(path) {
  for (let i = 0; i < 40; i++) {
    const res = http.get(`${BASE}${path}`, { headers: headers(), timeout: '10s' });
    if (res.status === 200) {
      return;
    }
    if (res.status === 422 || res.status >= 500) {
      generateErrors.add(true);
      return;
    }
    sleep(0.25);
  }
  generateErrors.add(true);
}
