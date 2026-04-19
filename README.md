# LangFlash

Kid-friendly Spanish flashcards with:
- email/password auth
- user-owned cards with optional images
- English->Spanish and Spanish->English multiple-choice quizzes
- adaptive question weighting (weaker cards appear more)
- per-user progress dashboard
- Google Translate suggestions for card creation

## Setup

1. Install gems:
   - `bundle install`
2. Create and migrate DB:
   - `bin/rails db:prepare`
3. (Optional) Configure Google Translate credentials:
   - set `GOOGLE_CLOUD_PROJECT`
   - set `GOOGLE_APPLICATION_CREDENTIALS` to your service account JSON path
4. Start server:
   - `bin/rails server`
5. Visit:
   - [http://localhost:3000](http://localhost:3000)

If Google credentials are missing, card creation still works; translation suggestion simply falls back silently.

## Test

- `bin/rails test`
