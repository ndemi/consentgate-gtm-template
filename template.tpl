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
  "displayName": "ConsentGate CMP",
  "categories": ["UTILITY", "TAG_MANAGEMENT"],
  "brand": {
    "id": "brand_dummy",
    "displayName": "ConsentGate"
  },
  "description": "ConsentGate cookie consent window with Google Consent Mode v2. Use the Consent Initialization - All Pages trigger. Do not also paste the ConsentGate code into the page. / Okno zgód ConsentGate z Consent Mode v2. Reguła: Consent Initialization - All Pages. Nie wklejaj dodatkowo kodu ConsentGate w stronę.",
  "containerContexts": ["WEB"]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "siteId",
    "displayName": "Site ID / Identyfikator strony (panel ConsentGate: Kod do wstawienia)",
    "simpleValueType": true,
    "valueValidators": [
      { "type": "NON_EMPTY" },
      { "type": "REGEX", "args": ["^[a-z0-9]{1,32}$"] }
    ]
  },
  {
    "type": "GROUP",
    "name": "advanced",
    "displayName": "Advanced / Ustawienia dodatkowe",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "TEXT",
        "name": "waitForUpdate",
        "displayName": "Wait for the visitor's decision, ms (wait_for_update) / Czekaj na decyzję, ms",
        "simpleValueType": true,
        "defaultValue": "500",
        "valueValidators": [{ "type": "NON_NEGATIVE_NUMBER" }]
      },
      {
        "type": "CHECKBOX",
        "name": "adsDataRedaction",
        "checkboxText": "Redact ad data before marketing consent (ads_data_redaction) / Ukrywaj dane reklamowe przed zgodą",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "urlPassthrough",
        "checkboxText": "Pass ad click parameters in links without consent (url_passthrough) / Przekazuj parametry kliknięcia reklamy w adresach bez zgody",
        "simpleValueType": true,
        "defaultValue": false
      },
      {
        "type": "SIMPLE_TABLE",
        "name": "regions",
        "displayName": "Different default for selected countries (ISO codes, e.g. US or US-CA). Everywhere else: denied. / Inny stan domyślny dla wybranych krajów. Wszędzie indziej: odmowa.",
        "simpleTableColumns": [
          { "defaultValue": "", "displayName": "Countries / Kraje (US, CA, ...)", "name": "region", "type": "TEXT", "isUnique": true, "valueValidators": [{ "type": "NON_EMPTY" }] },
          { "defaultValue": "denied", "displayName": "Functional / Funkcjonalne", "name": "functional", "type": "SELECT", "selectItems": [{ "value": "denied", "displayValue": "denied" }, { "value": "granted", "displayValue": "granted" }] },
          { "defaultValue": "denied", "displayName": "Analytics / Analityczne", "name": "analytics", "type": "SELECT", "selectItems": [{ "value": "denied", "displayValue": "denied" }, { "value": "granted", "displayValue": "granted" }] },
          { "defaultValue": "denied", "displayName": "Marketing / Marketingowe", "name": "marketing", "type": "SELECT", "selectItems": [{ "value": "denied", "displayValue": "denied" }, { "value": "granted", "displayValue": "granted" }] }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const getCookieValues = require('getCookieValues');
const injectScript = require('injectScript');
const setInWindow = require('setInWindow');
const copyFromWindow = require('copyFromWindow');
const gtagSet = require('gtagSet');
const makeInteger = require('makeInteger');
const encodeUriComponent = require('encodeUriComponent');
const Math = require('Math');
const getTimestampMillis = require('getTimestampMillis');
const callInWindow = require('callInWindow');

// The ConsentGate code is already on the page: do not load it twice, only leave a flag
// so the ConsentGate panel can warn about the double installation.
if (copyFromWindow('ConsentGate')) {
  setInWindow('__cgDup', 1, true);
  data.gtmOnSuccess();
  return;
}

const state = function (functional, analytics, marketing) {
  return {
    functionality_storage: functional,
    personalization_storage: functional,
    analytics_storage: analytics,
    ad_storage: marketing,
    ad_user_data: marketing,
    ad_personalization: marketing,
    security_storage: 'granted'
  };
};

const wait = makeInteger(data.waitForUpdate);
const waitMs = wait >= 0 ? wait : 500;

(data.regions || []).forEach(function (row) {
  const regions = (row.region || '').split(',').map(function (x) { return x.trim().toUpperCase(); }).filter(function (x) { return x.length > 0; });
  if (regions.length === 0) return;
  const s = state(row.functional, row.analytics, row.marketing);
  s.region = regions;
  s.wait_for_update = waitMs;
  setDefaultConsentState(s);
});
const all = state('denied', 'denied', 'denied');
all.wait_for_update = waitMs;
setDefaultConsentState(all);

if (data.adsDataRedaction) gtagSet('ads_data_redaction', true);
if (data.urlPassthrough) gtagSet('url_passthrough', true);

// Decision from an earlier visit (cookie cg_consent, format 1.id.time36.version.bits.sent):
// tags on this page see it at once, without waiting for the consent window to load.
// The window re-checks the decision and revokes it if it is no longer valid.
// A decision older than one year is ignored even if the window fails to load.
const base36 = function (s) {
  const digits = '0123456789abcdefghijklmnopqrstuvwxyz';
  let n = 0;
  for (let i = 0; i < s.length; i++) {
    const d = digits.indexOf(s.charAt(i));
    if (d < 0) return -1;
    n = n * 36 + d;
  }
  return n;
};
const raw = getCookieValues('cg_consent')[0];
if (raw) {
  const p = raw.split('.');
  const fresh = p.length === 6 && p[0] === '1' && getTimestampMillis() - base36(p[2]) < 365 * 86400000 && base36(p[2]) > 0;
  const bits = fresh ? makeInteger(p[4]) : -1;
  if (bits >= 0 && bits <= 7) {
    const on = function (bit) { return Math.floor(bits / bit) % 2 === 1 ? 'granted' : 'denied'; };
    updateConsentState(state(on(1), on(2), on(4)));
  }
}

// Each later decision of the visitor goes to Google tags through the Tag Manager consent API.
const onUserConsent = function (c) {
  const v = function (on) { return on ? 'granted' : 'denied'; };
  updateConsentState(state(v(c.functional), v(c.analytics), v(c.marketing)));
};
const onLoaded = function () {
  callInWindow('ConsentGate.onChange', onUserConsent);
  data.gtmOnSuccess();
};

// Tells the consent window that this template has already set the defaults.
setInWindow('__cgTpl', true, true);
injectScript('https://cdn.consentgate.eu/s/' + encodeUriComponent(data.siteId) + '.js', onLoaded, data.gtmOnFailure, 'consentgate');


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": { "publicId": "access_consent", "versionId": "1" },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              { "type": 3, "mapKey": [{ "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }], "mapValue": [{ "type": 1, "string": "ad_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }], "mapValue": [{ "type": 1, "string": "ad_user_data" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }], "mapValue": [{ "type": 1, "string": "ad_personalization" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }], "mapValue": [{ "type": 1, "string": "analytics_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }], "mapValue": [{ "type": 1, "string": "functionality_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }], "mapValue": [{ "type": 1, "string": "personalization_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }], "mapValue": [{ "type": 1, "string": "security_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }] }
            ]
          }
        }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  },
  {
    "instance": {
      "key": { "publicId": "get_cookies", "versionId": "1" },
      "param": [
        { "key": "cookieAccess", "value": { "type": 1, "string": "specific" } },
        { "key": "cookieNames", "value": { "type": 2, "listItem": [{ "type": 1, "string": "cg_consent" }] } }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  },
  {
    "instance": {
      "key": { "publicId": "inject_script", "versionId": "1" },
      "param": [
        { "key": "urls", "value": { "type": 2, "listItem": [{ "type": 1, "string": "https://cdn.consentgate.eu/s/*" }] } }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  },
  {
    "instance": {
      "key": { "publicId": "access_globals", "versionId": "1" },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              { "type": 3, "mapKey": [{ "type": 1, "string": "key" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }, { "type": 1, "string": "execute" }], "mapValue": [{ "type": 1, "string": "__cgTpl" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }, { "type": 8, "boolean": false }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "key" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }, { "type": 1, "string": "execute" }], "mapValue": [{ "type": 1, "string": "__cgDup" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true }, { "type": 8, "boolean": false }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "key" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }, { "type": 1, "string": "execute" }], "mapValue": [{ "type": 1, "string": "ConsentGate" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": false }, { "type": 8, "boolean": false }] },
              { "type": 3, "mapKey": [{ "type": 1, "string": "key" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" }, { "type": 1, "string": "execute" }], "mapValue": [{ "type": 1, "string": "ConsentGate.onChange" }, { "type": 8, "boolean": false }, { "type": 8, "boolean": false }, { "type": 8, "boolean": true }] }
            ]
          }
        }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  },
  {
    "instance": {
      "key": { "publicId": "write_data_layer", "versionId": "1" },
      "param": [
        { "key": "keyPatterns", "value": { "type": 2, "listItem": [{ "type": 1, "string": "ads_data_redaction" }, { "type": 1, "string": "url_passthrough" }] } }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Sets denied defaults and loads the consent window
  code: |-
    mock('copyFromWindow', function () { return undefined; });
    mock('getCookieValues', function () { return []; });
    mock('injectScript', function (url, onSuccess) { onSuccess(); });
    mock('callInWindow', function (name, listener) {
      if (name === 'ConsentGate.onChange') listener({ functional: false, analytics: true, marketing: false });
    });
    runCode(mockData);
    assertApi('callInWindow').wasCalled();
    assertApi('updateConsentState').wasCalledWith({
      functionality_storage: 'denied',
      personalization_storage: 'denied',
      analytics_storage: 'granted',
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      security_storage: 'granted'
    });
    assertApi('setDefaultConsentState').wasCalledWith({
      functionality_storage: 'denied',
      personalization_storage: 'denied',
      analytics_storage: 'denied',
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      security_storage: 'granted',
      wait_for_update: 500
    });
    assertApi('injectScript').wasCalled();
    assertApi('gtmOnSuccess').wasCalled();
- name: Does not load the window twice when the code is already on the page
  code: |-
    mock('copyFromWindow', function () { return {}; });
    runCode(mockData);
    assertApi('setDefaultConsentState').wasNotCalled();
    assertApi('injectScript').wasNotCalled();
    assertApi('gtmOnSuccess').wasCalled();
- name: Applies a recent decision from the cookie before the window loads
  code: |-
    mock('copyFromWindow', function () { return undefined; });
    mock('getTimestampMillis', function () { return 1800000000000; });
    mock('getCookieValues', function () { return ['1.id.mywoxha8.1.6.1']; });
    mock('injectScript', function () {});
    runCode(mockData);
    assertApi('updateConsentState').wasCalledWith({
      functionality_storage: 'denied',
      personalization_storage: 'denied',
      analytics_storage: 'granted',
      ad_storage: 'granted',
      ad_user_data: 'granted',
      ad_personalization: 'granted',
      security_storage: 'granted'
    });
setup: |-
  const mockData = {
    siteId: 'abc123',
    waitForUpdate: '500',
    adsDataRedaction: true,
    urlPassthrough: false,
    regions: []
  };


___NOTES___

ConsentGate (consentgate.eu), CRE 8 Sp. z o.o.
