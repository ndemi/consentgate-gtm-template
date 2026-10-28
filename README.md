# ConsentGate CMP for Google Tag Manager

Tag template that installs the [ConsentGate](https://consentgate.eu) cookie consent window through Google Tag Manager, with Google Consent Mode v2.

## What it does

- Sets the default consent state to `denied` for all Consent Mode signals before any other tag fires (`security_storage` stays `granted`).
- Applies a visitor's earlier decision from the ConsentGate cookie right away, so tags on the page see it without waiting for the window to load.
- Loads the ConsentGate consent window for your site.
- Does nothing if the ConsentGate code is already pasted into the page, so the window never loads twice.

## Setup

1. Add the template to your container and create a new tag with it.
2. Enter your site ID. You find it in the ConsentGate panel under Install.
3. Trigger: **Consent Initialization - All Pages**.
4. Do not also paste the ConsentGate code into the page. Use one or the other.

Optional settings: time to wait for the visitor's decision (`wait_for_update`), redacting ad data before consent (`ads_data_redaction`), passing ad click parameters in links without consent (`url_passthrough`), and a different default state for selected countries.

Non-Google tags (Meta Pixel, LinkedIn Insight, TikTok, Hotjar, custom HTML) must wait for consent. Fire them on the `cg_consent_update` custom event with a condition on the matching Data Layer Variable (`cg_consent.analytics` or `cg_consent.marketing` equals `true`), and require additional consent in the tag's Consent Settings.

Step-by-step guide: <https://consentgate.eu/en/guides/set-up-consent-window-in-google-tag-manager/>

## License

Apache License 2.0. See [LICENSE](LICENSE).
