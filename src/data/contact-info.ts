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
  legalName: 'Last Last Mile',
  tagline: 'Last-mile delivery, all the way to the last mile.',

  email: {
    general: '[GENERAL_EMAIL@lastlastmile.example]',
    partners: '[PARTNERS_EMAIL@lastlastmile.example]',
  },

  phone: {
    display: '[+63 9XX XXX XXXX]',
    href: 'tel:+639XXXXXXXXX',
  },

  address: {
    line1: '[Street address]',
    line2: '[Barangay, City/Municipality]',
    line3: '[Province, Philippines, ZIP]',
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
