// Helper macros to aid in optimizing lazy instantiation of lists.
// All of these are null-safe, you can use them without knowing if the list var is initialized yet

///Picks from the list, with some safeties, and returns the "default" arg if it fails
#define DEFAULTPICK(L, default) ((islist(L) && length(L)) ? pick(L) : default)

// Sets a L back to null iff it is empty
#define UNSETEMPTY(L) if (L && !length(L)) L = null

// Removes I from list L, and sets I to null if it is now empty
#define LAZYREMOVE(L, I) if(L) { L -= I; if(!length(L)) { L = null; } }

// Adds I to L, initalizing L if necessary
#define LAZYADD(L, I) if(!L) { L = list(); } L += I;

#define LAZYOR(L, I) if(!L) { L = list(); } L |= I;

// Adds I to L, initalizing L if necessary, if I is not already in L
#define LAZYDISTINCTADD(L, I) if(!L) { L = list(); } L |= I;

// Reads I from L safely - Works with both associative and traditional lists.
#define LAZYACCESS(L, I) (L ? (isnum(I) ? (I > 0 && I <= length(L) ? L[I] : null) : L[I]) : null)

// Turns LAZYINITLIST(L) L[K] = V into ...  for associated lists
#define LAZYSET(L, K, V) if(!L) { L = list(); } L[K] = V;

// Reads the length of L, returning 0 if null
#define LAZYLEN(L) length(L)

#define LAZYADDASSOC(L, K, V) if(!L) { L = list(); } L[K] += V;
///This is used to add onto lazy assoc list when the value you're adding is a /list/. This one has extra safety over lazyaddassoc because the value could be null (and thus cant be used to += objects)
#define LAZYADDASSOCLIST(L, K, V) if(!L) { L = list(); } L[K] += list(V);
#define LAZYREMOVEASSOC(L, K, V) if(L) { if(L[K]) { L[K] -= V; if(!length(L[K])) L -= K; } if(!length(L)) L = null; }
#define LAZYACCESSASSOC(L, I, K) L ? L[I] ? L[I][K] ? L[I][K] : null : null : null

// Sets a list to null
#define LAZYNULL(L) L = null

// Null-safe L.Cut()
#define LAZYCLEARLIST(L) if(L) { L.Cut(); L = null; }

// Reads L or an empty list if L is not a list.  Note: Does NOT assign, L may be an expression.
#define SANITIZE_LIST(L) ( islist(L) ? L : list() )

#define reverseList(L) reverseRange(L.Copy())

#define islist(L) istype(L, /list)

/// Performs an insertion on the given lazy list with the given key and value. If the value already exists, a new one will not be made.
#define LAZYORASSOCLIST(lazy_list, key, value) \
	LAZYINITLIST(lazy_list); \
	LAZYINITLIST(lazy_list[key]); \
	lazy_list[key] |= value;
