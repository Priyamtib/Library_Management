# AURELIA — The Library Club

A polished, responsive library-management showcase built using **all five required technologies: HTML, CSS, JavaScript, Java and Kotlin**.

## What the showcase does
- Student dashboard with borrowing, due-date, reading and request summaries.
- Searchable book catalogue with genre filters, sorting, book details and saved titles.
- Borrow and return workflow with 14-day due dates and a four-book borrowing limit.
- Personal bookshelf, reading history and book suggestions.
- Librarian desk to add titles, review requests and view inventory.
- Responsive layout, accessible controls, subtle motion and a dark reading theme.

## The five technologies — and exactly where they are used

| Required technology | Where it is used | Responsibility |
|---|---|---|
| **HTML** | `index.html` | Semantic page structure, navigation, forms, catalogue sections and dialogs |
| **CSS** | `assets/css/styles.css` | Complete visual design, responsive layouts, animations and light/dark themes |
| **JavaScript** | `assets/js/app.js` | Browser interactions, searching/filtering, borrowing/returns, requests and local persistence |
| **Java** | `java/LibraryManager.java` | Typed library domain model, catalogue search, borrowing limits, due dates and returns |
| **Kotlin** | `kotlin/LibraryConsole.kt` | Kotlin implementation of the library domain workflow, including search, borrowing and returns |

Java and Kotlin are runnable companion modules demonstrating the same core library rules. The website runs in the browser using HTML, CSS and JavaScript; the Java and Kotlin console modules are separate demonstrations, not server processes.

## Run the website
Open `index.html` in a modern browser, or publish the repository with GitHub Pages. No build step, database, API key or package installation is required.

## Demo behaviour and data
This is intentionally a **frontend showcase**, not a production library deployment:
- The browser stores demo data in `localStorage`, so changes remain after refresh on the same browser/device.
- Demo profile name, saved books, loans, returns, requests and librarian edits are local to that browser.
- There is no real account authentication, shared database, cross-device sync or institutional access control.
- Use the **Librarian desk** navigation item to demonstrate adding books and processing requests.

## Run the Java module
With a JDK installed:
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
├── java/LibraryManager.java
├── kotlin/LibraryConsole.kt
└── README.md
```
