# AURELIA — The Library Club

A polished, responsive library experience built with **HTML, CSS, JavaScript, Java and Kotlin**.

## Experience
- Student overview with borrowing, due-date, reading and request summaries.
- Searchable catalogue with genre filters, sorting, book details and saved titles.
- Borrowing and returning with a 14-day due date and a four-book limit.
- Reading history and member book requests.
- A lightweight librarian desk for adding titles, reviewing requests and checking inventory.
- Responsive layout, accessible controls, subtle motion and a dark reading theme.

## Run the web experience
Open `index.html` in a modern browser, or publish the repository with GitHub Pages. No build step or package installation is required.

## Technology modules
| Technology | Role |
|---|---|
| HTML | Semantic application structure |
| CSS | Responsive visual system, layout, animation and themes |
| JavaScript | Interactive UI, catalogue, loan workflow and browser persistence |
| Java | Standalone typed library domain model and console demonstration |
| Kotlin | Standalone Kotlin library companion with matching borrowing rules |

## Backend and authentication
The browser app includes an optional Supabase integration for email/password authentication, shared catalogue data, per-member loans, requests, saved books and librarian-only collection/request management. Borrowing and returns use PostgreSQL functions so copy counts update on the database, and Row Level Security restricts each member's records.

**The live backend is not connected until you configure a Supabase project.**
1. Create a Supabase project and enable Email authentication.
2. Run the complete `supabase/schema.sql` file in the Supabase SQL Editor.
3. Open `assets/js/supabase-config.js` and enter your Project URL and anon/publishable key. These are browser-safe values; never use the `service_role` secret in this repository.
4. To grant librarian access, run the following in SQL Editor, replacing the email:
   `update public.profiles p set role = 'librarian' from auth.users u where p.id = u.id and u.email = 'LIBRARIAN_EMAIL';`
5. Sign up or sign in from the app. Until Supabase is configured, the interface remains available in clearly labelled local-demo mode using this browser's storage.

New accounts default to the `member` role and cannot promote themselves. Java and Kotlin remain standalone console modules; they are not connected to the web backend.

## Run the Java module
```bash
javac java/LibraryManager.java
java -cp java LibraryManager
```

## Run the Kotlin module
With the Kotlin command-line compiler installed:
```bash
kotlinc kotlin/LibraryConsole.kt -include-runtime -d aurelia-kotlin.jar
java -jar aurelia-kotlin.jar
```

## Project structure
```
.
├── index.html
├── assets/
│   ├── css/styles.css
│   └── js/app.js
├── supabase/schema.sql
├── java/LibraryManager.java
├── kotlin/LibraryConsole.kt
└── README.md
```
