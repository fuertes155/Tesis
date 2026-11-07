"""Matriz real Chrome/Edge/Firefox contra el build web, con capturas y versiones."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
from threading import Thread

from playwright.sync_api import sync_playwright
from local_api import ROOT


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=ROOT / "artifacts/compatibility")
    parser.add_argument("--browser", choices=["Chrome", "Edge", "Firefox"])
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    if not (ROOT / "build/web/index.html").exists():
        parser.error("Ejecuta primero flutter build web --release")
    handler = partial(SimpleHTTPRequestHandler, directory=str(ROOT / "build/web"))
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    results = []
    try:
        with sync_playwright() as playwright:
            for name, engine, options in [
                ("Chrome", playwright.chromium, {"channel": "chrome"}),
                ("Edge", playwright.chromium, {"channel": "msedge"}),
                ("Firefox", playwright.firefox, {}),
            ]:
                if args.browser and name != args.browser:
                    continue
                try:
                    browser = engine.launch(**options)
                except Exception as error:
                    results.append({"browser": name, "passed": False, "error": str(error)})
                    continue
                try:
                    for width, height in [(360, 800), (768, 1024), (1440, 1000)]:
                        row = {"browser": name, "version": browser.version, "width": width, "height": height}
                        page = None
                        page_errors = []
                        try:
                            page = browser.new_page(viewport={"width": width, "height": height})
                            page.on("pageerror", lambda error: page_errors.append(str(error)))
                            page.goto(f"http://127.0.0.1:{server.server_port}", wait_until="networkidle")
                            placeholder = page.locator("flt-semantics-placeholder")
                            if placeholder.count():
                                placeholder.dispatch_event("click", timeout=90000)
                            user = page.get_by_role("textbox", name="Usuario")
                            user.wait_for(timeout=90000)
                            user.fill("qa@example.com")
                            user.fill("")
                            page.get_by_role("button", name="INICIAR SESIÓN").click()
                            page.get_by_text("Ingresa usuario y contraseña", exact=False).wait_for(timeout=15000)
                            if page_errors:
                                raise RuntimeError("; ".join(page_errors))
                            row["passed"] = True
                        except Exception as error:
                            row.update(passed=False, error=str(error), page_errors=page_errors)
                        if page is not None:
                            try:
                                page.screenshot(path=str(args.output / f"{name}_{width}.png"), full_page=True)
                            except Exception as error:
                                row["screenshot_error"] = str(error)
                        results.append(row)
                        if page is not None:
                            page.close()
                finally:
                    browser.close()
    finally:
        server.shutdown()
        server.server_close()
    (args.output / "summary.json").write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(results, indent=2, ensure_ascii=False))
    return 0 if all(row["passed"] for row in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
