# Mix & Sip POS Flutter Application — Project Analysis

**Analysis date:** 2026-07-16  
**Repository path:** `C:\Users\freddy\Desktop\apps\mix-n-sip-pos-app`  
**Scope:** Read-only architecture, setup, workflow, security, and maintainability review. No functional application code, database, migrations, configuration, or dependencies were changed.

## Finding labels

- **Confirmed from code:** Directly demonstrated by the Flutter source or platform configuration.
- **Confirmed across repositories:** Demonstrated by both this Flutter project and the Laravel project at `C:\wamp64\www\mix-and-sip-pos`.
- **Inferred from code:** Strongly implied, but not executed end-to-end.
- **Requires backend/database verification:** Depends on the deployed Laravel code or database state.
- **Requires runtime verification:** Needs a working SDK/device/backend combination.

## Implementation update — 2026-07-16

Following owner review, two approved reliability items were implemented without changing Laravel pricing, discount, order, or payment workflows:

1. A logical in-memory sale now receives one `client_reference` when its cart begins. The same reference is retained across failed checkout attempts and is cleared only after confirmed success or when the cart is emptied. POS state is no longer auto-disposed during navigation, so the cart/reference survives route changes within the running app. A focused retry test confirms both attempts submit the same reference.
2. Dio 401 responses now publish a session event that immediately moves `AuthController` to unauthenticated state after clearing the token. Logout always completes locally even if server revocation is unavailable. Focused tests cover both paths.

The active UI was also redesigned with a responsive warm cream/coffee visual system, shared navigation, a tablet split-pane POS, phone cart/payment sheets, improved orders/details/payment states, and clearer error handling. Static analysis reports no issues, all five tests pass, and an Android debug APK built and rendered successfully on the connected emulator.

## 1. Executive Summary

**Confirmed from code:** This is an early Flutter point-of-sale client for the Mix & Sip Laravel application. Its currently reachable application supports:

1. Username/password login against Laravel Sanctum.
2. Restoration of a stored bearer-token session.
3. A permission-aware dashboard.
4. Product search and customer selection.
5. Cart creation, server-calculated quotes, and sale checkout.
6. Pending, pending-due, and completed order lists.
7. Order-item display and payment of an outstanding balance.
8. System/light/dark theme selection and logout.

The active application uses a feature-oriented Flutter structure with Riverpod state notifiers, GoRouter navigation, Dio HTTP, and Flutter Secure Storage. It is a thin online client: it has no local business database, offline queue, cached catalog, persisted cart, background jobs, or synchronization engine. Laravel is the source of truth for authentication, permissions, products, customers, pricing, orders, payment state, and inventory.

**Confirmed from code:** The project also contains a much larger invoice-and-billing UI template that is not reachable from `main.dart`. Of 130 Dart files and about 31,512 lines, approximately 100 files/29,526 lines are in excluded legacy/template areas. They contain mock data, TODO actions, old navigation, and dormant integrations. The active POS layer is approximately 30 files/1,986 lines.

**Overall maturity:** The application is a functional prototype, not yet production-ready. The highest risks are duplicate sales after ambiguous network failures, client-controlled discounts, overselling/negative inventory, authentication state becoming inconsistent with token storage, incomplete release networking configuration, very limited tests, and the large excluded template tree masking defects.

## 2. Technologies Detected

| Area | Technology | Evidence / status |
|---|---|---|
| Language | Dart 3.x | `pubspec.yaml`; installed SDK reports Dart 3.12.2 |
| UI framework | Flutter stable | `.metadata`; generated plugin metadata reports Flutter 3.44.6 |
| State management | Riverpod 2.6.1 | `flutter_riverpod`; `StateNotifierProvider` and `Provider` |
| Routing | GoRouter 14.8.1 | Declarative routes and auth redirect |
| HTTP | Dio 5.9.0 | Active Laravel API client and repositories |
| Secure local storage | Flutter Secure Storage 9.2.4 | Sanctum token and theme mode |
| IDs | UUID 4.x | Checkout client reference |
| Styling | Material 3 and Google Fonts | Poppins-based themes |
| Legacy HTTP | `http` 1.x | Dormant Gemini prototype only |
| Testing | `flutter_test` | Two unit/model tests |
| Linting | `flutter_lints` 5.x | `analysis_options.yaml` |
| Platforms | Android, iOS, web, Windows, Linux, macOS | Generated platform folders |
| Package manager | Flutter Pub | `pubspec.yaml`, `pubspec.lock`, `.dart_tool` |
| Android build | Gradle 8.14.3, Kotlin, Java 11 | `android/` configuration |

There is no Firebase configuration, SQLite/Hive/Isar database, service worker customization, CI/CD definition, Docker setup, FVM configuration, Melos workspace, crash reporter, analytics SDK, push notification SDK, printer SDK, or barcode scanner package in the repository.

## 3. Project Structure

```text
mix-n-sip-pos-app/
├── lib/
│   ├── main.dart                         # Flutter entry point
│   ├── app/
│   │   ├── app.dart                     # MaterialApp.router and themes
│   │   ├── router/app_router.dart       # Auth redirect and active routes
│   │   └── theme/app_theme.dart         # Material 3 light/dark themes
│   ├── core/
│   │   ├── api/                         # Dio client, error parsing, legacy items adapter
│   │   ├── config/                      # Compile-time API URL/Host values
│   │   ├── errors/                      # AppException
│   │   ├── permissions/                 # Exact permission-name helper
│   │   └── storage/                     # Secure token storage
│   ├── features/
│   │   ├── authentication/              # User DTO, repository, state, login UI
│   │   ├── dashboard/                   # Permission-aware module cards
│   │   ├── pos/                         # Catalog/cart/quote/checkout
│   │   ├── orders/                      # Order lists, details, pay-due
│   │   └── settings/                    # Theme and logout
│   ├── shared/widgets/                  # Coming-soon screen
│   ├── views/                           # Dormant invoice/billing prototype (66 files)
│   ├── widgets/                         # Dormant template widgets (22 files)
│   ├── commonwidgets/                   # Dormant template helpers (9 files)
│   ├── models/                          # Dormant/legacy models (2 files)
│   └── constants/                       # Template constants
├── test/                                # Two small tests
├── images/                              # Entire directory bundled as assets
├── android/, ios/, web/                 # Mobile/web runners
├── windows/, linux/, macos/             # Desktop runners
├── pubspec.yaml / pubspec.lock          # Dependencies and locked versions
├── analysis_options.yaml                # Lints plus broad exclusions
└── README.md                            # Unmodified generic Flutter README
```

### Active versus template code

**Confirmed from code:** `main.dart` reaches only `lib/app`, `lib/core`, `lib/features`, and `lib/shared`. No active route imports `lib/views`, `lib/widgets`, or `lib/commonwidgets`. The only active-to-legacy dependency is `core/api/items_service.dart` importing `models/item.dart`; the service itself is not used by the active router.

The dormant `lib/views` tree includes analytics, authentication mockups, bank details, billing chat, credit notes, customers, delivery challans, expenses, fraud detection, inventory, invoices, messages, payments, products, purchases, quotations, reports, returns, settings, signatures, tax rates, vendors, and a legacy home screen. This code should not be called “dead” until product ownership confirms it is not intended for future activation, but it is currently outside the app’s import/navigation closure.

## 4. Safe Local Setup Instructions

### Prerequisites

1. Flutter stable compatible with Dart `^3.7.2`. The project was last generated/resolved with Flutter 3.44.6 and Dart 3.12.2.
2. A platform toolchain: Android Studio/SDK for Android, Visual Studio C++ workload for Windows, or Xcode/CocoaPods for Apple platforms.
3. The Laravel application running with its `/api/v1` routes, database, Sanctum tables, roles/permissions, products, customers, and POS migrations available.
4. A test user with `pos.menu` and/or `orders.menu` permissions.

### SDK location observed on this machine

The SDK exists at `C:\Users\freddy\develop`, but its `bin` directory is not on this PowerShell process's `PATH`. Commands can be run explicitly or the directory can be added to the user's development environment:

```powershell
& 'C:\Users\freddy\develop\bin\flutter.bat' --version
& 'C:\Users\freddy\develop\bin\flutter.bat' pub get
```

`pub get` is the appropriate dependency command because this is a single Flutter Pub project with a committed `pubspec.lock`. Do not use npm, Composer, Yarn, or Gradle directly for Dart package installation.

### API configuration

The app uses compile-time `--dart-define` values:

- `API_BASE_URL`, default `https://mix-and-sip.devlynq.com/api/v1`
- `API_HOST`, default empty; the hosted server receives its normal hostname
- `GEMINI_API_KEY`, referenced only by dormant prototype code; it should not be embedded in a distributable client.

Android emulator example:

```powershell
& 'C:\Users\freddy\develop\bin\flutter.bat' run -d <android-device-id> --dart-define=API_BASE_URL=http://10.0.2.2/api/v1 --dart-define=API_HOST=pos.test
```

Plain runs use the hosted HTTPS API. The emulator command above explicitly overrides that default with `10.0.2.2` and the `pos.test` Host header to reach local WAMP/Laravel. For Windows/Linux/macOS, use a host reachable from that platform. For web, the Laravel API must permit the web origin through CORS, HTTPS pages cannot call an HTTP API, and browsers generally do not permit application code to set the `Host` header.

### Platform blockers

- **Android debug:** `INTERNET` and cleartext HTTP are enabled. This is the only configuration that clearly supports the default HTTP URL.
- **Android profile/release:** `INTERNET` is present, but cleartext HTTP is not enabled. Android 9+ will normally block the default HTTP API. Release signing still uses the debug key.
- **iOS:** `Info.plist` has no App Transport Security exception for the HTTP API, no `ios/Podfile` is present, and branding is still `Invoiceandbilling`. HTTPS is the recommended resolution rather than a broad ATS exception.
- **macOS:** sandbox entitlements do not include `com.apple.security.network.client`; API networking is expected to fail in sandboxed builds.
- **Web:** active authentication imports `dart:io` for `Platform.operatingSystem`, so web compilation is expected to fail. Secure storage also requires a secure web context.
- **Windows/Linux:** template application identifiers and names remain; the default Android-emulator IP is not appropriate.

### Other setup requirements

- No `.env` file is used by Flutter. Do not create one unless a configuration library is deliberately introduced later.
- No application key, storage link, writable Laravel directory, mobile database migration, queue worker, or cron process is required by the Flutter client itself.
- `flutter_secure_storage` needs the native plugin toolchains. Linux may need the platform keyring/libsecret packages; Apple builds need correct signing/keychain capabilities.
- Google Fonts may fetch Poppins at runtime unless the font is bundled or already cached, so first-run styling can depend on internet access.
- The entire `images/` directory is bundled. Asset size and licensing should be reviewed before release.

### Safe verification commands

```powershell
& 'C:\Users\freddy\develop\bin\flutter.bat' pub get
& 'C:\Users\freddy\develop\bin\flutter.bat' analyze
& 'C:\Users\freddy\develop\bin\flutter.bat' test --reporter expanded
& 'C:\Users\freddy\develop\bin\flutter.bat' devices
```

No Laravel migration or seeder should be run merely to launch the Flutter UI. Confirm the deployed database already has customer discounts and unique order `client_reference` support before exercising checkout.

## 5. Architecture

### Entry and composition

**Confirmed from code:** `lib/main.dart::main()` initializes Flutter bindings and runs `ProviderScope(child: MixAndSipApp())`. `lib/app/app.dart::MixAndSipApp.build()` watches the router and theme providers and creates `MaterialApp.router`.

### Presentation

Screens are `ConsumerWidget`/`ConsumerStatefulWidget` classes. They watch Riverpod state and call notifier methods or repositories. Material widgets provide the responsive UI. The active application has no separate design-system/component package beyond themes and a small shared coming-soon widget.

### State management

- `AuthController` is a non-auto-disposed `StateNotifier` and owns session status/user/error/submission state.
- `PosController` is auto-disposed and owns catalog lists, selected customer, cart, quote, loading, submission, and one error.
- `OrdersController` is auto-disposed and owns selected filter, list, loading, and error.
- `ThemeController` stores the chosen mode in secure storage.

The pattern is generally `Screen -> Controller -> Repository -> ApiClient -> Laravel`. Order details and pay-due are exceptions: `OrdersScreen` accesses `OrdersRepository` directly from modal UI instead of routing through `OrdersController`.

### Data/repository layer

Repositories construct endpoint-specific payloads and parse maps into small domain objects. There are no generated serializers, immutable model generator, DTO validation layer, caching repository, or interface abstraction. Parsing uses casts and non-null assertions, making response compatibility important.

### API and error handling

`ApiClient` owns one Dio instance per provider scope, attaches the bearer token before every request, and clears secure storage after any 401. `ApiErrorParser.parse()` translates Dio connection/timeout failures and Laravel `message`, `errors`, and `code` fields into `AppException`.

There is no request/response logging, correlation ID, telemetry, retry policy, connectivity monitor, certificate pinning, refresh-token flow, or global UI error boundary. The client has 15-second connect and 20-second receive timeouts but no explicit send timeout.

## 6. Request Lifecycle

### Startup/session restoration

1. `main()` creates the Riverpod container and app.
2. `authControllerProvider` constructs `AuthController` and immediately calls `restore()`.
3. GoRouter starts at `/loading` and keeps restoring users there.
4. `AuthRepository.restore()` reads `sanctum_token` from secure storage.
5. If present, it calls `GET /auth/me` with `Authorization: Bearer ...`.
6. Successful user JSON becomes `AppUser`; the router redirects to `/`.
7. Any restoration exception clears the token and redirects to `/login`.

**Risk:** An offline timeout is treated the same as an invalid/revoked token, so a transient outage logs the user out locally.

### Login

1. `/login` displays `LoginScreen`.
2. Client validation requires nonempty username and password.
3. `AuthController.login()` calls `AuthRepository.login()`.
4. Repository posts username, password, and an OS-derived device name to `POST /auth/login`.
5. Laravel validates credentials, creates a Sanctum personal-access token, and returns user roles and all effective permissions.
6. The token is written to secure storage and auth state becomes authenticated.
7. GoRouter redirects to the dashboard.

Laravel throttles login to 10 requests/minute. Password hashing and credential verification remain server-side. The Flutter application never stores the password.

### Authenticated request

1. A screen/controller calls a repository.
2. Repository calls the shared Dio client.
3. The request interceptor asynchronously reads secure storage and adds the bearer token.
4. Laravel `auth:sanctum` authenticates the token.
5. Laravel permission middleware protects POS or order groups.
6. JSON is parsed to a model/state and the screen rebuilds.
7. On 401, the client clears the token but does not notify `AuthController`.

### Logout

`SettingsScreen` calls `AuthController.logout()`, which posts `/auth/logout`. Laravel deletes only the current access token. The repository clears local storage in `finally`. If the HTTP call throws, the controller never changes to unauthenticated even though local storage has been cleared.

### Active route map

| Client route | Screen | Client gate | Backend gate | Purpose |
|---|---|---|---|---|
| `/loading` | `SessionLoadingScreen` | Auth redirect | `/auth/me` uses Sanctum | Restore session |
| `/login` | `LoginScreen` | Unauthenticated | Login throttle | Authenticate |
| `/` | `DashboardScreen` | Authenticated | None on screen | Module menu |
| `/settings` | `SettingsScreen` | Authenticated | Logout uses Sanctum | Theme/logout |
| `/pos` | `PosScreen` | Authenticated only | `auth:sanctum`, `pos.menu` | Create sales |
| `/orders` | `OrdersScreen` | Authenticated only | `auth:sanctum`, `orders.menu` | Review/pay orders |

**Confirmed across repositories:** Direct navigation to `/pos` or `/orders` is not permission-checked by GoRouter, but Laravel protects every underlying API endpoint. This is an inconsistent UX/client defense, not a server-side authorization bypass in the reviewed API route group.

There are no mobile deep-link declarations, webhook handlers, internal debug routes, background routes, or push-notification routes.

## 7. Authentication and Authorization

### Authentication design

- Username/password is posted over the configured transport.
- Laravel verifies `Hash::check()` and returns a Sanctum personal-access token.
- The token is stored as `sanctum_token` in Flutter Secure Storage.
- Every request receives `Authorization: Bearer <token>`.
- `/auth/me` restores user, roles, and permissions.
- Logout revokes only the current token and deletes it locally.
- No refresh token, explicit expiration, token listing/revocation UI, PIN, biometrics, inactivity timeout, device restriction, or remember-me toggle exists.

Token expiration depends on Laravel Sanctum configuration and the deployed database; it is not represented in the Flutter model. Device names identify only operating system plus a fixed suffix and are not unique per installation.

### Roles and permissions

Flutter does not assign roles or permissions. `AppUser` stores server-returned role names and a `Set<String>` of effective permissions. Permission matching is case-sensitive and exact.

| Role | Permission | Feature/actions | Client enforcement | Server enforcement | Status |
|---|---|---|---|---|---|
| Any server role granting permission | `pos.menu` | Catalog, quote, create sale | Dashboard card only | Entire `/v1/pos` route group | Confirmed across repositories |
| Any server role granting permission | `orders.menu` | Lists, items, pay due | Dashboard card only | Entire `/v1/orders` route group | Confirmed across repositories |
| Any server role granting permission | `customer.menu` | Customer card | Card visible; action is empty | No matching active mobile endpoint | Confirmed from code |
| Any server role granting permission | `reports.menu` | Reports card | Card visible; action is empty | No active mobile reports request | Confirmed from code |
| Any authenticated user | none beyond authentication | Settings/theme/logout | Router authentication redirect | Logout uses Sanctum | Confirmed from code |

Exact role-to-permission assignments require database verification because Spatie Laravel Permission stores them in server tables. No branch, warehouse, department, company, location, register, or record-ownership constraint is present in the Flutter state or active API payloads. The reviewed Laravel v1 routes likewise do not express such a constraint. This must be checked against actual business requirements and database scoping.

### Server versus UI enforcement

The dashboard hides modules, but route paths themselves check only authentication. Server middleware is therefore the authoritative protection. Buttons for customers and reports can appear to authorized users but do nothing. `PermissionService` exists and is unit-tested, but the dashboard bypasses it and calls `permissions.contains()` directly.

## 8. Data Model and Storage

### Local storage

| Key/data | Store | Lifetime | Notes |
|---|---|---|---|
| Sanctum bearer token | Flutter Secure Storage, key `sanctum_token` | Across launches | Cleared on logout, restore failure, or any 401 |
| Theme mode | Flutter Secure Storage, key `theme_mode` | Across launches | Values: `system`, `light`, `dark` |
| Cart, catalog, customers, quotes, orders | Riverpod memory only | Until provider disposal/process end | No offline persistence or recovery |

There is no mobile database, file cache, session cookie store, local migration, or synchronization metadata.

### Flutter domain objects

| Object | Important fields | Source | Relationships / use |
|---|---|---|---|
| `AppUser` | id, name, username, email, roles, permissions | `/auth/login`, `/auth/me` | Current authenticated identity |
| `Product` | id, name, code, price, stock | `/pos/products` | Selected into `CartLine`; null stock becomes zero |
| `Customer` | id, name, discountPercent | `/pos/customers` | One selected for quote/sale |
| `CartLine` | product, integer quantity | In memory | Local subtotal is price × quantity |
| `PosQuote` | subtotal, discount, tax, total | `/pos/quote` | Authoritative displayed checkout totals |
| `OrderSummary` | id, invoice, date, status, customer, total, due | `/orders/{filter}` | Order list/detail header |
| Order item | dynamic map fields | `/orders/{id}/items` | Name/code/quantity/unit cost/total in modal |

### Server entities used by the client

| Server entity/table | Key fields observed | Workflow | Verification |
|---|---|---|---|
| `users` / `User` | id, name, username, email, password | Login/session | Confirmed across repositories |
| Sanctum personal access tokens | token, name/device, tokenable | Bearer authentication/logout | Confirmed across repositories; expiry requires config/database check |
| Spatie roles/permissions and pivots | role names, permission names, user assignments | Dashboard and API middleware | Schema/assignments require database verification |
| `products` / `Product` | id, product_name, product_code, selling_price, product_store, expire_date | Search, quote, stock decrement | Confirmed across repositories |
| `customers` / `Customer` | id, name, contact fields, discount_percent | Customer selection/discount | Confirmed across repositories; migration state requires database check |
| `orders` / `Order` | customer_id, invoice_no, client_reference, dates/statuses, totals, pay/due, tendered/change, method | Sale/order/payment | Confirmed across repositories; field types must be checked against live schema |
| `order_details` / `OrderDetails` | order_id, product_id, quantity, unitcost, total | Sale lines/order items | Confirmed across repositories |

### Status and method values

- Order list endpoints use `pending`, `pending-due`, and `complete` as client filters.
- Server `order_status` is created as `pending` or `complete`.
- Checkout payment methods are exactly `Cash`, `Card`, or `Transfer`.
- Pay-due accepts a free server string up to 20 characters, but the mobile UI always sends `Cash`.
- `payment_status` and `payment_method` are both populated with the method, so the name “status” does not represent a lifecycle state in this workflow.
- Tax is currently hard-coded to zero by `PosPricingService`.
- Prices are converted to integer cents after first casting the product's selling price to integer; decimal selling prices require database/runtime verification because fractional values may be truncated by the backend.

### Database items requiring verification

1. The `2026_07_13_120000_add_client_reference_to_orders_table` migration has been applied and its unique index exists.
2. The customer `discount_percent` migration has been applied and values are correct.
3. Production column types for order money are decimal rather than the older integer migration definitions.
4. Product stock semantics permit or forbid negative inventory.
5. Token expiry/pruning policy and existing token volume.
6. Actual role-permission assignments and whether users should be scoped to a branch/register/location.
7. Customer ID 26 exists and is truly the intended walk-in/default customer.

## 9. Business Workflows

### 9.1 Login and session restoration

**Start:** `/loading` on launch or `/login` when unauthenticated.  
**Inputs:** Username and password; both only checked for nonempty values client-side.  
**Backend:** `POST /api/v1/auth/login`, then secure token storage; later `GET /api/v1/auth/me`.  
**Side effects:** Laravel creates a Sanctum token; Flutter stores it.  
**Result:** Dashboard with module cards based on effective permissions.  
**Errors:** Login displays parsed API errors. Restore hides errors, clears the token, and returns to login.  
**Files:** `login_screen.dart`, `auth_controller.dart`, `auth_repository.dart`, `api_client.dart`, `app_router.dart`.

### 9.2 Product/customer loading

**Start:** Opening `/pos`; auto-disposed `PosController` calls `load()`.  
**Permissions:** `pos.menu` enforced by Laravel.  
**Calls:** Products and customers load concurrently. Products request 40 rows; customers request 50.  
**Rules:** Backend returns only products with `expire_date` later than today and orders them by name. Customer ID 26 is selected if present; otherwise the first returned customer.  
**Result:** Responsive product grid and customer dropdown.  
**Limitations:** Only the first page is retained; there is no next-page mechanism. A customer outside the first 50 cannot be selected. There is no customer search in the active UI.

### 9.3 Product search and cart

**Start:** Typing in the POS search field.  
**Behavior:** A 350 ms timer debounces `GET /pos/products?q=...`.  
**Cart:** Tapping a product adds or increments an in-memory `CartLine`. Quantity can grow without regard to displayed stock. Decrementing to zero removes the line. Any cart/customer change discards the quote.  
**Calculation:** Before server quote, UI estimates totals from client price × quantity.  
**Errors:** Stored in the POS state's single `error` field beneath the main search area.  
**Risks:** In-flight searches are not cancelled or sequenced; an older response can replace a newer query. The cart is destroyed when the auto-disposed provider is left.

### 9.4 Quote

**Start:** “Validate total” in the cart sheet.  
**Payload:** customer ID, customer discount percent copied from the client DTO, and product ID/quantity lines.  
**Backend calculation:** Reloads customer/products, groups duplicate lines, rejects missing/expired products, prices from the database, applies the submitted discount, sets tax to zero, and returns totals.  
**Result:** The UI displays authoritative subtotal, discount, tax, and total and sets tendered to total.  
**Errors:** Controller captures them, but the error widget is behind the open bottom sheet, so the cashier may not see the reason.

### 9.5 Checkout/create sale

**Start:** After a quote, choose Cash/Card/Transfer, enter tendered, and complete sale.  
**Payload:** Cart/customer data, a newly generated UUID, payment method, `pay` equal to the previously quoted total, and tendered.  
**Backend:** Recalculates the quote inside a transaction, creates `orders` and `order_details`, and decrements product stock only for immediately complete orders. It returns an invoice number.  
**Status:** Since the client always sends full quoted total as `pay`, the intended result is `complete`; price/discount changes between quote and sale can instead fail or create an unexpected due.  
**Success:** Client clears cart and quote and displays the invoice number.  
**Failure:** Cart remains; error is stored outside the bottom sheet.  
**Side effects:** Order rows, detail rows, inventory decrement, invoice-number generation. No receipt printing, PDF, email, cash-drawer, or audit event is initiated by Flutter.

**Critical retry behavior:** `client_reference` is generated inside every `checkout()` call. If the server commits but the response is lost, pressing checkout again sends a different reference and defeats the backend's idempotency protection, potentially creating a duplicate sale.

### 9.6 Order browsing

**Start:** `/orders`, requiring `orders.menu`.  
**Filters:** Pending, Pending Due, Complete.  
**Call:** `GET /orders/{filter}?perPage=50`.  
**Result:** Segmented list with invoice, customer, date, status, total, and due; pull-to-refresh is available.  
**Detail:** Tapping an order opens a modal and separately calls `/orders/{id}/items`.  
**Limitations:** First 50 only, no search/date filter/sort UI, no header refetch, no invoice download/printing. A detail-request error leaves a perpetual spinner because `FutureBuilder` does not handle `hasError`.

### 9.7 Pay outstanding due

**Start:** Pay button for an order with due > 0.  
**Input:** Free-text tendered amount; invalid text becomes zero.  
**Payload:** Tendered plus hard-coded `Cash`.  
**Backend:** Locks the order in a transaction, requires tendered at least equal to due, applies only the due, calculates change, decrements stock, and marks complete.  
**Success:** Dialog and detail close.  
**Error behavior:** No dialog loading state, duplicate-submit protection, try/catch, or rendered validation error. The list is not explicitly refreshed in place.  
**Business rule:** Partial due payments are not supported; tendered must cover the entire due.

### 9.8 Theme/logout

Theme changes update MaterialApp and are stored as `system`, `light`, or `dark`. Logout revokes the current server token when reachable and always deletes the local token. Network failure can leave the rendered auth state inconsistent with storage.

### Not currently implemented in the active app

Barcode scanning (although Laravel has a barcode lookup endpoint), customer CRUD, product CRUD, inventory adjustments, returns, reports, printing/PDF, receipts, drafts, offline mode, shift/register management, cash reconciliation, branch/warehouse selection, approvals, notifications, file upload, background jobs, email, and synchronization are absent from the active import tree. Similar-looking screens under `lib/views` are prototypes with mock data, not active workflows.

## 10. API and Integration Map

### Active Laravel API

Base URL: `${API_BASE_URL}`, expected to end in `/api/v1`.

| Method/path | Purpose | Auth/permission | Client consumer |
|---|---|---|---|
| `POST /auth/login` | Create Sanctum token/user snapshot | Public, throttled | `AuthRepository.login()` |
| `GET /auth/me` | Restore identity/permissions | Sanctum | `AuthRepository.restore()` |
| `POST /auth/logout` | Revoke current token | Sanctum | `AuthRepository.logout()` |
| `GET /pos/products` | Search/paginate nonexpired products | Sanctum + `pos.menu` | `PosRepository.products()` |
| `GET /pos/customers` | Search/paginate customers | Sanctum + `pos.menu` | `PosRepository.customers()` |
| `POST /pos/quote` | Server pricing | Sanctum + `pos.menu` | `PosRepository.quote()` |
| `POST /pos/sales` | Idempotent sale creation | Sanctum + `pos.menu` | `PosRepository.checkout()` |
| `GET /orders/pending` | Pending list | Sanctum + `orders.menu` | `OrdersRepository.list()` |
| `GET /orders/pending-due` | Due list | Sanctum + `orders.menu` | `OrdersRepository.list()` |
| `GET /orders/complete` | Complete list | Sanctum + `orders.menu` | `OrdersRepository.list()` |
| `GET /orders/{id}/items` | Order lines | Sanctum + `orders.menu` | `OrdersRepository.items()` |
| `POST /orders/{id}/pay-due` | Clear due/complete order | Sanctum + `orders.menu` | `OrdersRepository.payDue()` |

Laravel also exposes `/pos/products/barcode/{barcode}` and `/orders/{order}`, but the active Flutter client does not call them.

### Other integrations

| Integration | State | Configuration/auth | Risk/notes |
|---|---|---|---|
| Flutter Secure Storage | Active | Native keystore/keychain/browser secure storage | Token and theme persistence; platform prerequisites apply |
| Google Fonts | Active | No explicit key | May fetch Poppins at runtime; bundle fonts for deterministic offline use |
| Google Gemini `gemini-1.5-flash` | Dormant prototype | Compile-time `GEMINI_API_KEY` placed in URL | Never ship a privileged key in the client; proxy and authorize server-side if feature is revived |
| Clearbit/Unsplash/icons8 images | Dormant mock screens | Public URLs | Network, licensing, privacy, and availability concerns if revived |
| Legacy Yii-style item API | Dormant | `r=api/items`, price list, warehouse query values | Incompatible architectural branch from current Laravel v1 API; source of truth unclear |

The active Laravel integration has no automatic retry, backoff, cache, offline queue, explicit logging, or connectivity status. The forced `Host` header is environment-specific and unsuitable for browser builds.

## 11. Frontend Structure

### Screens and navigation

- Loading screen: indeterminate restoration state.
- Login: responsive centered card, autofill, password visibility toggle, inline errors, submission spinner.
- Dashboard: welcome panel and max-width module-card grid; exact permission visibility.
- POS: debounced search, responsive 2/3/4-column grid, product cards, cart badge, bottom-sheet cart/checkout.
- Orders: segmented filter, list cards, pull-to-refresh, detail modal, pay-due dialog.
- Settings: theme selection and logout.

Material 3 light/dark themes use a wine-colored seed and Google Poppins. Responsive behavior is primarily width-based grids and constrained content; no dedicated tablet/desktop navigation shell exists.

### UI/backend parity issues

1. Local cart totals are estimates; server quote is authoritative.
2. The cart permits quantities above stock, and backend also lacks stock availability validation.
3. Customer discount is duplicated into the client and sent back to the server.
4. Customer/report cards are permission-visible but nonfunctional.
5. POS/order pagination metadata is ignored, so valid records silently disappear after row limits.
6. Checkout/pay errors can be hidden by modals or unhandled.
7. Buttons are hidden by dashboard permission but direct client routes remain available; server still enforces permission.
8. Some active strings contain mojibake such as `â€¢` and `Ã—`, indicating an encoding conversion problem.
9. Product search requests can complete out of order.
10. There is no explicit empty-product result state or POS pull-to-refresh.

## 12. Important Files

| File path | Purpose / important symbols | Related workflow | Risk |
|---|---|---|---|
| `lib/main.dart` | `main()` and `ProviderScope` | Startup | Low |
| `lib/app/app.dart` | `MixAndSipApp` | App composition/theme/router | Medium |
| `lib/app/router/app_router.dart` | `appRouterProvider`, redirect/routes | All navigation/auth | High |
| `lib/core/config/app_environment.dart` | `API_BASE_URL`, `API_HOST` | All APIs | High |
| `lib/core/api/api_client.dart` | Dio options/interceptors | All APIs/session | High |
| `lib/core/api/api_error_parser.dart` | Laravel/Dio error conversion | All failures | Medium |
| `lib/core/storage/token_storage.dart` | Secure token CRUD | Authentication | High |
| `lib/core/permissions/permission_service.dart` | Exact permission helper | Authorization | Low |
| `lib/core/api/items_service.dart` | Legacy query-style catalog adapter | Dormant item list | Medium |
| `lib/core/apiconfig.dart` | Duplicate API config/Gemini key define | Dormant integrations | High |
| `lib/features/authentication/data/auth_repository.dart` | Login/restore/logout | Authentication | Critical |
| `lib/features/authentication/presentation/controllers/auth_controller.dart` | Session state/providers | Authentication/router | Critical |
| `lib/features/authentication/presentation/screens/login_screen.dart` | Login form/validation | Login | Medium |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Permission cards | Module access | Medium |
| `lib/features/pos/domain/pos_models.dart` | Product/customer/cart/quote DTOs | POS | High |
| `lib/features/pos/data/pos_repository.dart` | Catalog/quote/sale payloads | POS checkout | Critical |
| `lib/features/pos/presentation/controllers/pos_controller.dart` | Cart/search/quote/checkout state | POS | Critical |
| `lib/features/pos/presentation/screens/pos_screen.dart` | POS and cart UI | POS | High |
| `lib/features/orders/domain/order_summary.dart` | Order-list parsing | Orders | Medium |
| `lib/features/orders/data/orders_repository.dart` | Lists/items/pay-due | Orders | High |
| `lib/features/orders/presentation/controllers/orders_controller.dart` | Filter/list state | Orders | Medium |
| `lib/features/orders/presentation/screens/orders_screen.dart` | List/detail/payment UI | Orders | High |
| `lib/features/settings/presentation/controllers/theme_controller.dart` | Theme persistence | Settings | Low |
| `analysis_options.yaml` | Lints and broad exclusions | Whole codebase quality | Critical |
| `pubspec.yaml` | Package identity/dependencies/assets | Build/release | High |
| `android/app/src/main/AndroidManifest.xml` | Android label/network permission | Android | Medium |
| `android/app/src/debug/AndroidManifest.xml` | Debug cleartext exception | Local Android | High |
| `android/app/build.gradle.kts` | IDs, SDK, debug release signing | Android release | Critical |
| `ios/Runner/Info.plist` | iOS name/platform behavior | iOS release | High |
| `macos/Runner/*.entitlements` | Sandbox/network rights | macOS | Critical |
| `web/index.html`, `web/manifest.json` | PWA identity/metadata | Web | Medium |
| `test/permission_service_test.dart` | Exact permission test | Authorization | Low |
| `test/product_model_test.dart` | Nullable stock parsing test | Catalog | Low |
| `lib/views/billingchatassistant/chatasistant.dart` | Dormant direct Gemini request | Prototype AI | Critical if activated |
| `lib/views/fraudmistakedetection/frauddetection.dart` | Dormant direct Gemini request | Prototype AI | Critical if activated |

## 13. Risks and Technical Debt

### Critical

1. **Duplicate-sale retry window — confirmed across repositories.** Flutter creates `client_reference` inside each HTTP attempt. A committed sale with a lost response is retried under a new UUID, bypassing Laravel's unique/idempotent replay check. Generate one reference per logical cart transaction, persist it until a conclusive response, and reuse it for retries.
2. **Client-controlled discount — confirmed across repositories.** Flutter sends `discount_percent`, and Laravel prefers that submitted value over the customer's database value. Any modified client with `pos.menu` can request a discount up to 100%. Pricing policy must be enforced server-side; special override permission/audit should be explicit.
3. **Overselling and negative stock — confirmed across repositories.** Flutter does not cap quantity to stock. Laravel validates existence/expiry but not available quantity, then decrements stock for completed sales/pay-due. Concurrent or excessive sales can make inventory negative.
4. **Authentication/token state divergence — confirmed from code.** A 401 clears storage without changing auth state. A failed logout clears storage but may leave state authenticated. Screens can remain open with no usable token, producing repeated failures until restart or another state transition.
5. **Most Dart code is excluded from analysis — confirmed from code.** `analysis_options.yaml` excludes roughly 94% of Dart lines. Dormant code can accumulate syntax/API/lint issues without detection and may be unsafe to activate.
6. **Release security/build identity unfinished — confirmed from code.** Android release uses debug signing and `com.example.invoiceandbilling`; Apple/web/desktop retain template identity. This blocks a safe store/release process and can create package/key migration problems if published prematurely.

### High

1. **Quote/checkout race.** Flutter sends the old quote total as `pay`, while Laravel recalculates current price/discount. A lower new total fails as overpayment; a higher total creates an unintended pending order while Flutter reports success and clears the cart.
2. **Default HTTP API works only for Android debug.** Profile/release Android cleartext, iOS ATS, macOS client entitlements, web mixed content/CORS, and platform-specific addresses are incomplete.
3. **Transient startup failures destroy sessions.** Any `/auth/me` failure, including timeout/offline, clears a potentially valid token.
4. **Incomplete checkout error visibility.** Errors are stored outside the cart sheet, tendered validation is weak, and ambiguous errors invite cashier retries—the worst case for duplicate sales.
5. **Pay-due UI lacks failure/submission controls.** Errors can escape, double taps are possible, method is always Cash, and the visible list is not explicitly refreshed.
6. **Catalog/order truncation.** Products stop at 40, customers/orders at 50; pagination metadata is ignored. This creates silent operational omissions.
7. **Web target is not build-compatible.** `dart:io Platform` is imported by active authentication. The `Host` header strategy also conflicts with browser networking.
8. **Dormant client-side Gemini design.** If activated, an API key would be extractable from the binary and invoice/business content would be sent directly to Google without a reviewed server-side policy.
9. **No stock and payment workflow tests.** Financial/inventory behavior is almost entirely untested.
10. **No Git repository detected at the supplied path.** There is no local history/status to distinguish intentional changes from template residue or to safely review/revert future work.

### Medium

1. Client route guards do not enforce POS/order permissions; backend does, but unauthorized direct routes provide poor behavior.
2. POS search requests can return out of order; no Dio cancellation/generation check exists.
3. Customer ID 26 is a hard-coded default assumption.
4. Auto-disposed POS state loses the cart on navigation and process termination.
5. `GoRouter` is reconstructed whenever watched auth state changes, which may reset navigation state; runtime verification is needed.
6. DTO parsing uses force unwraps/casts and can crash on compatible-but-null or changed responses.
7. Order detail errors render an endless spinner.
8. Customer and report dashboard cards have empty actions.
9. API configuration is duplicated between `app_environment.dart` and `apiconfig.dart`.
10. No structured logging, crash reporting, request IDs, or audit visibility exists in Flutter.
11. Active source contains encoding artifacts in user-visible text.
12. `payment_status` and `payment_method` have overlapping semantics, increasing reporting ambiguity.
13. The server pricing code casts selling price to integer before converting to cents; fractional pricing needs verification.
14. Many declared packages/assets are used only by dormant UI, increasing dependency and binary surface.

### Low

1. Theme mode uses secure storage despite not being sensitive and can restore after first paint, causing a theme flicker.
2. README, web description, product metadata, copyright, icons, and desktop names are generic template values.
3. The cart badge counts distinct lines rather than total item quantity, which may surprise cashiers.
4. No explicit empty-product state, change-due display, or POS pull-to-refresh exists.
5. Formatting and naming in dormant folders contain typos (`qotationslist`, `deliverychalanlist`, `bankkdetails`, `homme`, `detials`).

## 14. Testing and Verification

### Existing tests

1. `permission_service_test.dart` verifies exact/case-sensitive permission matching and `hasAll`.
2. `product_model_test.dart` verifies nullable Laravel product stock becomes zero and integer price parses to double.

There are no widget tests, router tests, golden tests, repository tests, mocked API tests, authentication tests, secure-storage tests, POS controller tests, quote/checkout contract tests, idempotency tests, order/payment tests, platform build tests, integration tests, or end-to-end tests.

### Commands attempted

| Check | Result | Interpretation |
|---|---|---|
| Git status | Could not run: supplied directory is not a Git repository | Repository provenance/version history unavailable |
| Dart version | Passed: Dart 3.12.2 stable | SDK executable is present |
| Dart analysis of active `main/app/core/features/shared/test` | Passed: “No issues found” | Active code passes current static analysis |
| Whole `lib,test` analysis | Did not finish within 60 seconds | Broad tree is large; exclusions also limit meaningful coverage |
| `flutter --version` / `flutter doctor -v` | Hung with no output past 60 seconds | Flutter command startup/tool lock/environment needs investigation |
| `flutter test --reporter expanded` | Hung with no output and was terminated after bounded wait | Tests did not pass or fail; they were not runnable in this shell |

No backend API calls, login attempts, checkout requests, database commands, migrations, seeders, dependency upgrades, builds, or device launches were performed.

### Priority test gaps

1. Stable idempotency reference across timeout/retry/restart.
2. Server-owned discounts and stock enforcement, including concurrency.
3. Quote-to-checkout price changes.
4. 401, offline restore, logout timeout, and router transitions.
5. Tendered/pay validation and change calculations.
6. Pending-due completion and duplicate taps.
7. Pagination and large customer/catalog/order sets.
8. Malformed/null API payloads.
9. Android release, iOS, Windows, and web build smoke tests.

## 15. Unknowns and Questions

1. Which platforms are actually in scope: Android tablet only, Android/iOS phones, web, or desktop POS?
2. Is customer ID 26 the official walk-in customer in every environment?
3. Should POS users be limited by branch, warehouse, register, shift, or company?
4. Is negative stock allowed by business policy, and when should stock be reserved/decremented?
5. Can cashiers override discounts? If so, which permission, maximum, reason, and audit record are required?
6. Are partial payments/drafts intended? Flutter currently always attempts full payment; pay-due requires the entire remaining amount.
7. Should Card/Transfer require reference numbers or payment gateway confirmation?
8. Should tendered apply only to Cash, and should change be displayed/printed?
9. Are prices always whole currency units? Backend integer casting may discard fractional prices.
10. What is the authoritative tax/VAT rule? The API currently returns zero tax.
11. Is invoice number generation safe under concurrent terminals in the deployed database?
12. Has the unique `orders.client_reference` migration been applied everywhere?
13. What is Sanctum token lifetime/revocation policy, and should devices be managed by users/admins?
14. Is offline selling required? Current architecture cannot safely sell without the server.
15. Are receipts, PDF invoices, printers, barcode scanners, cash drawers, and email required?
16. Are the invoice/billing template screens licensed/desired, or should they remain quarantined until a later decision?
17. Why is the Flutter tool hanging in this shell despite the SDK and Dart executable being present?
18. Where is the intended Git remote/history for this app?
19. Does the API run at port 80 behind `pos.test`, or does the base URL need an explicit port?
20. What production HTTPS domain and certificate will replace local HTTP/forced Host routing?

## 16. Recommended Next Steps

Do not begin broad feature work until the critical sale-integrity questions are resolved. A safe order is:

1. Put the Flutter project under Git/version control and capture the current baseline without modifying behavior.
2. Decide supported platforms and production application IDs, signing, HTTPS API domain, and environment strategy.
3. Repair the Flutter SDK invocation/tooling, run existing tests, and add CI that analyzes the intended source tree.
4. Resolve server-owned discount rules and atomic stock availability validation before production checkout tests.
5. Redesign checkout idempotency so one persisted reference represents one logical cart until a conclusive result.
6. Define quote-expiration/repricing behavior and have checkout return/render the actual authoritative payment status, due, tendered, and change.
7. Make authentication transitions consistent for 401, offline restore, and failed logout.
8. Add high-value contract/controller tests for login, permissions, quote, sale, retry, stock, payments, and pagination.
9. Implement pagination/customer search and robust modal error/loading states.
10. Decide the fate of the dormant invoice/billing prototype. Keep it isolated; do not activate direct Gemini calls or mock screens accidentally.
11. Add operational features only after requirements are confirmed: register/shift/branch scope, receipt printing, barcode scanning, offline policy, and payment references.
12. Perform controlled runtime verification against a dedicated local/test Laravel database—never the existing production database—and document exact observed responses/status transitions.

## 17. First Files to Review

For a focused owner review, start in this order:

1. `lib/features/pos/data/pos_repository.dart`
2. `lib/features/pos/presentation/controllers/pos_controller.dart`
3. `lib/features/pos/presentation/screens/pos_screen.dart`
4. `lib/core/api/api_client.dart`
5. `lib/features/authentication/data/auth_repository.dart`
6. `lib/features/authentication/presentation/controllers/auth_controller.dart`
7. `lib/app/router/app_router.dart`
8. `lib/features/orders/presentation/screens/orders_screen.dart`
9. `lib/features/orders/data/orders_repository.dart`
10. `analysis_options.yaml`
11. `pubspec.yaml`
12. `android/app/build.gradle.kts` and platform manifests/entitlements

For the cross-repository contract, review Laravel `routes/api.php`, `app/Http/Controllers/Api/V1/PosController.php`, `app/Services/PosPricingService.php`, `app/Services/PosSaleService.php`, `app/Http/Controllers/Api/OrdersController.php`, and the customer discount/client-reference migrations alongside the Flutter files above.
