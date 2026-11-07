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

## Important implementation note
The web experience is a **front-end demonstration**. Its sample data and changes are stored in the current browser using `localStorage`; they are not shared between users or devices. The Java and Kotlin programs are standalone console modules and are not wired to the website. There is no server, production authentication, remote database, email service or cross-device synchronisation.

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
├── java/LibraryManager.java
├── kotlin/LibraryConsole.kt
└── README.md
```
