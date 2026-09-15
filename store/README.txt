FORGEN store listing rename (same app — do NOT create a new app)

App Store Connect
1. Open the existing app (Bundle ID io.fitforge.app).
2. App Information -> Name -> set to FORGEN.
3. Save. Upload the next build as usual; TestFlight continues on the same app.

Google Play Console
1. Open the existing app (applicationId forgen.app).
2. Main store listing -> App name -> set to FORGEN.
3. Save and publish listing / upload AAB as an update.

Do not change the iOS Bundle ID (io.fitforge.app).
Canonical names also live in:
- store/app_store_connect/name.txt
- store/play_console/title.txt

Subscriptions (must match the IDs in lib/core/subscription/billing_products.dart)

Product IDs:
- forgen.gymrat.monthly       (Gymrat, $4.99/month in the app UI)
- forgen.gymrat_pro.monthly   (Gymrat Pro, $9.99/month in the app UI)

Google Play Console
1. Put the app in at least internal/closed testing. IAP is unreliable without license testers.
2. Monetize -> Products -> Subscriptions: create both products with those exact IDs.
3. Add a monthly auto-renewing base plan, prices, and countries.
4. Add license testers (Gmail) for $0 test purchases.
5. Activate the subscriptions and attach them to a release.
6. Real-time developer notifications are optional; the app currently writes the plan after the Play Billing purchase.

App Store Connect (iOS)
1. Paid Apps agreement must be active.
2. Create auto-renewable subscriptions with the same product IDs.
3. Use Sandbox testers for TestFlight / sandbox purchases.

Referral plans are granted in Supabase: Gymrat at 3 active referrals, Gymrat Pro at 5. They are not Play/App Store products.
