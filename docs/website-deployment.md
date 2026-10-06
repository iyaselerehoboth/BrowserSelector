# Landing page deployment

The public-facing site is self-contained in `website/`. It requires no Node dependencies, build step, analytics service, or external fonts. Its interactive picker is an illustration, not a connection to the installed app.

## Preview

```bash
python3 -m http.server 8000 --directory website
```

Visit `http://localhost:8000`. Verify narrow and wide layouts, keyboard navigation, demo selection/remembering, FAQ disclosure, and setup links.

## Publish on GitHub Pages

1. Commit and push the site and `.github/workflows/pages.yml` to `master`.
2. Open repository **Settings → Pages → Build and deployment** and select **GitHub Actions** as the source.
3. In **Actions → Deploy landing page**, choose **Run workflow**, or push a change to `website/` on `master`.
4. Wait for the deployment to finish. The workflow environment supplies the published URL, normally `https://iyaselerehoboth.github.io/BrowserSelector/`.

All site asset paths are relative, so the GitHub Pages project subpath works without rewriting URLs. The workflow uploads only `website/`, not repository development documents.

This repository is public and is eligible for GitHub Pages on GitHub Free. If you later make it private, Pages requires an eligible paid plan, and private repository release assets will require visitors to have repository access.

Official guidance: [custom Pages workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages) and [creating a Pages site](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site).

## Enable public downloads

Version 1.0.4 is linked from the landing page. For future releases:

1. Build and validate a DMG using `scripts/package-dmg.sh`.
2. Publish the DMG and checksum to a release or download host that your visitors can actually access. Preserve corresponding source and GPL attribution.
3. Replace the download availability message and repository CTA in `website/index.html` with the verified package link. Keep the installation/signing information consistent with that build.
4. Test the download while signed out of GitHub. Private release assets will not work for public visitors.

The inherited app release workflow is separate from the Pages workflow and requires adaptation for this fork before use. Pages deployment does not build, sign, notarize, or publish the macOS app.
