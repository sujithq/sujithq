"""
Blog Posts Automation Script for README.md

This script fetches the latest blog posts from an RSS/Atom feed and updates
the "Latest Blog Posts" section in README.md between the specified markers.

Usage:
    python scripts/update_blog_posts.py

The script will:
1. Fetch the RSS feed from FEED_URL
2. Parse the latest 5 posts (title + URL)
3. Update the content between BLOG-POST-LIST markers in README.md
4. Only write changes if the content actually differs (idempotent)

Environment: Designed to run in GitHub Actions with Python 3.x
Author: GitHub Actions automation
"""

import re
import sys
from pathlib import Path
from xml.etree import ElementTree as ET
import urllib.request

README = Path("README.md")
FEED_URL = "https://sujithq.github.io/index.xml"
START = "<!-- BLOG-POST-LIST:START -->"
END = "<!-- BLOG-POST-LIST:END -->"
COUNT = 5

def fetch_feed(url):
    with urllib.request.urlopen(url) as resp:
        return resp.read()

def parse_items(xml_bytes, count):
    root = ET.fromstring(xml_bytes)
    items = []
    # RSS 2.0
    for item in root.findall(".//item"):
        title = (item.findtext("title") or "").strip()
        link = (item.findtext("link") or "").strip()
        if title and link:
            items.append((title, link))
    # Atom fallback
    if not items:
        ns = {"atom": "http://www.w3.org/2005/Atom"}
        for entry in root.findall(".//atom:entry", ns):
            title = (entry.findtext("atom:title", namespaces=ns) or "").strip()
            link_el = entry.find("atom:link[@rel='alternate']", ns) or entry.find("atom:link", ns)
            link = (link_el.get("href") if link_el is not None else "").strip()
            if title and link:
                items.append((title, link))
    return items[:count]

def replace_section(content, start, end, new_block):
    pattern = re.compile(rf"({re.escape(start)})(.*)({re.escape(end)})", re.DOTALL)
    replacement = f"{start}\n{new_block}\n{end}"
    if not pattern.search(content):
        return content.rstrip() + "\n\n" + replacement + "\n"
    return pattern.sub(replacement, content)

def main():
    xml = fetch_feed(FEED_URL)
    items = parse_items(xml, COUNT)
    lines = [f"- [{t}]({u})" for t, u in items] or ["- _(no posts found)_"]
    new_block = "\n".join(lines)

    content = README.read_text(encoding="utf-8")
    updated = replace_section(content, START, END, new_block)
    if updated != content:
        README.write_text(updated, encoding="utf-8")
        print("README updated.")
    else:
        print("No changes needed.")

if __name__ == "__main__":
    sys.exit(main())