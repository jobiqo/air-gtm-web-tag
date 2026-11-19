# Jobiqo AIR Tracking — web GTM tag template

Sends job views and conversions from traffic of Jobiqo AIR campaigns to the Jobiqo AIR Tracking API, from a **web (client-side) Google Tag Manager** container.

- Tracks **AIR traffic only**: visits whose landing URL contains `air_campaign_item_id`.
- **Never delays or blocks** other tags: the tag reports success immediately and does not wait for the request.
- Keeps its **own session**, so it works with or without Google Analytics 4.

If the website has a server-side GTM container, consider [air-gtm-server-tag](https://github.com/jobiqo/air-gtm-server-tag) instead: its cookies last longer in Safari and ad blockers drop fewer events.

## Requirements

- A web GTM container on the website.
- If the website uses a consent banner, fire the tag only after the required consent (see [Consent](#consent)).

## Installation

**From the Community Template Gallery:** in your web container, go to Templates → Tag Templates → Search Gallery, search for "Jobiqo AIR Tracking" and add it.

**Manually:** download `template.tpl`, then go to Templates → Tag Templates → New → ⋮ → Import.

## Configuration

| Field | Description |
|---|---|
| Event type | **Fixed event type**: choose `view`, `apply`, `apply_finish`, `registration_start` or `registration_complete` from the dropdown. **From a variable**: select a variable, e.g. a lookup table, that returns one of those values. Unknown values are skipped. |
| Conversion attribution | **Same AIR session only** (default): the stored landing URL is used only within the same AIR session (30 minutes of inactivity ends it). **Within an attribution window**: used until the window expires. |
| Attribution window | 1, 7, 30 or 90 days. Shown only in window mode. Safari limits cookies set by scripts to 7 days. |
| Mark all events as test events | Sets `is_test` on every event, e.g. on a staging environment. Events from GTM preview are always marked as test. |
| Logs settings | Do not log / log during debug and preview (default) / always log to the browser console. |

### Example setup

Create one tag per event type with a **Fixed event type**, or one tag with Event type set to **From a variable** and a lookup table:

| Tag | Event type | Trigger |
|---|---|---|
| AIR – Job view | `view` | Page View on job detail pages |
| AIR – Apply start | `apply` | Click on the Apply button |
| AIR – Apply finish | `apply_finish` | Application submitted (e.g. thank-you page or a dataLayer event) |

The tag checks for AIR traffic itself, so the triggers do not need a condition on `air_campaign_item_id`.

### Consent

The tag sets two functional cookies and sends the page URL, referrer and user agent to Jobiqo. Whether consent is required depends on the website's legal assessment. To require consent, use GTM's built-in consent settings on the tag (Advanced Settings → Consent Settings) or add a consent condition to the triggers.

## How it works

1. **Job view on an AIR landing URL:** the tag starts or continues an AIR session, stores the landing URL in a cookie, and sends a `view`.
2. **Apply start:** sent only when the current page is an AIR landing URL. An apply on another job is not attributed to the AIR job.
3. **Apply finish and registration events:** use the current URL when it has AIR parameters. Otherwise they use the stored landing URL, within the configured attribution.
4. **Visitors without AIR context:** nothing is sent and no cookies are set. An existing AIR session is kept alive.

Every apply finish is sent; there is no deduplication.

### Cookies

| Name | Content | Lifetime |
|---|---|---|
| `_air_session` | Random AIR session ID | 30 minutes, renewed on every tracked event |
| `_air_url` | Session ID and AIR landing URL | 24 hours in session mode; the attribution window in window mode |

Both are first-party, `Secure` and `SameSite=Lax`. The tag also reads the `_ga` cookie, if present, to send the GA4 client ID.

## Request

`GET https://air.jobiqo.com/campaign-tracking` with the fields as URL-encoded query parameters. The fields are the same as in the server-side template, except `user_agent`: GTM templates cannot read `navigator.userAgent`, and the browser sends the visitor's user agent as the request's `User-Agent` header.

| Field | Description |
|---|---|
| `event_type` | The configured event type |
| `session_id` | AIR session ID |
| `url` | AIR landing URL, including its query parameters |
| `referrer` | `document.referrer` |
| `integration` | `web` |
| `template_version` | Template version, e.g. `1.0.0` |
| `is_test` | `true` in preview mode or when test mode is on, otherwise `false` |
| `ga_client_id` | GA4 client ID from the `_ga` cookie, only when available |

## Testing

1. Open the container in Preview mode.
2. Visit a job page with `?air_campaign_item_id=test` in the URL.
3. Check that the tag fired. In the browser console, look for the `Request` log line, and in the Network tab for the request to `air.jobiqo.com`.
4. Check that the `_air_session` and `_air_url` cookies exist on the website's domain.
5. Complete an application and check that `apply_finish` is sent with the original landing URL.

Events from preview mode are marked `is_test=true`.

The template also contains unit tests: open the template in the template editor, go to **Tests** and click **Run tests**.

## Releasing a new version

1. Edit the template in the GTM template editor, not by hand.
2. Update `TEMPLATE_VERSION` at the top of the code.
3. Run the tests, export the template and replace `template.tpl`.
4. Commit and push.
5. Add the new commit SHA at the top of `versions` in `metadata.yaml`, with change notes, and push again.

The gallery usually picks up the new version within a few days.

## Support

Report problems via the [issues]([https://github.com/jobiqo/jobiqo-air-tracking-web/issues](https://github.com/jobiqo/air-gtm-web-tag/issues)) of this repository.

## License

Apache License 2.0, see [LICENSE](LICENSE).
