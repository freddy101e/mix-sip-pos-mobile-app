# Loyalty card reminder

The Flutter app and companion Laravel repository at `C:\wamp64\www\mix-and-sip-pos` contain this feature.

In the web admin dashboard, open **Loyalty cards** and set a start and end date. Both dates are inclusive in the Laravel application's configured time zone. Clear both dates to disable the reminder. Settings require the existing SuperAdmin role and dashboard.view permission.

The app checks `GET /api/v1/pos/loyalty-cards` before completing a fully paid new sale. While active, staff must choose **Loyalty card received**, **Loyalty card given**, or **Continue anyway**. Back to order cancels saving. Failed setting requests leave the order unsaved so the cashier can retry.

The selection is saved as `orders.loyalty_card_status`: `received`, `given`, or `skipped`. A null value means no response was recorded, including older orders. Skipped does not classify an order as a delivery. Responses are visible in app order details, web order details, and the admin loyalty activity table. Saving an unpaid or partially paid pending order skips the reminder. When staff pay its outstanding due, the app checks `/orders/loyalty-cards` and requires a choice during the active dates before submitting payment. The choice is saved atomically with the payment. Editing an order retains its response.

## Release order

1. Deploy the companion Laravel changes and run `php artisan migrate --path=database/migrations/2026_09_12_000001_add_loyalty_cards.php --force`.
2. Rebuild and distribute the Flutter app. The new app requires the loyalty settings endpoint.
3. Set the campaign dates after cashiers have updated. Older app versions cannot complete payments during an active campaign because the API requires a response.

The local migration could not run because WAMP MySQL is stopped and this process cannot start the Windows service. The migration and feature were tested against an isolated SQLite database. No production deployment was performed.
