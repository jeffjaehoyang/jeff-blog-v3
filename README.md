# jeffyang.io

Source for [jeffyang.io](https://www.jeffyang.io) ("Read Only Memory"), Jeff Yang's personal blog. Built with [Hugo](https://gohugo.io) and deployed on Vercel.

```bash
brew install hugo                       # extended edition, v0.160.1 (see vercel.json)
hugo server -D                          # http://localhost:1313
hugo new posts/my-new-post/index.md     # new post; put its images in the same folder
scripts/check.sh                        # validate before committing
```

Pushing to `main` deploys to production. Other branches get Vercel preview URLs that include drafts.

See [AGENTS.md](AGENTS.md) for the full guide: repo layout, front matter, images, and conventions.
