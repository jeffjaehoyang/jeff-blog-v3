# AGENTS.md

Guide for AI coding agents (any tool or harness) and humans working on **jeffyang.io**, Jeff Yang's personal blog.
This file is the single source of truth for how the repo works. `CLAUDE.md` is only a symlink to it, for tools
that look for that filename. Put new instructions here, not in tool-specific files.

## Stack at a glance

- **Hugo extended v0.160.1**, plain static site. No Node, no npm, no CSS framework, no Hugo modules.
- **All templates live in `layouts/`**. They are fully custom and self-contained.
  The `theme = 'ritzy'` line in `hugo.toml` (and anything under `themes/`, `node_modules/`,
  `package*.json`, `assets/`) is a legacy leftover that contributes nothing to the build. Do not edit or rely on it.
- **Hosting: Vercel.** Every push to `main` deploys to production automatically
  (`vercel.json` runs `hugo --gc` with `HUGO_VERSION` pinned). There is no staging.
- **Analytics:** Plausible script in `layouts/_default/baseof.html`.

## Commands

```bash
hugo server -D          # dev server at http://localhost:1313, live reload, includes drafts
hugo server             # preview exactly what will be published (no drafts)
hugo --gc               # production build into public/ (same as Vercel)
scripts/check.sh        # build with warnings-as-errors + content convention checks; run before every commit
hugo new posts/<slug>/index.md   # scaffold a new post (page bundle) from archetypes/posts.md
```

Keep the local Hugo version in sync with `HUGO_VERSION` in `vercel.json`. If you bump one, bump the other.

## Repository map

| Path | What it is |
| --- | --- |
| `hugo.toml` | Site config: title, baseURL, markup settings (raw HTML allowed, Pygments highlighting). |
| `content/posts/` | Blog posts. Older posts are flat files (`<slug>.md`); new posts are bundles (`<slug>/index.md`). |
| `content/about/index.md` | About page. `heading:` overrides the H1 shown on the page. |
| `content/thought.md` | Headless page. Its body is the "Currently thinking about" blurb on the homepage. |
| `content/_index.md` | Homepage front matter only. |
| `layouts/_default/baseof.html` | The HTML shell: `<head>`, SEO/Open Graph tags, **all site CSS** (one inline `<style>` block), navbar, footer. |
| `layouts/index.html` | Homepage: intro, thought blurb, featured post, 5 most recent posts. |
| `layouts/_default/single.html` | Individual post/page. |
| `layouts/_default/list.html` | `/posts/` index and tag listing pages. |
| `layouts/404.html` | Not-found page. |
| `archetypes/posts.md` | Front matter template used by `hugo new posts/...`. |
| `static/` | Copied verbatim to the site root (favicons, web manifest). |
| `public/`, `resources/` | Build output and caches. Git-ignored. Never edit. |

## Writing a new post

1. Scaffold it as a page bundle (folder named after the URL slug, lowercase-kebab-case):

   ```bash
   hugo new posts/my-new-post/index.md
   ```

   The URL becomes `https://www.jeffyang.io/posts/my-new-post/`.

2. Fill in the front matter. Every field below is used by the templates:

   ```yaml
   ---
   title: 'My New Post'
   date: 2026-10-05T09:00:00-04:00
   draft: true            # set to false to publish
   # featured: true       # optional: pins the post in the homepage "Featured" band
   tags: ['Personal Reflection']
   description: 'One sentence shown on the homepage, /posts/, and in link previews.'
   ---
   ```

   - `description` is required in practice. It appears on post cards and as the meta/OG description.
     Replace the archetype placeholder.
   - `tags`: reuse existing tags so they group well. Current tags are `Personal Reflection`,
     `Web Development`, `Developer Tools`, `Algorithms`. Run
     `grep -h '^tags' content/posts/*.md content/posts/*/index.md 2>/dev/null | sort | uniq -c` to see current usage.
   - `featured`: the homepage shows the **newest** post with `featured: true`. To change the featured post,
     move the flag; never hardcode a path in `layouts/index.html`.
   - Posts with a future `date` are not published until that date (Hugo default).

3. Write in Markdown. Use `###` for section headings (the page title is the only H1).
   Fenced code blocks with a language get syntax highlighting. Raw HTML is allowed.
   Attribute blocks such as `{.class}` after a block are enabled.

4. Preview with `hugo server -D`, then set `draft: false`.

## Images

Put images **inside the post's bundle folder** next to `index.md`, and reference them by filename:

```text
content/posts/my-new-post/
├── index.md
├── cover.png
└── architecture.jpg
```

```markdown
{{< figure src="cover.png" alt="What the image shows" >}}

{{< figure src="architecture.jpg" alt="Service architecture diagram" caption="How the pieces fit together." >}}
```

- Prefer the built-in `figure` shortcode. It outputs an absolute path such as `/posts/my-new-post/cover.png`,
  which also works in RSS readers. Plain Markdown `![alt](cover.png)` works on the page but
  emits a relative URL that breaks in feeds.
- By convention the first element of a post is a cover `figure`.
- Always give meaningful `alt` text. Use `caption` for visible captions.
- Images render full content width (620px column). There is no automatic resizing, so export images at
  roughly 1240px wide (2x) and keep each file under ~500 KB. Use JPEG/WebP for photos, PNG for diagrams.
  GIFs work but get large fast.
- Use lowercase-kebab-case filenames without spaces.
- Images shared across several pages can go in `static/images/` and be referenced as `/images/<file>`.
- Older posts embed images from Dropbox URLs (`...&raw=1`). Leave them as they are unless asked to migrate them.
  Do not add new Dropbox or other third-party-hosted images.

## Other common edits

- **Change the "Currently thinking about" blurb:** edit the body of `content/thought.md`. Keep it to one sentence.
- **Change the About page:** `content/about/index.md`.
- **Styling:** all CSS is in the `<style>` block in `layouts/_default/baseof.html`. Some layouts also use inline
  `style=""` attributes. Palette: text `#4a4b4f`, accent `#8f6a60`, muted `#9d9d9d`, background `#faf8f5`;
  font Source Serif Pro. Keep the minimal, single-column look.
- **Nav links / footer:** in `baseof.html`.

## Rules for agents

- **Do not push to `main` or merge without explicit permission.** A push deploys straight to production.
- Never edit `public/` or `resources/`. They are generated.
- Do not introduce Node/npm, a CSS framework, or a Hugo theme/module. Keep the site dependency-free.
- Do not change `baseURL` or permalink structure. Existing post URLs must keep working.
- Do not rename or move existing post files. That changes their URLs.
- Preserve the author's voice. When asked to edit prose, make the requested changes and do not rewrite the rest.

## Verify before you finish

1. `scripts/check.sh` prints `OK`. It builds like production with warnings treated as errors, and checks
   that published posts have a title, date, tags, and a real description.
2. With `hugo server -D` running, check the changed pages render. For posts, check
   the homepage card, `/posts/`, and the post page itself (images load, code is highlighted).
3. `git status` shows only the files you meant to change (no `public/` output).
