---
name: reader
description: Fetch a web page as clean readable text or markdown with the `reader` CLI. Use instead of WebFetch when a page needs readability extraction, when a domain is not on the fetch allowlist, or when the user wants the article saved to a file.
---

Run `reader <url>` for a readability-cleaned, pretty-printed view. Add `-o` for raw markdown, `--raw` for plain text, `-r` to skip readability, `-w <cols>` to set width, `--eml` when the input is an email file.

To save: `reader -o <url> > <file>.md`, then report the path and size and show the first lines.

Prefer `reader` over WebFetch for articles, documentation, and any page where you need the full body rather than a summary.
