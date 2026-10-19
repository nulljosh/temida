# Temida API

Temida has no HTTP API of its own. Case data lives in jaybulb-api
(api.jaybulb.com), which only returns the signed-in user's own rows, and is read
from the browser with that user's session (`web/auth.js`, `web/spark-client.js`);
checklist state also mirrors to `localStorage`. The apps use the same endpoints
through `ios/Sources/Models/API.swift`:

| Endpoint | Used for |
|---|---|
| `POST /auth/token?grant_type=password\|refresh_token\|id_token` | Sign in, stay signed in, Apple and Google |
| `POST /auth/signup`, `/auth/recover`, `/auth/logout` | New account, reset link, sign out |
| `GET`, `PUT`, `DELETE /auth/user` | Profile (name, photo, onboarded flag), delete account |
| `GET`, `POST`, `DELETE /rest/brief_*` | Case data, journal, documents, checklist, lawyer status |
| `PUT /storage/spark-avatars/themis/<user>/<file>.jpg` | Profile photo |

The agent-facing interface is WebMCP.

## WebMCP

`web/script.js` appends `web/webmcp.js`, and it only runs after `auth.js` has established a
session, so no tool can reach case material from a signed-out page.

### Read-only

| Tool | Does |
|---|---|
| `list_cases` | Case ids, file numbers and titles, plus which one is open |
| `get_case` | Grounds, settlement scenarios, damage heads, timeline and counsel for one case |
| `get_call_script` | The prepared call script for a case |
| `get_checklist` | Evidence checklist for the open case: label, leverage value, priority, done state |
| `get_leverage` | Evidence gathered, counsel status and the projected total |

### Reversible writes

| Tool | Does |
|---|---|
| `set_checklist_item` | Mark an evidence item gathered or not; recomputes leverage |
| `open_case` | Switch the app to another case |

There are deliberately **no delete tools**. Nothing in this app removes case
data, and that includes the agent surface.

The checklist write goes through `setChecklistItem` in `web/script.js`, the same
function the checklist row click calls, so persistence and the
leverage recompute can't drift between the two paths.
