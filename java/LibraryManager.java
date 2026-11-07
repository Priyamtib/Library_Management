import java.time.LocalDate;
import java.util.*;

/**
 * Aurelia library domain model and console demonstration.
 * This Java program is a standalone prototype; it is not connected to the browser demo.
 */
public class LibraryManager {
    static class Book {
        final String id, title, author;
        int totalCopies, availableCopies;
        Book(String id, String title, String author, int copies) {
            this.id=id; this.title=title; this.author=author;
            this.totalCopies=copies; this.availableCopies=copies;
        }
    }
    static class Loan {
        final String memberId, bookId;
        final LocalDate borrowedOn, dueOn;
        LocalDate returnedOn;
        Loan(String memberId, String bookId, LocalDate borrowedOn, LocalDate dueOn) {
            this.memberId=memberId; this.bookId=bookId;
            this.borrowedOn=borrowedOn; this.dueOn=dueOn;
        }
        boolean isActive() { return returnedOn == null; }
    }
    private final Map<String,Book> catalogue = new LinkedHashMap<>();
    private final List<Loan> loans = new ArrayList<>();
    public void addBook(Book book) {
        if (catalogue.containsKey(book.id)) throw new IllegalArgumentException("Duplicate book ID");
        catalogue.put(book.id, book);
    }
    public List<Book> search(String query) {
        String q=query.toLowerCase(Locale.ROOT);
        List<Book> matches=new ArrayList<>();
        for(Book b:catalogue.values())
            if(b.title.toLowerCase(Locale.ROOT).contains(q) ||
               b.author.toLowerCase(Locale.ROOT).contains(q)) matches.add(b);
        return matches;
    }
    public Loan borrow(String memberId, String bookId) {
        Book book=requireBook(bookId);
        long active=loans.stream().filter(l->l.memberId.equals(memberId)&&l.isActive()).count();
        if(active>=4) throw new IllegalStateException("Borrowing limit reached");
        if(book.availableCopies<1) throw new IllegalStateException("No copies available");
        book.availableCopies--;
        Loan loan=new Loan(memberId,bookId,LocalDate.now(),LocalDate.now().plusDays(14));
        loans.add(loan);
        return loan;
    }
    public void returnBook(String memberId, String bookId) {
        Loan loan=loans.stream().filter(l->l.memberId.equals(memberId)&&l.bookId.equals(bookId)&&l.isActive())
            .findFirst().orElseThrow(()->new IllegalStateException("No active loan found"));
        loan.returnedOn=LocalDate.now();
        requireBook(bookId).availableCopies++;
    }
    public List<Loan> activeLoans(String memberId) {
        List<Loan> result=new ArrayList<>();
        for(Loan loan:loans) if(loan.memberId.equals(memberId)&&loan.isActive()) result.add(loan);
        return result;
    }
    private Book requireBook(String id) {
        Book b=catalogue.get(id);
        if(b==null) throw new NoSuchElementException("Unknown book: "+id);
        return b;
    }
    public static void main(String[] args) {
        LibraryManager library=new LibraryManager();
        library.addBook(new Book("A001","The Alchemist","Paulo Coelho",4));
        library.addBook(new Book("A002","Wings of Fire","A. P. J. Abdul Kalam",3));
        System.out.println("AURELIA · JAVA LIBRARY MODULE");
        System.out.println("Search results for 'fire':");
        library.search("fire").forEach(b->System.out.println(b.id+" | "+b.title+" — "+b.author));
        Loan loan=library.borrow("STU-101","A002");
        System.out.println("Borrowed: "+loan.bookId+" | Due: "+loan.dueOn);
        library.returnBook("STU-101","A002");
        System.out.println("Active loans after return: "+library.activeLoans("STU-101").size());
    }
}