#!/usr/bin/env python3
"""Lint script for wiki health check."""
import os
import re

wiki_dirs = ['wiki/sources', 'wiki/entities', 'wiki/concepts', 'wiki/analyses']

# All page slugs
all_pages = set()
for d in wiki_dirs:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.endswith('.md'):
                all_pages.add(f[:-3])

# All linked page names
wikilink_re = re.compile(r'\[\[([^\]|#]+)(?:[|#][^\]]*)?\]\]')
all_linked = set()
for d in wiki_dirs:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.endswith('.md'):
                with open(os.path.join(d, f)) as fh:
                    for m in wikilink_re.findall(fh.read()):
                        all_linked.add(m.strip())

orphans = all_pages - all_linked
broken = all_linked - all_pages

print(f"Total pages: {len(all_pages)}, Linked targets seen: {len(all_linked)}")
print(f"\nOrphan pages (no inbound links) — {len(orphans)}:")
for o in sorted(orphans):
    print(f"  {o}")

print(f"\nBroken wikilinks (target page doesn't exist) — {len(broken)}:")
for b in sorted(broken):
    print(f"  {b}")

# Index gap check
index_pages = set()
if os.path.isfile('wiki/index.md'):
    with open('wiki/index.md') as fh:
        for m in wikilink_re.findall(fh.read()):
            index_pages.add(m.strip())

not_in_index = all_pages - index_pages
print(f"\nPages not listed in index.md — {len(not_in_index)}:")
for p in sorted(not_in_index):
    print(f"  {p}")
