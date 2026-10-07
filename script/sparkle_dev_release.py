#!/usr/bin/env python3
"""Write the single latest Dev appcast item for a signed app ZIP.

Usage: sparkle_dev_release.py <zip> <bundle-version> <short-version> <repo> <app-name> <minimum-macos>
"""
import base64
import datetime
import os
import pathlib
import sys
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey


def main():
    archive, bundle_version, short_version, repo, app_name, minimum_macos = sys.argv[1:]
    path = pathlib.Path(archive)
    data = path.read_bytes()
    key = Ed25519PrivateKey.from_private_bytes(base64.b64decode(os.environ["SPARKLE_PRIVATE_KEY"].strip()))
    signature = base64.b64encode(key.sign(data)).decode()
    pub_date = datetime.datetime.now(datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")
    xml = f"""<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>{app_name} (dev)</title>
    <link>https://raw.githubusercontent.com/{repo}/main/appcast-dev.xml</link>
    <description>Latest Dev build for {app_name}.</description>
    <language>en</language>
    <item>
      <title>{app_name} {short_version}</title>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{bundle_version}</sparkle:version>
      <sparkle:shortVersionString>{short_version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>{minimum_macos}</sparkle:minimumSystemVersion>
      <description>Automatic Dev build from main. Installed silently for the Dev channel.</description>
      <enclosure url="https://github.com/{repo}/releases/download/dev/{app_name}-dev.zip" type="application/octet-stream" sparkle:edSignature="{signature}" length="{len(data)}" />
    </item>
  </channel>
</rss>
"""
    pathlib.Path("appcast-dev.xml").write_text(xml, encoding="utf-8")
    print(f"Signed Dev appcast written for {bundle_version} ({len(data)} bytes)")


if __name__ == "__main__":
    main()

