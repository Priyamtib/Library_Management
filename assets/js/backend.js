(() => {
  "use strict";
  const configured = () => Boolean(window.AURELIA_SUPABASE_URL && window.AURELIA_SUPABASE_ANON_KEY);
  let client = null;
  const getClient = () => {
    if (!configured()) throw new Error("Supabase is not configured yet. Add the Project URL and anon key in assets/js/supabase-config.js.");
    if (!window.supabase?.createClient) throw new Error("Supabase client library could not be loaded. Check your internet connection.");
    if (!client) client = window.supabase.createClient(window.AURELIA_SUPABASE_URL, window.AURELIA_SUPABASE_ANON_KEY, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
    });
    return client;
  };
  const result = async (promise) => { const {data,error}=await promise; if(error)throw error; return data; };
  const api = {
    isConfigured: configured,
    client: getClient,
    async signIn(email,password) { return result(getClient().auth.signInWithPassword({email,password})); },
    async signUp(email,password,name) {
      return result(getClient().auth.signUp({email,password,options:{data:{display_name:name}}}));
    },
    async signOut() { return result(getClient().auth.signOut()); },
    async session() { return result(getClient().auth.getSession()); },
    async bootstrap() {
      const c=getClient(), session=await result(c.auth.getSession());
      if(!session.session) return null;
      const uid=session.session.user.id;
      const [profile,books,loans,requests,saved]=await Promise.all([
        result(c.from("profiles").select("id,display_name,role").eq("id",uid).single()),
        result(c.from("books").select("*").order("title")),
        result(c.from("loans").select("*").eq("user_id",uid).order("borrowed_at",{ascending:false})),
        result(c.from("book_requests").select("*").eq("user_id",uid).order("created_at",{ascending:false})),
        result(c.from("saved_books").select("book_id").eq("user_id",uid))
      ]);
      return {profile,books,loans,requests,saved};
    },
    async borrow(bookId) { return result(getClient().rpc("borrow_aurelia_book",{p_book_id:bookId})); },
    async returnBook(loanId) { return result(getClient().rpc("return_aurelia_book",{p_loan_id:loanId})); },
    async createRequest(payload) { return result(getClient().from("book_requests").insert(payload).select().single()); },
    async updateRequest(id,status) { return result(getClient().from("book_requests").update({status}).eq("id",id).select().single()); },
    async addBook(book) { return result(getClient().from("books").insert(book).select().single()); },
    async toggleSaved(bookId,isSaved,userId) {
      if(isSaved) return result(getClient().from("saved_books").delete().eq("book_id",bookId).eq("user_id",userId));
      return result(getClient().from("saved_books").insert({book_id:bookId,user_id:userId}));
    },
    async updateName(name) { return result(getClient().from("profiles").update({display_name:name}).select().single()); },
    async isLibrarian() {
      const session=await result(getClient().auth.getSession());
      if(!session.session)return false;
      const p=await result(getClient().from("profiles").select("role").eq("id",session.session.user.id).single());
      return p.role==="librarian";
    }
  };
  window.AureliaBackend=api;
})();
