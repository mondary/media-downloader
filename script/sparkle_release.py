#!/usr/bin/env python3
"""Sign a Sparkle enclosure and append it to appcast.xml.

Usage: sparkle_release.py <archive> <tag> <short-version> <bundle-version> <repo> <app-name> <minimum-macos> <notes-file>
SPARKLE_PRIVATE_KEY contains the base64 encoded raw Ed25519 private key.
"""
import base64
import datetime
import html
import os
import pathlib
import re
import sys
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey


def markdown_html(markdown):
    output = []
    in_list = False
    for raw in markdown.strip().splitlines():
        line = raw.strip()
        if not line:
            if in_list:
                output.append("</ul>")
                in_list = False
            continue
        heading = re.match(r"^(#{1,6})\s+(.+)$", line)
        bullet = re.match(r"^[-*+]\s+(.+)$", line)
        safe = html.escape(line, quote=False)
        safe = re.sub(r"`([^`]+)`", r"<code>\1</code>", safe)
        safe = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", safe)
        if heading:
            if in_list:
                output.append("</ul>")
                in_list = False
            level = min(len(heading.group(1)) + 1, 6)
            output.append(f"<h{level}>{html.escape(heading.group(2))}</h{level}>")
        elif bullet:
            if not in_list:
                output.append("<ul>")
                in_list = True
            content = html.escape(bullet.group(1), quote=False)
            output.append(f"<li>{content}</li>")
        else:
            if in_list:
                output.append("</ul>")
                in_list = False
            output.append(f"<p>{safe}</p>")
    if in_list:
        output.append("</ul>")
    return "".join(output).replace("]]>", "]]]]><![CDATA[>")


def main():
    archive, tag, short_version, bundle_version, repo, app_name, minimum_macos, notes_path = sys.argv[1:]
    path = pathlib.Path(archive)
    data = path.read_bytes()
    key = Ed25519PrivateKey.from_private_bytes(base64.b64decode(os.environ["SPARKLE_PRIVATE_KEY"].strip()))
    signature = base64.b64encode(key.sign(data)).decode()
    pub_date = datetime.datetime.now(datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")
    enclosure_url = f"https://github.com/{repo}/releases/download/{tag}/{path.name}"
    notes = markdown_html(pathlib.Path(notes_path).read_text())
    item = f"""      <item>
        <title>{html.escape(app_name)} {html.escape(short_version)}</title>
        <pubDate>{pub_date}</pubDate>
        <sparkle:version>{html.escape(bundle_version)}</sparkle:version>
        <sparkle:shortVersionString>{html.escape(short_version)}</sparkle:shortVersionString>
        <sparkle:minimumSystemVersion>{html.escape(minimum_macos)}</sparkle:minimumSystemVersion>
        <description><![CDATA[{notes}]]></description>
        <enclosure url="{html.escape(enclosure_url, quote=True)}" type="application/octet-stream" sparkle:edSignature="{signature}" length="{len(data)}" />
      </item>"""
    feed = pathlib.Path("appcast.xml")
    content = feed.read_text()
    if f"<sparkle:shortVersionString>{short_version}</sparkle:shortVersionString>" in content:
        raise SystemExit(f"appcast already contains {short_version}")
    content = re.sub(r"(?m)^\s*</channel>", item + "\n  </channel>", content, count=1)
    feed.write_text(content)
    print(f"Signed appcast item added for {short_version} ({len(data)} bytes)")


if __name__ == "__main__":
    main()
