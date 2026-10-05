# AGENTS.md

Guide for AI coding agents (any tool or harness) and humans working on **jeffyang.io**, Jeff Yang's personal blog,
branded **Read Only Memory**. This file is the single source of truth for how the repo works. `CLAUDE.md` is only a
symlink to it, for tools that look for that filename. Put new instructions here, not in tool-specific files.

## Stack at a glance

- **Hugo extended v0.160.1**, plain static site. No Node, no npm, no CSS framework, no Hugo modules.
- **All templates live in `layouts/`**. They are fully custom; there is no theme.
- **Hosting: Vercel.** Every push to `main` deploys to production. Other branches get preview deployments
  that include drafts (see "Publishing workflow").
- **Analytics:** Plausible, loaded only in production builds.

## Commands

```bash
hugo server -D                   # dev server at http://localhost:1313, live reload, includes drafts
hugo server                      # preview exactly what will be published (no drafts)
scripts/check.sh                 # production build (warnings = errors) + content checks; run before every commit
hugo new posts/<slug>/index.md   # scaffold a new post (page bundle) from archetypes/posts.md
hugo --gc                        # production build into public/ (what Vercel runs on main)
```

Keep the local Hugo version in sync with `HUGO_VERSION` in `vercel.json`. If you bump one, bump the other.

## Repository map

| Path | What it is |
| --- | --- |
| `hugo.toml` | Site config: title, baseURL, markup, RSS limit, related-posts weights, resource publishing. |
| `content/posts/<slug>/index.md` | A post (page bundle) with its images in the same folder. One old post is still a flat `<slug>.md`. |
| `content/about/index.md` | About page. `heading:` overrides the H1 shown on the page. |
| `content/thought.md` | Headless page. Its body is the "Currently thinking about" blurb on the homepage. |
| `content/_index.md` | Homepage front matter only. |
| `layouts/_default/baseof.html` | HTML shell: `<head>` (SEO, canonical, Open Graph, fonts), **all site CSS** in one `<style>` block, navbar, footer. |
| `layouts/index.html` | Homepage: intro, thought blurb, featured post, 5 most recent posts. |
| `layouts/_default/single.html` | Post/page template, including Older/Newer links and "Related writing". |
| `layouts/_default/list.html` | `/posts/` index and tag listing pages. |
| `layouts/_default/rss.xml` | Full-text RSS feed (`/posts/index.xml`, tag feeds). |
| `layouts/partials/image.html` | Responsive image pipeline (resize to WebP, srcset). |
| `layouts/shortcodes/figure.html` | Overrides Hugo's `figure` shortcode to use the image pipeline. |
| `layouts/_default/_markup/render-image.html` | Sends Markdown `![]()` images through the same pipeline. |
| `layouts/404.html` | Not-found page. |
| `archetypes/posts.md` | Front matter template used by `hugo new posts/...`. |
| `static/` | Copied verbatim to the site root: favicons, web manifest, `fonts/` (self-hosted Source Serif Pro). |
| `scripts/check.sh` | Pre-commit validation. |
| `vercel.json` | Build command and pinned Hugo version. |
| `public/`, `resources/` | Build output and caches. Git-ignored. Never edit. |

## Writing a new post

1. Scaffold it as a page bundle (folder named after the URL slug, lowercase-kebab-case):

   ```bash
   hugo new posts/my-new-post/index.md
   ```

   The URL becomes `https://www.jeffyang.io/posts/my-new-post/`.

2. Fill in the front matter:

   ```yaml
   ---
   title: 'My New Post'
   date: 2026-10-05T09:00:00-04:00
   draft: true            # set to false to publish
   # featured: true       # optional: pins the post in the homepage "Featured" band
   cover: cover.png       # optional but recommended: lead image in the bundle, also the link-preview image
   tags: ['Personal Reflection']
   description: 'One sentence shown on the homepage, /posts/, RSS, and in link previews.'
   ---
   ```

   - `description` is required for published posts (`scripts/check.sh` enforces it). Replace the archetype placeholder.
   - `tags` drive tag pages and "Related writing". Reuse existing tags so posts group well:
     `Personal Reflection`, `Web Development`, `Developer Tools`, `Algorithms`, `Data Infrastructure`.
     Check current usage with `grep -rh '^tags' content/posts | sort | uniq -c`.
   - `cover` names an image file in the bundle. It becomes the 1200px `og:image`/`twitter:image` and loads
     eagerly when used in a `figure`. Without it, link previews fall back to the site icon.
   - `featured`: the homepage shows the **newest** post with `featured: true`. To change the featured post,
     move the flag; never hardcode a path in `layouts/index.html`.
   - Posts with a future `date` are not published until that date (Hugo default).

3. Write in Markdown. Use `###` for section headings (the page title is the only H1).
   Fenced code blocks with a language get syntax highlighting. Raw HTML is allowed.
   Attribute blocks such as `{.class}` after a block are enabled.
   HTML comments in content are published in page source, so remove draft notes before publishing.

4. Preview with `hugo server -D`, run `scripts/check.sh`, then set `draft: false`.

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

- By convention a post starts with its cover `figure`, and `cover:` in front matter names the same file.
- The `figure` shortcode supports `src`, `alt`, `caption` (Markdown allowed), `link`, and `class`.
  `alt` defaults to the caption. Always give meaningful alt text.
- Plain Markdown `![alt text](diagram.png)` also works and goes through the same pipeline, without a caption.
- **Commit the original, full-size image.** The build resizes JPEG/PNG/WebP to 640px and 1280px WebP
  with `srcset`, width/height, and lazy loading. Only the resized files are deployed. GIFs and SVGs are served
  as-is, so keep GIFs small (under ~2 MB).
- File extensions must match the real format. Hugo fails on, for example, WebP data saved as `.png`.
- Use lowercase-kebab-case filenames without spaces.
- Never hotlink third-party-hosted images (Dropbox, Imgur, etc.). `scripts/check.sh` rejects them.
- Files in `static/` are not processed. Only use `static/` for site-wide assets such as icons.

## Other common edits

- **"Currently thinking about" blurb:** edit the body of `content/thought.md`. Keep it to one sentence.
- **About page:** `content/about/index.md`.
- **Site name / tagline:** `title` and `params.description` in `hugo.toml`. The navbar, tab titles, previews,
  and RSS all read from there.
- **Styling:** all CSS is in the `<style>` block in `layouts/_default/baseof.html`. Some layouts also use inline
  `style=""` attributes. Palette: text `#4a4b4f`, accent `#8f6a60`, muted `#9d9d9d`, background `#faf8f5`.
  Font: self-hosted Source Serif Pro, weights 400 and 600 only. Keep the minimal, single-column look.
- **Nav links / footer:** in `baseof.html`.

## Publishing workflow

- **Quick publish:** commit to `main` with `draft: false` and push. Vercel deploys production.
- **Proofread first:** push the post on a branch (it can stay `draft: true`). Vercel builds a preview deployment
  that includes drafts and future-dated posts. Previews are marked `noindex` and skip analytics.
  When it looks right, set `draft: false` and merge to `main`.

## Rules for agents

- **Do not push to `main` or merge without explicit permission.** A push deploys straight to production.
- Never edit `public/` or `resources/`. They are generated.
- Do not introduce Node/npm, a CSS framework, a Hugo theme/module, or third-party scripts and fonts.
- Do not change `baseURL` or the permalink structure. Existing post URLs must keep working. Converting
  `posts/<slug>.md` into `posts/<slug>/index.md` is fine because the URL stays the same. Renaming a slug is not.
- Do not write or invent first-person experiences for Jeff. For posts, outline or edit only what he provides.
- Preserve the author's voice. When asked to edit prose, make the requested changes and do not rewrite the rest.

## Verify before you finish

1. `scripts/check.sh` prints `OK`. It builds like production with warnings treated as errors, checks
   published posts' front matter, and checks every `figure`/`cover` file exists and no images are hotlinked.
2. With `hugo server -D` running, check the changed pages render. For posts, check
   the homepage card, `/posts/`, and the post page itself (images load, code is highlighted).
3. `git status` shows only the files you meant to change (no `public/` output).
