# LiveLocal final real-device QA

Use the staging debug APK on an Android device. Record PASS/FAIL and a short note for each item.

## Guest

1. Launch the app.
2. Search for a Google place that is not in the LiveLocal seed data.
3. Open the external place detail.
4. Tap a protected action and verify the login gate resumes safely.

## Tourist

5. Log in and verify the session survives an app restart.
6. Tap **Near me** and verify results use the device's real GPS location.
7. Save a Google place.
8. Add it to a Collection.
9. Add it to a Trip.
10. Reload/re-fetch and verify the external place still resolves.
11. Submit a named review.
12. Submit an anonymous review with a photo.

## Creator

13. Paste a Malaysian restaurant Google Maps link.
14. Tap **Generate with AI** once.
15. Verify the existing Restaurant form is auto-filled.
16. Edit at least one generated field.
17. Add the required eligible image, confirm image rights, and explicitly submit.

## Admin

18. Verify the Restaurant submission appears in the queue without restarting.
19. Inspect and approve it; verify the queue refreshes.

## Creator

20. Verify the submission status/outcome updates.

## Public

21. Verify the approved Restaurant is visible and its detail opens.

## General

22. Check English copy.
23. Check Bahasa Melayu copy.
24. Check Android back navigation.
25. Check keyboard dismissal and access to form actions.
26. Confirm there is no layout overflow.
27. Confirm there is no red error screen.
28. Confirm there is no infinite spinner.
29. Confirm scrolling and search feel smooth.
