# Technical Debt Register

Every `TODO`, `FIXME`, `HACK`, and `XXX` in application source must use a
`TD-###` identifier listed here. `npm run check:tech-debt` verifies the link.

| ID | Location | Debt | Resolution criteria |
| --- | --- | --- | --- |
| TD-001 | `lib/database/anychat_auth.dart` | Several social-button enum values reach `UnimplementedError` rather than a supported sign-in flow. | Implement those sign-in providers or remove/disable the unsupported choices and return a user-facing error. |
| TD-002 | `lib/services/notifications/` | The vendored Awesome Notifications copy ships duplicated blocks (single/double slider widgets, repeated `notifications_util.dart` patterns, and `common_functions.dart` vs `common_web_functions.dart`); these clones are grandfathered in `.jscpd-baseline.json`. | Unify or deliberately exclude the vendored duplication, then shrink `.jscpd-baseline.json`; do not let the clone count grow. |
