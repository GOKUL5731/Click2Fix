# Click2Fix UI Wireframes

Brand:

- Primary Blue: `#1976D2`
- Success Green: `#2E7D32`
- Emergency Red: `#D32F2F`
- Trust Gold: `#F9A825`
- Background Light: `#F5F7FA`

UI style:

- Modern card-based lists for worker, quote, booking, invoice, and review items.
- Large camera action on user home.
- Large emergency button visible on home.
- Rounded corners with professional spacing.
- Light and dark themes.
- English, Tamil, and Hindi localization hooks.

## User App Screens

1. Splash Screen
   - Center: Click2Fix logo and tagline.
   - Bottom: loading indicator and environment label for dev builds.

2. Onboarding Screen
   - Header: service promise.
   - Body: 3 pages for click, compare, fix.
   - Footer: Get Started and language selector.

3. Login Screen
   - Header: phone number entry.
   - Body: country code, mobile input, optional email login.
   - CTA: Send OTP.

4. OTP Verification Screen
   - Header: verify phone.
   - Body: 6 digit OTP input, resend timer.
   - CTA: Verify and Continue.

5. Face Verification Screen
   - Header: verify identity.
   - Body: camera preview or uploaded face image.
   - CTA: Capture Face, Skip for Now.

6. Home Dashboard
   - Top: greeting, current location, notification icon.
   - Center: large Take Photo button.
   - Secondary actions: Upload Gallery, Record Video, Type Issue, Voice.
   - Emergency: full-width red Emergency Fix button.
   - Bottom: active booking card and recent categories.

7. Upload Issue Screen
   - Top: media preview.
   - Body: description, category override, GPS pin.
   - CTA: Detect Problem.

8. AI Detection Result Screen
   - Summary card: category, confidence, urgency, price range.
   - Body: detected clues and editable description.
   - CTA: Find Nearby Workers.

9. Worker Comparison Screen
   - Top: sorting tabs for lowest price, best rating, nearest, fastest.
   - Body: worker quote cards with trust badge.
   - CTA per card: View Details, Book.

10. Worker Detail Screen
   - Header: photo, name, rating, trust score.
   - Body: skills, distance, arrival time, reviews, verification badges.
   - CTA: Book Worker.

11. Booking Confirmation Screen
   - Body: issue, worker, price, arrival time, address.
   - CTA: Confirm Booking.

12. Live Tracking Screen
   - Main: map with user and worker markers.
   - Bottom: ETA sheet, call, chat, cancel.

13. Chat Screen
   - Header: worker name and booking status.
   - Body: message list.
   - Footer: text input, media attach, quick phrases.

14. Voice Call Screen
   - Header: worker photo and call status.
   - Body: timer and speaker/mute controls.
   - CTA: End Call.

15. Payment Screen
   - Body: final amount, service fee, payment method.
   - CTA: Pay with Razorpay or UPI.

16. Review and Rating Screen
   - Body: star rating, review tags, comment.
   - CTA: Submit Review.

17. Booking History Screen
   - Top: filter chips.
   - Body: completed, active, canceled booking cards.

18. Invoice Screen
   - Body: invoice preview, worker, GST/service details, total.
   - CTA: Download PDF.

19. Notification Center
   - Body: quotes, booking updates, payment, offers, emergencies.
   - CTA: Mark all as read.

20. Profile Screen
   - Header: photo, name, phone, verification badge.
   - Body: addresses, payment methods, language, support.

21. Settings Screen
   - Body: theme, language, notification preferences, devices, logout.

22. Emergency Request Screen
   - Header: red critical service banner.
   - Body: emergency type, location, nearest workers.
   - CTA: Start Emergency Booking.

## Worker App Screens

1. Worker Login
   - Phone input, OTP action, support link.

2. Worker Registration
   - Name, phone, experience, city, category summary.

3. Aadhaar Upload Screen
   - Front/back upload, consent checkbox, submit.

4. Face Verification Screen
   - Selfie capture with face alignment hint.

5. Skill Selection Screen
   - Multi-select chips for plumbing, electrical, carpentry, cleaning, painting, appliance repair.

6. Working Area Setup Screen
   - Map radius selector and service zones.

7. Working Hours Screen
   - Day schedule rows and emergency availability toggle.

8. Worker Dashboard
   - Availability switch, active booking, nearby request count, earnings summary.

9. Nearby Requests Screen
   - Request cards with category, distance, urgency, price range.

10. Request Detail Screen
   - Issue media, location distance, description, AI result.

11. Quote Submission Screen
   - Price, arrival time, message, send quote.

12. Navigation Screen
   - Map route, ETA, call user, start trip.

13. Active Booking Screen
   - Status steps: accepted, on the way, arrived, work started, completed.

14. Earnings and Wallet Screen
   - Balance, payouts, booking earnings list.

15. Reviews Screen
   - Average rating, review list, trust score changes.

16. Availability Toggle Screen
   - ON/OFF state, reason for unavailable, next available time.

17. Worker Profile Screen
   - Identity, badges, categories, service area, documents, support.

## Admin Panel Screens

1. Admin Login
   - Email/password, OTP challenge for privileged admins.

2. Dashboard
   - KPI cards: total users, total workers, active bookings, emergency requests, revenue.
   - Charts: daily, weekly, monthly.
   - Panels: fraud alerts and worker approval queue.

3. User Management
   - Searchable user table, status filters, profile drawer.

4. Worker Management
   - Worker table, verification status, availability, trust score.

5. Worker Verification
   - Approval queue with documents, selfie match, action buttons.

6. Document Review
   - Aadhaar viewer, extracted details, manual notes, approve/reject.

7. Fraud Detection Dashboard
   - Fraud score cards, duplicate face alerts, price anomalies, fake review clusters.

8. Booking Management
   - Booking table, status timeline, worker/user links.

9. Complaint Management
   - Complaint queue, SLA timer, refund and escalation actions.

10. Emergency Monitoring
   - Live emergency map, priority queue, assigned workers, escalation controls.

11. Revenue Dashboard
   - GMV, commission, refunds, payouts, city/category filters.

12. Analytics Dashboard
   - Funnel, retention, category demand, worker supply heatmap.

13. Pricing Control
   - Category market rates, emergency surcharge, city multipliers.

14. Category Management
   - Create/edit category, skills, icon, AI mapping label.

15. Notification Broadcasting
   - Audience selector, message composer, preview, send schedule.

