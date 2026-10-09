#!/usr/bin/env python3
"""Write a minimal Sparkle 2 update feed from an EdDSA-signed notarized ZIP."""
import os
import re
import sys
from xml.etree import ElementTree as ET
from pathlib import Path

tag = os.environ["RELEASE_TAG"]
version = os.environ["RELEASE_VERSION"]
build = os.environ["RELEASE_BUILD"]
asset = os.environ["RELEASE_ASSET"]
signature_line = os.environ["SIGNATURE_LINE"]
signature = re.search(r'sparkle:edSignature="([A-Za-z0-9+/=]+)"', signature_line)
length = re.search(r'length="([0-9]+)"', signature_line)
if not signature or not length:
    sys.exit("Invalid Sparkle sign_update output")
if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", tag):
    sys.exit("Tag must be vMAJOR.MINOR.PATCH for stable updates")
if not re.fullmatch(r"[0-9]+", build):
    sys.exit("Build must be numeric")
if not re.fullmatch(r"Lunarium-[0-9]+\.[0-9]+\.[0-9]+-arm64\.zip", asset):
    sys.exit("Unexpected ZIP asset name")

sparkle = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", sparkle)
rss = ET.Element("rss", {"version": "2.0"})
channel = ET.SubElement(rss, "channel")
ET.SubElement(channel, "title").text = "Lunarium Updates"
ET.SubElement(channel, "language").text = "en"
ET.SubElement(channel, "description").text = "Signed updates for Lunarium on Apple Silicon"
item = ET.SubElement(channel, "item")
ET.SubElement(item, "title").text = "Lunarium " + version
ET.SubElement(item, "pubDate").text = __import__("email.utils", fromlist=["formatdate"]).formatdate(usegmt=True)
ET.SubElement(item, f"{{{sparkle}}}minimumSystemVersion").text = "14.0"
url = f"https://github.com/owlCoder/lunarium/releases/download/{tag}/{asset}"
ET.SubElement(item, "enclosure", {
    "url": url,
    "length": length.group(1),
    "type": "application/octet-stream",
    f"{{{sparkle}}}version": build,
    f"{{{sparkle}}}shortVersionString": version,
    f"{{{sparkle}}}edSignature": signature.group(1),
})
Path("dist/appcast.xml").write_bytes(
    b'<?xml version="1.0" encoding="utf-8"?>\n' +
    ET.tostring(rss, encoding="utf-8", xml_declaration=False)
)
print(f"Wrote signed-archive feed for {tag} ({asset}).")
