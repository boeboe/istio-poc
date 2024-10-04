import http from 'k6/http';
import { check } from 'k6';

// Environment variables
const INGRESS_EXTERNAL_IP = __ENV.INGRESS_EXTERNAL_IP; // Pass in the Ingress IP via env variable
const INGRESS_HTTP_PORT = __ENV.INGRESS_HTTP_PORT;
const INGRESS_HTTPS_PORT = __ENV.INGRESS_HTTPS_PORT;
const DNS_SUFFIX = __ENV.DNS_SUFFIX;
const TEST_SCENARIO = __ENV.TEST_SCENARIO || 'http'; // Default to 'http' if not specified

// Define URLs
const HTTP_URL = `http://perf-http.${DNS_SUFFIX}:${INGRESS_HTTP_PORT}/`;
const HTTPS_URL = `https://perf-https-mtls.${DNS_SUFFIX}:${INGRESS_HTTPS_PORT}/`;

// Certs for https-mtls
const CERT = open('output/https-mtls/wildcard-cert.pem'); // Path to certificate
const KEY = open('output/https-mtls/wildcard-key.pem');   // Path to private key if needed

export let options = {
  stages: [
    { duration: '1m', target: 1000 }, // Ramp-up to 10 users over 1 minute
    { duration: '5m', target: 1000 }, // Hold at 10 users for 5 minutes
    { duration: '1m', target: 0 },  // Ramp-down to 0 users over 1 minute
  ],
};

export default function () {
  if (TEST_SCENARIO === 'http') {
    // Test HTTP Endpoint
    let resHttp = http.get(HTTP_URL, {
      headers: {
        'Test': 'HALLOOOOOO',
        'Host': `perf-http.${DNS_SUFFIX}`,
      },
    });
    check(resHttp, {
      'HTTP status is 200': (r) => r.status === 200,
    });
  } else if (TEST_SCENARIO === 'https-mtls') {
    // Test HTTPS Endpoint with mTLS
    let resHttps = http.get(HTTPS_URL, {
      headers: {
        'Test': 'HALLOOOOOO',
        'Host': `perf-https-mtls.${DNS_SUFFIX}`,
      },
      tlsAuth: {
        cert: CERT, // Path to certificate
        key: KEY,   // Path to private key if needed
      },
    });
    check(resHttps, {
      'HTTPS status is 200': (r) => r.status === 200,
    });
  } else {
    throw new Error(`Invalid TEST_SCENARIO value: ${TEST_SCENARIO}. Use "http" or "https".`);
  }
}
