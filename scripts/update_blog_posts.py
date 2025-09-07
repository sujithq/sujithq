"""
Blog Posts Automation Script for README.md

This script fetches the latest blog posts from an RSS/Atom feed and updates
the "Latest Blog Posts" section in README.md between the specified markers.

Usage:
    python scripts/update_blog_posts.py

The script will:
    Fetch the RSS feed from FEED_URL
    Parse the latest 5 blogs and 3 updates (title + URL)
3. Update the content between BLOG-POST-LIST markers in README.md
4. Only write changes if the content actually differs (idempotent)

Environment: Designed to run in GitHub Actions with Python 3.x
Author: GitHub Actions automation
"""

import re
import unicodedata
import sys
import logging
import argparse
from pathlib import Path
from xml.etree import ElementTree as ET
import urllib.request

README = Path("README.md")
FEED_URL = "https://sujithq.github.io/index.xml"
BLOG_START = "<!-- BLOG-POST-LIST:START -->"
BLOG_END = "<!-- BLOG-POST-LIST:END -->"
UPDATES_START = "<!-- UPDATES-LIST:START -->"
UPDATES_END = "<!-- UPDATES-LIST:END -->"
BLOG_COUNT = 5
UPDATES_COUNT = 3

def normalize_url(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)       # unicode normalize
    s = s.strip()                               # trim whitespace
    s = re.sub(r'[\u200B-\u200D\uFEFF]', '', s) # remove ZWSP/ZWJ/ZWNJ/BOM
    return s

def fetch_feed(url):
    logging.debug(f"Fetching RSS/Atom feed from {url}")
    with urllib.request.urlopen(url) as resp:
        data = resp.read()
    logging.debug(f"Fetched {len(data)} bytes from feed.")
    return data

def parse_items(xml_bytes):
    logging.debug("Parsing feed XML for items.")
    root = ET.fromstring(xml_bytes)
    items = []
    # RSS 2.0
    for item in root.findall(".//item"):
        title = (item.findtext("title") or "").strip()
        link = (item.findtext("link") or "").strip()
        # guid = (item.findtext("guid") or "").strip()
        logging.debug(f"Found RSS item: title='{title}', link='{link}'")
        print(repr(link[:40]))
        print([hex(ord(c)) for c in link[:8]])
        bool(re.match(r'^\s*https?://sujithq\.github\.io/updates(?:/|$|[?#])', link, re.I))
        if title and link:
            items.append((title, link))
    # Atom fallback
    # if not items:
    #     ns = {"atom": "http://www.w3.org/2005/Atom"}
    #     for entry in root.findall(".//atom:entry", ns):
    #         title = (entry.findtext("atom:title", namespaces=ns) or "").strip()
    #         link_el = entry.find("atom:link[@rel='alternate']", ns) or entry.find("atom:link", ns)
    #         link = (link_el.get("href") if link_el is not None else "").strip()
    #         logging.debug(f"Found Atom entry: title='{title}', link='{link}'")
    #         if title and link:
    #             items.append((title, link))
    logging.debug(f"Total items parsed: {len(items)}")
    # Split into blogs and updates
    # weekly_pattern = re.compile(r"Weekly\s*[–-]\s*\d{4}")
    updates = [(t, u) for t, u in items if normalize_url(u).startswith("https://sujithq.github.io/updates/")]
    blogs = [(t, u) for t, u in items if not normalize_url(u).startswith("https://sujithq.github.io/updates/")]
    logging.debug(f"Updates found: {len(updates)}; Blogs found: {len(blogs)}")

    # Pick exactly one latest for each category: Terraform, GitHub, Azure
    cat_regex = re.compile(r"^(Terraform|GitHub|Azure)\s+Weekly", re.IGNORECASE)
    categories = ["Terraform", "GitHub", "Azure"]
    canonical = {"terraform": "Terraform", "github": "GitHub", "azure": "Azure"}
    selected = {}
    for title, url in updates:
        m = cat_regex.search(title)
        if not m:
            continue
        cat = canonical.get(m.group(1).lower())
        if cat in categories and cat not in selected:
            selected[cat] = (title, url)
        if len(selected) == len(categories):
            break

    # Order updates consistently by category list, include only found ones
    missing = [c for c in categories if c not in selected]
    if missing:
        logging.debug(f"No recent updates found for categories (will fall back to older in feed if present later): {missing}")
    updates_by_category = [selected[c] for c in categories if c in selected]

    return blogs[:BLOG_COUNT], updates_by_category

def replace_section(content, start, end, new_block):
    logging.debug(f"Replacing section in README.md between {start} and {end}.")
    pattern = re.compile(rf"({re.escape(start)})(.*)({re.escape(end)})", re.DOTALL)
    replacement = f"{start}\n{new_block}\n{end}"
    if not pattern.search(content):
        logging.debug("Markers not found, appending new block.")
        return content.rstrip() + "\n\n" + replacement + "\n"
    logging.debug("Markers found, replacing block.")
    return pattern.sub(replacement, content)

def main():
    parser = argparse.ArgumentParser(description="Update blog posts script")
    parser.add_argument('--verbose', action='store_true', help='Enable extensive logging')
    args = parser.parse_args()

    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    logging.info("Script started.")
    if args.verbose:
        logging.debug("Verbose logging enabled.")

    xml = fetch_feed(FEED_URL)
    blogs, updates = parse_items(xml)
    blog_lines = [f"* [{t}]({u})" for t, u in blogs] or ["* _(no blog posts found)_"]
    update_lines = [f"* [{t}]({u})" for t, u in updates] or ["* _(no updates found)_"]
    blog_block = "\n".join(blog_lines)
    update_block = "\n".join(update_lines)

    logging.debug(f"Generated blog block:\n{blog_block}")
    logging.debug(f"Generated updates block:\n{update_block}")
    content = README.read_text(encoding="utf-8")
    logging.debug("Read README.md content.")
    updated = replace_section(content, BLOG_START, BLOG_END, blog_block)
    updated = replace_section(updated, UPDATES_START, UPDATES_END, update_block)
    if updated != content:
        README.write_text(updated, encoding="utf-8")
        logging.info("README updated.")
    else:
        logging.info("No changes needed.")
    logging.info("Script finished.")

if __name__ == "__main__":
    sys.exit(main())