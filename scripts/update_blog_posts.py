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
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime

README = Path("README.md")
FEED_URL = "https://sujithq.github.io/index.xml"
BLOG_START = "<!-- BLOG-POST-LIST:START -->"
BLOG_END = "<!-- BLOG-POST-LIST:END -->"
UPDATES_START = "<!-- UPDATES-LIST:START -->"
UPDATES_END = "<!-- UPDATES-LIST:END -->"
BLOG_COUNT = 10
UPDATES_COUNT = 6

def normalize_url(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)       # unicode normalize
    s = s.strip()                               # trim whitespace
    s = re.sub(r'[\u200B-\u200D\uFEFF]', '', s) # remove ZWSP/ZWJ/ZWNJ/BOM
    return s

def parse_date(text: str):
    """Parse common RSS/Atom date formats into timezone-aware datetime."""
    if not text:
        return None
    s = text.strip()
    # Try RFC2822 (RSS pubDate)
    try:
        dt = parsedate_to_datetime(s)
        if dt is not None and dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        pass
    # Try ISO-8601 (Atom updated/published)
    try:
        if s.endswith("Z"):
            s = s[:-1] + "+00:00"
        dt = datetime.fromisoformat(s)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None

def fetch_feed(url):
    logging.debug(f"Fetching RSS/Atom feed from {url}")
    with urllib.request.urlopen(url) as resp:
        data = resp.read()
    logging.debug(f"Fetched {len(data)} bytes from feed.")
    return data

def parse_items(xml_bytes):
    logging.debug("Parsing feed XML for items.")
    root = ET.fromstring(xml_bytes)
    items = []  # (title, link, datetime)
    # RSS 2.0
    for item in root.findall(".//item"):
        title = (item.findtext("title") or "").strip()
        link = (item.findtext("link") or "").strip()
        date_text = (
            item.findtext("pubDate")
            or item.findtext("{http://purl.org/dc/elements/1.1/}date")
            or item.findtext("lastmod")
            or item.findtext("modified")
        )
        dt = parse_date(date_text) or datetime.min.replace(tzinfo=timezone.utc)
        logging.debug(f"Found RSS item: title='{title}', link='{link}', date='{date_text}' -> {dt}")
        if title and link:
            items.append((title, link, dt))
    # Atom fallback
    if not items:
        ns = {"atom": "http://www.w3.org/2005/Atom"}
        for entry in root.findall(".//atom:entry", ns):
            title = (entry.findtext("atom:title", namespaces=ns) or "").strip()
            link_el = entry.find("atom:link[@rel='alternate']", ns) or entry.find("atom:link", ns)
            link = (link_el.get("href") if link_el is not None else "").strip()
            date_text = entry.findtext("atom:updated", namespaces=ns) or entry.findtext("atom:published", namespaces=ns)
            dt = parse_date(date_text) or datetime.min.replace(tzinfo=timezone.utc)
            logging.debug(f"Found Atom entry: title='{title}', link='{link}', date='{date_text}' -> {dt}")
            if title and link:
                items.append((title, link, dt))
    logging.debug(f"Total items parsed: {len(items)}")
    # Split into blogs and updates
    updates = [(t, u, d) for t, u, d in items if normalize_url(u).startswith("https://sujithq.github.io/updates/")]
    blogs = [(t, u, d) for t, u, d in items if normalize_url(u).startswith("https://sujithq.github.io/posts/")]
    logging.debug(f"Updates found: {len(updates)}; Blogs found: {len(blogs)}")

    # Blogs: newest N by date
    blogs_sorted = sorted(blogs, key=lambda x: x[2], reverse=True)[:BLOG_COUNT]
    blog_pairs = [(t, u) for t, u, _ in blogs_sorted]

    # Updates: latest by date per category
    cat_regex = re.compile(r"^(terraform|github|azure|security|dotnet|ai):", re.IGNORECASE)
    categories = ["Terraform", "GitHub", "Azure" , "Security", "DotNet", "AI"]
    canonical = {"terraform": "Terraform", "github": "GitHub", "azure": "Azure" , "security": "Security", "dotnet": "DotNet", "ai": "AI"}
    latest_per_cat = {}
    for title, url, dt in updates:
        m = cat_regex.search(title)
        if not m:
            continue
        cat = canonical.get(m.group(1).lower())
        prev = latest_per_cat.get(cat)
        if prev is None or dt > prev[2]:
            latest_per_cat[cat] = (title, url, dt)
            logging.debug(f"Selected/updated latest for {cat}: {title} ({dt})")

    missing = [c for c in categories if c not in latest_per_cat]
    if missing:
        logging.debug(f"Missing categories (no items found in feed window): {missing}")

    updates_by_category = [(latest_per_cat[c][0], latest_per_cat[c][1]) for c in categories if c in latest_per_cat]

    return blog_pairs, updates_by_category

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