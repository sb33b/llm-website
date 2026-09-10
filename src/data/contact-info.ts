// Single source of truth for contact/company details used across the site
// (footer, About, Contact, Partner page mailto CTA).
//
// ⚠️ PLACEHOLDER VALUES — none of this is real. Replace every field below
// with actual company details before going live. Every value that still
// needs a real answer is wrapped in [BRACKETS] so it's easy to grep for:
//
//   grep -rn "\[" src/data/contact-info.ts
//
// Nothing else in the codebase needs to change — every page imports from
// this one file.

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
    // channel for this kind of business in the Philippines — confirm if
    // one exists.
    facebook: null as string | null,
    instagram: null as string | null,
    linkedin: null as string | null,
  },

  domain: 'lastlastmile.com', // confirm this is the real registered domain
} as const;
