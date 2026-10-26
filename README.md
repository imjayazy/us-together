# Us Together — Couple Fitness & Habit Tracker

Responsive website for two people: accounts, shared couple invite code, task lists, completion tracking, workout logs, habit check-ins and weekly progress.

## How shared sync works
GitHub Pages hosts the static website. Supabase provides authentication and the shared database.

## Setup
1. Create a free project at https://supabase.com.
2. In the project's SQL Editor, run the complete contents of `supabase_schema.sql`.
3. In Supabase Project Settings → API (or Connect), copy the **Project URL** and **anon/publishable key**.
4. Open `index.html` in a text editor and replace `PASTE_SUPABASE_PROJECT_URL_HERE` and `PASTE_SUPABASE_ANON_OR_PUBLISHABLE_KEY_HERE`.
   **Never** use a `service_role` or secret key in browser code.
5. Create a GitHub repository. Upload `index.html`, `README.md`, and `supabase_schema.sql` to its root.
6. GitHub repo → Settings → Pages → Build and deployment → Deploy from a branch → `main` → `/ (root)` → Save.
7. In Supabase Authentication → URL Configuration, set the Site URL to your GitHub Pages URL, e.g. `https://YOUR-USERNAME.github.io/YOUR-REPO/`. Add the same URL under Redirect URLs if requested.
8. Open the website. Both people create separate accounts. One creates a couple space and privately shares the invite code. The other signs in and joins with that code.

If Supabase email confirmation is enabled, confirm each account's email before signing in.

## Included
- Overview dashboard for both partners
- Tasks with due date, category, assignee, completion and delete
- Workout log with exercise, sets, reps, weight, duration and notes
- Habit check-ins (including your reading and evening chat times)
- 7-day workout chart and personal summaries
- Responsive mobile layout

## Security
RLS is enabled in the schema. Review and test the policies with two separate accounts before adding sensitive information. Keep the invite code private. Never publish passwords or service-role keys.
