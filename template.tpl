___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Jobiqo AIR Tracking (web)",
  "categories": [
    "CONVERSIONS",
    "ATTRIBUTION"
  ],
  "brand": {
    "id": "brand_dummy",
    "displayName": "Jobiqo"
  },
  "description": "Sends Jobiqo AIR job views and conversions from a web GTM container to the Jobiqo AIR Tracking API. Only AIR traffic is tracked. The tag never delays or blocks other tags.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "RADIO",
    "name": "eventTypeSource",
    "displayName": "Event type",
    "radioItems": [
      {
        "value": "fixed",
        "displayValue": "Fixed event type"
      },
      {
        "value": "variable",
        "displayValue": "From a variable"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "fixed",
    "help": "Choose a fixed event type for this tag, or use a variable (for example a lookup table) to send different event types from one tag."
  },
  {
    "type": "SELECT",
    "name": "eventType",
    "displayName": "",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "view",
        "displayValue": "Job view"
      },
      {
        "value": "apply",
        "displayValue": "Apply start"
      },
      {
        "value": "apply_finish",
        "displayValue": "Apply finish"
      },
      {
        "value": "registration_start",
        "displayValue": "Registration start"
      },
      {
        "value": "registration_complete",
        "displayValue": "Registration complete"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "view",
    "enablingConditions": [
      {
        "paramName": "eventTypeSource",
        "paramValue": "fixed",
        "type": "EQUALS"
      }
    ],
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "alwaysInSummary": true
  },
  {
    "type": "TEXT",
    "name": "eventTypeVariable",
    "displayName": "",
    "simpleValueType": true,
    "valueHint": "{{Lookup Table - AIR event type}}",
    "help": "A variable that returns one of: view, apply, apply_finish, registration_start, registration_complete. Other values are skipped.",
    "enablingConditions": [
      {
        "paramName": "eventTypeSource",
        "paramValue": "variable",
        "type": "EQUALS"
      }
    ],
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "alwaysInSummary": true
  },
  {
    "type": "RADIO",
    "name": "attribution",
    "displayName": "Conversion attribution",
    "radioItems": [
      {
        "value": "session",
        "displayValue": "Same AIR session only (30 minutes of inactivity ends a session)"
      },
      {
        "value": "window",
        "displayValue": "Within an attribution window"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "session",
    "help": "Apply finish and registration events often happen on pages without AIR parameters. The tag then uses the AIR landing URL stored at the job view. This setting decides how long that stored URL may be used. Note: Safari limits cookies set by scripts to 7 days.",
    "alwaysInSummary": true
  },
  {
    "type": "SELECT",
    "name": "attributionWindowDays",
    "displayName": "Attribution window",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "1",
        "displayValue": "1 day"
      },
      {
        "value": "7",
        "displayValue": "7 days"
      },
      {
        "value": "30",
        "displayValue": "30 days"
      },
      {
        "value": "90",
        "displayValue": "90 days"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "30",
    "enablingConditions": [
      {
        "paramName": "attribution",
        "paramValue": "window",
        "type": "EQUALS"
      }
    ],
    "alwaysInSummary": true
  },
  {
    "type": "CHECKBOX",
    "name": "testMode",
    "checkboxText": "Mark all events as test events",
    "simpleValueType": true,
    "defaultValue": false,
    "help": "Events sent from GTM preview mode are always marked as test (is_test). Tick this to mark every event as test, for example on a staging environment."
  },
  {
    "type": "GROUP",
    "name": "logsGroup",
    "displayName": "Logs settings",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "RADIO",
        "name": "logType",
        "displayName": "",
        "radioItems": [
          {
            "value": "no",
            "displayValue": "Do not log"
          },
          {
            "value": "debug",
            "displayValue": "Log to console during debug and preview"
          },
          {
            "value": "always",
            "displayValue": "Always log to console"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "debug"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// Jobiqo AIR Tracking (web)

const sendPixel = require('sendPixel');
const getUrl = require('getUrl');
const getReferrerUrl = require('getReferrerUrl');
const getCookieValues = require('getCookieValues');
const setCookie = require('setCookie');
const encodeUriComponent = require('encodeUriComponent');
const generateRandom = require('generateRandom');
const getTimestampMillis = require('getTimestampMillis');
const getContainerVersion = require('getContainerVersion');
const logToConsole = require('logToConsole');
const JSON = require('JSON');


// Constants
const TEMPLATE_VERSION = '1.0.0';
const INTEGRATION = 'web';
const ENDPOINT = 'https://air.jobiqo.com/campaign-tracking';
const SESSION_COOKIE = '_air_session';
const LANDING_COOKIE = '_air_url';
const GA_COOKIE = '_ga';
const AIR_PARAM = 'air_campaign_item_id=';
const SESSION_TIMEOUT_SECONDS = 1800;
const SESSION_MODE_LANDING_MAX_AGE = 86400;
const VALID_EVENTS = ['view', 'apply', 'apply_finish', 'registration_start', 'registration_complete'];
// Only these events may use the stored landing URL; view and apply must happen on an AIR URL
const FALLBACK_EVENTS = ['apply_finish', 'registration_start', 'registration_complete'];


// Config (defaults keep older tag configurations working)
// Event type: a fixed choice, or a variable such as a lookup table.
// Tags saved before eventTypeSource existed have no source and use eventType.
const eventType = data.eventTypeSource === 'variable' ? data.eventTypeVariable : data.eventType;
const attribution = data.attribution || 'session';
const windowDays = (1 * data.attributionWindowDays) || 30;
const containerVersion = getContainerVersion();
const isPreview = !!(containerVersion && (containerVersion.previewMode || containerVersion.debugMode));
const isTest = isPreview || data.testMode === true;
const logEnabled = data.logType === 'always' || (data.logType !== 'no' && isPreview);


// Helpers
function log(type, details) {
    if (!logEnabled) return;
    details.Name = 'JobiqoAIR';
    details.Type = type;
    details.TemplateVersion = TEMPLATE_VERSION;
    logToConsole(JSON.stringify(details));
}

function isAirUrl(u) {
    return !!u && u.indexOf(AIR_PARAM) !== -1;
}

function cookieOptions(maxAgeSeconds) {
    return {
        domain: 'auto',
        path: '/',
        'max-age': maxAgeSeconds,
        secure: true,
        samesite: 'Lax'
    };
}

function newSessionId() {
    return getTimestampMillis() + '.' + generateRandom(100000000, 999999999);
}

// _ga cookie format: GA1.1.<random>.<timestamp> -> client ID is the last two parts
function parseGaClientId(gaCookie) {
    if (!gaCookie) return undefined;
    const parts = gaCookie.split('.');
    if (parts.length < 4) return undefined;
    return parts[parts.length - 2] + '.' + parts[parts.length - 1];
}

function skip(reason) {
    log('Skipped', { EventType: eventType, Reason: reason });
    data.gtmOnSuccess();
}


// 1. Validate event type
if (VALID_EVENTS.indexOf(eventType) === -1) {
    return skip('unknown event type "' + eventType + '"');
}


// 2. Read current state
const pageUrl = getUrl();
const pageIsAir = isAirUrl(pageUrl);
const existingSessionId = getCookieValues(SESSION_COOKIE)[0];
const storedLanding = getCookieValues(LANDING_COOKIE)[0];


// 3. Resolve the AIR landing URL for this event
let url;
let urlSource;

if (pageIsAir) {
    url = pageUrl;
    urlSource = 'page';
} else if (FALLBACK_EVENTS.indexOf(eventType) !== -1 && storedLanding) {
    const sep = storedLanding.indexOf('|');
    const storedSessionId = sep > -1 ? storedLanding.substring(0, sep) : '';
    const storedUrl = sep > -1 ? storedLanding.substring(sep + 1) : '';
    const sameSession = !!existingSessionId && storedSessionId === existingSessionId;

    if (attribution === 'window' || sameSession) {
        url = storedUrl;
        urlSource = 'cookie';
    }
}


// 4. Not AIR traffic: only keep an existing AIR session alive, set nothing new
if (!isAirUrl(url)) {
    if (existingSessionId) {
        setCookie(SESSION_COOKIE, existingSessionId, cookieOptions(SESSION_TIMEOUT_SECONDS));
    }
    return skip('no AIR landing URL for this event');
}


// 5. AIR session (sliding 30-minute expiry)
const sessionId = existingSessionId || newSessionId();
setCookie(SESSION_COOKIE, sessionId, cookieOptions(SESSION_TIMEOUT_SECONDS));

if (eventType === 'view' && urlSource === 'page') {
    const landingMaxAge = attribution === 'window' ? windowDays * 86400 : SESSION_MODE_LANDING_MAX_AGE;
    setCookie(LANDING_COOKIE, sessionId + '|' + url, cookieOptions(landingMaxAge));
}


// 6. Build query string (same fields as the server-side JSON payload).
// No user_agent field: GTM does not allow templates to read navigator.userAgent,
// and the browser already sends its User-Agent header with this request.
const params = [
    ['event_type', eventType],
    ['session_id', sessionId],
    ['url', url],
    ['referrer', getReferrerUrl() || ''],
    ['integration', INTEGRATION],
    ['template_version', TEMPLATE_VERSION],
    ['is_test', isTest ? 'true' : 'false']
];

const gaClientId = parseGaClientId(getCookieValues(GA_COOKIE)[0]);
if (gaClientId) {
    params.push(['ga_client_id', gaClientId]);
}

const pixelUrl = ENDPOINT + '?' + params.map(function(p) {
    return p[0] + '=' + encodeUriComponent(p[1]);
}).join('&');


// 7. Send without waiting: this tag must never delay other tags
log('Request', { EventType: eventType, UrlSource: urlSource, RequestUrl: pixelUrl });

sendPixel(pixelUrl, function() {
    log('Response', { EventType: eventType, Accepted: true });
}, function() {
    log('Response', { EventType: eventType, Accepted: false });
});

data.gtmOnSuccess();


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "get_url",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_referrer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "_air_session"
              },
              {
                "type": 1,
                "string": "_air_url"
              },
              {
                "type": 1,
                "string": "_ga"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "set_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedCookies",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "_air_session"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "_air_url"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_pixel",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://air.jobiqo.com/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "all"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: view_airLanding_newVisitor_sendsFullPayload
  code: |-
    // First AIR landing: new session, landing URL stored, all fields sent

    runCode(getMockData({}));

    const q = sentParams();
    assertApi('gtmOnSuccess').wasCalled();
    assertThat(pixelUrl.indexOf(ENDPOINT + '?')).isEqualTo(0);
    assertThat(q.event_type).isEqualTo('view');
    assertThat(q.session_id).isEqualTo(NEW_SESSION);
    assertThat(q.url).isEqualTo(AIR_URL);
    assertThat(q.referrer).isEqualTo(REFERRER);
    assertThat(q.user_agent).isUndefined();
    assertThat(q.integration).isEqualTo('web');
    assertThat(q.template_version).isEqualTo('1.0.0');
    assertThat(q.is_test).isEqualTo('false');
    assertThat(q.ga_client_id).isEqualTo('111.222');
    assertThat(cookiesSet._air_session.value).isEqualTo(NEW_SESSION);
    assertThat(cookiesSet._air_session.options['max-age']).isEqualTo(1800);
    assertThat(cookiesSet._air_url.value).isEqualTo(NEW_SESSION + '|' + AIR_URL);
    assertThat(cookiesSet._air_url.options['max-age']).isEqualTo(86400);
- name: view_airLanding_existingSession_keepsSession
  code: |-
    // A new AIR landing within an active session keeps the session ID

    cookieJar._air_session = EXISTING_SESSION;

    runCode(getMockData({}));

    assertThat(sentParams().session_id).isEqualTo(EXISTING_SESSION);
    assertThat(cookiesSet._air_url.value).isEqualTo(EXISTING_SESSION + '|' + AIR_URL);
- name: view_noAir_noSession_nothingSentNoCookies
  code: |-
    // Non-AIR visitor: no request and no cookies at all

    pageUrl = OTHER_JOB_URL;

    runCode(getMockData({}));

    assertApi('sendPixel').wasNotCalled();
    assertApi('setCookie').wasNotCalled();
    assertApi('gtmOnSuccess').wasCalled();
- name: view_noAir_existingSession_onlyRefreshesSession
  code: |-
    // AIR visitor browsing another job: session kept alive, nothing sent

    pageUrl = OTHER_JOB_URL;
    cookieJar._air_session = EXISTING_SESSION;
    cookieJar._air_url = EXISTING_SESSION + '|' + AIR_URL;

    runCode(getMockData({}));

    assertApi('sendPixel').wasNotCalled();
    assertThat(cookiesSet._air_session.value).isEqualTo(EXISTING_SESSION);
    assertThat(cookiesSet._air_url).isUndefined();
- name: apply_noAirPage_withLandingCookie_notSent
  code: |-
    // Apply on a non-AIR job must not be attributed to the AIR job

    pageUrl = OTHER_JOB_URL;
    cookieJar._air_session = EXISTING_SESSION;
    cookieJar._air_url = EXISTING_SESSION + '|' + AIR_URL;

    runCode(getMockData({ eventType: 'apply' }));

    assertApi('sendPixel').wasNotCalled();
    assertApi('gtmOnSuccess').wasCalled();
- name: applyFinish_sameSession_usesStoredUrl
  code: |-
    // Apply finish on a thank-you page within the same AIR session

    pageUrl = PLAIN_URL;
    cookieJar._air_session = EXISTING_SESSION;
    cookieJar._air_url = EXISTING_SESSION + '|' + AIR_URL;

    runCode(getMockData({ eventType: 'apply_finish' }));

    const q = sentParams();
    assertThat(q.event_type).isEqualTo('apply_finish');
    assertThat(q.url).isEqualTo(AIR_URL);
    assertThat(q.session_id).isEqualTo(EXISTING_SESSION);
- name: applyFinish_expiredSession_sessionMode_notSent
  code: |-
    // Session cookie expired: no attribution in session mode

    pageUrl = PLAIN_URL;
    cookieJar._air_url = EXISTING_SESSION + '|' + AIR_URL;

    runCode(getMockData({ eventType: 'apply_finish' }));

    assertApi('sendPixel').wasNotCalled();
    assertApi('setCookie').wasNotCalled();
- name: applyFinish_expiredSession_windowMode_sendsWithNewSession
  code: |-
    // In window mode the stored URL is used after the session ended

    pageUrl = PLAIN_URL;
    cookieJar._air_url = EXISTING_SESSION + '|' + AIR_URL;

    runCode(getMockData({ eventType: 'apply_finish', attribution: 'window' }));

    const q = sentParams();
    assertThat(q.url).isEqualTo(AIR_URL);
    assertThat(q.session_id).isEqualTo(NEW_SESSION);
- name: windowMode_landingCookieFollowsWindow
  code: |-
    // Landing cookie lifetime follows the selected attribution window

    runCode(getMockData({ attribution: 'window', attributionWindowDays: '7' }));

    assertThat(cookiesSet._air_url.options['max-age']).isEqualTo(7 * 86400);
- name: previewMode_marksTest
  code: |-
    // Events from GTM preview are always test events

    containerVersion.previewMode = true;

    runCode(getMockData({}));

    assertThat(sentParams().is_test).isEqualTo('true');
- name: noGaCookie_fieldOmitted
  code: |-
    // Without a _ga cookie the GA client ID is left out

    cookieJar._ga = undefined;

    runCode(getMockData({}));

    assertThat(sentParams().ga_client_id).isUndefined();
- name: neverWaitsForAir
  code: |-
    // The tag succeeds immediately, even if the pixel never loads

    mock('sendPixel', function(url, onSuccess, onFailure) {
        pixelUrl = url;
    });

    runCode(getMockData({}));

    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
- name: pixelFailure_tagStillSucceeds
  code: |-
    // A failed pixel is only logged, never surfaced as a tag failure

    mock('sendPixel', function(url, onSuccess, onFailure) {
        pixelUrl = url;
        onFailure();
    });

    runCode(getMockData({}));

    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
- name: unknownEventType_notSent
  code: |-
    // A lookup table without a match must not send anything

    runCode(getMockData({ eventType: undefined }));

    assertApi('sendPixel').wasNotCalled();
    assertApi('setCookie').wasNotCalled();
    assertApi('gtmOnSuccess').wasCalled();
- name: eventTypeFromVariable_usesVariableValue
  code: |-
    // Variable source: the variable's value is the event type

    runCode(getMockData({ eventTypeSource: 'variable', eventType: 'view', eventTypeVariable: 'apply' }));

    assertThat(sentParams().event_type).isEqualTo('apply');
- name: eventTypeFixed_ignoresVariableField
  code: |-
    // Fixed source: a leftover variable value is ignored

    runCode(getMockData({ eventTypeSource: 'fixed', eventType: 'view', eventTypeVariable: 'apply' }));

    assertThat(sentParams().event_type).isEqualTo('view');
- name: eventTypeVariable_unknownValue_notSent
  code: |-
    // A variable returning an unknown value sends nothing

    runCode(getMockData({ eventTypeSource: 'variable', eventTypeVariable: 'something_else' }));

    assertApi('sendPixel').wasNotCalled();
    assertApi('gtmOnSuccess').wasCalled();
- name: legacyTag_withoutSource_usesEventType
  code: |-
    // A tag saved before the source field existed keeps working

    runCode({ eventType: 'apply' });

    assertThat(sentParams().event_type).isEqualTo('apply');
setup: |-
  // Shared test setup for the Jobiqo AIR web template

  const parseUrl = require('parseUrl');

  const ENDPOINT = 'https://air.jobiqo.com/campaign-tracking';

  // Test data
  const AIR_URL = 'https://www.example-jobboard.nl/vacature/123?air_campaign_item_id=023d1fa2-e9f&utm_campaign=jobiqo-air&utm_source=Talent&utm_medium=aggregator';
  const PLAIN_URL = 'https://www.example-jobboard.nl/sollicitatie/bedankt';
  const OTHER_JOB_URL = 'https://www.example-jobboard.nl/vacature/456';
  const REFERRER = 'https://nl.talent.com/';
  const NOW = 1700000000000;
  const RANDOM = 123456789;
  const NEW_SESSION = NOW + '.' + RANDOM;
  const EXISTING_SESSION = '1699999999000.987654321';

  // Mutable state per test
  let pageUrl = AIR_URL;
  let cookieJar = { _ga: 'GA1.1.111.222' };
  let cookiesSet = {};
  let containerVersion = {
      containerId: 'GTM-TEST',
      version: '1',
      debugMode: false,
      previewMode: false
  };
  let pixelUrl = null;

  // Base tag configuration
  function getMockData(overrides) {
      const defaults = {
          eventTypeSource: 'fixed',
          eventType: 'view',
          attribution: 'session',
          attributionWindowDays: '30',
          testMode: false,
          logType: 'debug'
      };

      for (var key in overrides) {
          defaults[key] = overrides[key];
      }

      return defaults;
  }

  // Decoded query parameters of the last pixel
  function sentParams() {
      return parseUrl(pixelUrl).searchParams;
  }

  // Mocks
  mock('getUrl', function() {
      return pageUrl;
  });

  mock('getReferrerUrl', function() {
      return REFERRER;
  });

  mock('getCookieValues', function(name) {
      return cookieJar[name] ? [cookieJar[name]] : [];
  });

  mock('setCookie', function(name, value, options) {
      cookiesSet[name] = { value: value, options: options };
  });

  mock('getTimestampMillis', function() {
      return NOW;
  });

  mock('generateRandom', function(min, max) {
      return RANDOM;
  });

  mock('getContainerVersion', function() {
      return containerVersion;
  });

  mock('sendPixel', function(url, onSuccess, onFailure) {
      pixelUrl = url;
      onSuccess();
  });


___NOTES___

Jobiqo AIR Tracking (web), template version 1.0.0.
Sends a GET request with the same fields as the server-side JSON payload.
