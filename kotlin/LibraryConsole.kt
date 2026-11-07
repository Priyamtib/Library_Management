import java.time.LocalDate

/**
 * Kotlin console companion for Aurelia.
 * Demonstrates catalogue search, borrowing limits, due dates and returns.
 * Standalone learning module; it does not connect to the browser's local storage.
 */
data class LibraryBook(
    val id: String,
    val title: String,
    val author: String,
    var available: Int,
    val total: Int = available
)
data class LibraryLoan(
    val memberId: String,
    val bookId: String,
    val borrowedOn: LocalDate = LocalDate.now(),
    val dueOn: LocalDate = LocalDate.now().plusDays(14),
    var returnedOn: LocalDate? = null
)

class AureliaLibrary {
    private val books = linkedMapOf<String, LibraryBook>()
    private val loans = mutableListOf<LibraryLoan>()

    fun addBook(book: LibraryBook) {
        require(!books.containsKey(book.id)) { "Book ID already exists." }
        require(book.available >= 0) { "Copies cannot be negative." }
        books[book.id] = book
    }
    fun search(term: String): List<LibraryBook> =
        books.values.filter {
            it.title.contains(term, ignoreCase = true) ||
            it.author.contains(term, ignoreCase = true)
        }
    fun borrow(memberId: String, bookId: String): LibraryLoan {
        val book = books[bookId] ?: error("Book not found.")
        require(loans.count { it.memberId == memberId && it.returnedOn == null } < 4) {
            "Borrowing limit reached."
        }
        require(book.available > 0) { "No copies available." }
        book.available--
        return LibraryLoan(memberId, bookId).also { loans.add(it) }
    }
    fun returnBook(memberId: String, bookId: String) {
        val loan = loans.firstOrNull {
            it.memberId == memberId && it.bookId == bookId && it.returnedOn == null
        } ?: error("No active loan found.")
        loan.returnedOn = LocalDate.now()
        books.getValue(bookId).available++
    }
    fun activeLoans(memberId: String) =
        loans.filter { it.memberId == memberId && it.returnedOn == null }
}

fun main() {
    val library = AureliaLibrary()
    library.addBook(LibraryBook("A001", "The Alchemist", "Paulo Coelho", 4))
    library.addBook(LibraryBook("A002", "Wings of Fire", "A. P. J. Abdul Kalam", 3))
    println("AURELIA · KOTLIN LIBRARY MODULE")
    library.search("wings").forEach { println("${it.id} | ${it.title} — ${it.author}") }
    val loan = library.borrow("STU-101", "A002")
    println("Due date: ${loan.dueOn}")
    library.returnBook("STU-101", "A002")
    println("Active loans: ${library.activeLoans("STU-101").size}")
}