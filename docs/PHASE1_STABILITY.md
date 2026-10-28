# PRM393 – Phase 1 stability verification

This package patches an existing `PRM393_Project` checkout/order workflow on the **dat** branch.
No database schema changes, package upgrades, or destructive commands are required.

## Automated checks (run on macOS with Flutter installed)

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

**Note:** No Android emulator or Flutter SDK was available where this patch was prepared, so these checks must be executed on your machine. Do not claim they passed before doing so.

## Manual verification

1. Customer: sign in, add a drink, create COD order, verify one order and empty cart.
2. Customer: make simulated MoMo payment, cancel payment dialog, verify cart unchanged and no order inserted.
3. Customer: submit simulated payment, verify single order and local confirmation notification.
4. Customer: test double-click on checkout: one order only.
5. Customer: cancel a pending order, verify cancelled status and notification history. For simulated paid order, confirm warning that no refund is performed.
6. Admin: sign in on the **same emulator** (SQLite is device-local), move status pending -> confirmed -> preparing -> delivering -> completed.
7. Admin: verify no false local notification appears on Admin device when changing customer order status.
8. Admin: verify impossible jumps are rejected by repository when attempted programmatically.
9. Test stale UI: open two order-detail views with same order, update one then the other; second attempt must fail safely and refresh state.
10. Test failed SQLite read/write (e.g., temporary debug injection) to verify retry banner, checkout Snackbar, and loading reset.
11. Run all pre-existing widget/unit tests, not only `order_stability_test.dart`.

## Behavior & limitations

- Successful order database write remains success even if notification history fails.
- SQLite UPDATE has a status predicate to detect outdated order-detail screens.
- Order notifications from Admin are stored in local SQLite history, NOT pushed to customer devices.
- This app remains a same-device customer/admin demo; real remote notifications require server + FCM.
- Simulated MoMo/card flows do not move money, and cancellation is NOT a refund.

## Troubleshooting

If patcher reports a missing anchor, the cloned code differs from the inspected master snapshot. Do not force the patch: compare those files manually, or send the current project ZIP for rebasing.
If you already have a feature branch and uncommitted work, commit or stash it before applying the patch.
