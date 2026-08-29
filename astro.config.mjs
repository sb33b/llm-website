import { defineConfig } from 'astro/config';

// Last Last Mile marketing site — static output only, deployed by uploading
// the contents of dist/ to cPanel. See README.md for the full deploy flow.
export default defineConfig({
  site: 'https://lastlastmile.com',

  build: {
    // Flat "about.html" instead of Astro's default "about/index.html".
    // This keeps download.html unambiguous from the /download redirect
    // shortlink defined in public/.htaccess — see README.md.
    format: 'file',
  },
});
