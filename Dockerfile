FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates chromium python3 && rm -rf /var/lib/apt/lists/* && useradd --create-home --uid 10001 browser-test
USER browser-test
WORKDIR /tmp
ENV PORT=8000
EXPOSE 8000
CMD ["python3", "-u", "-c", "import http.server, os, subprocess, tempfile, threading\n\ndef check():\n    try:\n        with tempfile.TemporaryDirectory(prefix='chromium-') as profile:\n            result = subprocess.run(['chromium', '--headless', '--disable-dev-shm-usage', '--user-data-dir=' + profile, '--dump-dom', 'https://example.com/'], capture_output=True, text=True, timeout=150)\n        passed = result.returncode == 0 and '<title>Example Domain</title>' in result.stdout\n        print('CHROMIUM_TEST:', 'PASS' if passed else 'FAIL', flush=True)\n        if not passed:\n            print(result.stderr[-2000:], flush=True)\n    except Exception as error:\n        print('CHROMIUM_TEST: FAIL:', error, flush=True)\n\nclass Health(http.server.BaseHTTPRequestHandler):\n    def do_GET(self):\n        self.send_response(200 if self.path in ('/', '/health', '/healthz') else 404)\n        self.end_headers()\n        self.wfile.write(b'Hostless Chromium test\\n')\n\nthreading.Thread(target=check, daemon=True).start()\nhttp.server.ThreadingHTTPServer(('0.0.0.0', int(os.environ['PORT'])), Health).serve_forever()"]
