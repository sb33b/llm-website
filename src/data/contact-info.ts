// Single source of truth for contact/company details used across the site
// (footer, About, Contact, Partner page mailto CTA).
//
// These are the real, in-use values. Nothing else in the codebase needs to
// change to update contact details — every page imports from this one file.
// After editing, rebuild (`npm run build`) and re-upload the contents of
// `dist/`.
//
// Social links are intentionally off (all null) — no public accounts yet.
// Set a value to a URL string to make that icon appear in the footer.

export const contactInfo = {
  legalName: 'Last Last Mile Logistics',
  tagline: 'Take your parcel to the LAST last mile.',

  email: {
    general: 'lastlastmile@gmail.com',
    partners: 'lastlastmile@gmail.com',
  },

  phone: {
    display: '+63 917-537-7999',
    href: 'tel:+639175377999',
  },

  address: {
    line1: '5876 Enriquez St.',
    line2: 'Brgy. Poblacion, Makati',
    line3: 'NCR, Philippines, 1210',
  },

  social: {
    // Set to null to hide a link entirely. Facebook is the most common
    // channel for this kind of business in the Philippines — add the URL
    // here if/when a page exists.
    facebook: null as string | null,
    instagram: null as string | null,
    linkedin: null as string | null,
  },

  domain: 'lastlastmile.com', // registered at Namecheap; matches astro.config.mjs `site`
} as const;
