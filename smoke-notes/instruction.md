# Notes: product brief

Build a tiny web product where people keep private notes. It is small on purpose: it checks that a
factory can build, start and secure a whole product.

## 1. Accounts

- **Sign up** with an email and a password of at least 8 characters. Sign-up takes effect at once:
  no email confirmation. A used email is refused.
- **Log in** and **log out**. A session is a cookie.

## 2. Notes

- A person adds a note: a line of text, 1 to 500 characters.
- A person sees a list of their own notes, newest first, and deletes any of them.
- A person never sees, changes or deletes the notes of another person. A note id that is not theirs
  answers exactly as an id that does not exist.

## 3. Interface

The page at `/` holds everything. Use these names exactly.

| Where | Element | Name |
|---|---|---|
| Signed out | fields; buttons | "Email", "Password"; "Sign up", "Log in" |
| Signed in | button | "Log out" |
| Signed in | field; button | "Note"; "Add note" |
| Signed in | list of notes, one list item per note | each item shows the note text and a button "Delete" |
| Signed out | message after a refused sign-up or log-in | the word "refused" |

## 4. HTTP interface

All bodies are JSON. A missing or wrong session answers 401.

| Request | Answer |
|---|---|
| `POST /api/signup` `{"email","password"}` | 201 and a session cookie. 400 for a bad email or a short password. 409 for a used email. |
| `POST /api/login` `{"email","password"}` | 200 and a session cookie. 401 for a wrong email or password. |
| `POST /api/logout` | 204. The cookie stops working. |
| `GET /api/notes` | 200 and a list of `{"id","text"}`, newest first. |
| `POST /api/notes` `{"text"}` | 201 and `{"id","text"}`. 400 for empty or longer than 500 characters. |
| `DELETE /api/notes/{id}` | 204. 404 when the note is not the caller's or does not exist. |

## 5. Running it

- **Where to build.** Build the product in `/app` on the machine you're given. Grading copies only
  `/app` onto a fresh copy of that machine and runs `/app/start.sh` there as an ordinary user (not
  root) who owns `/app`. Anything outside `/app` is lost.
- **Start command.** `/app/start.sh` is executable. Run with no arguments, it starts the whole product.
  Within 1 minute the product serves everything on port 3000, on all network interfaces, and keeps
  serving until stopped.
- **Self-contained.** The product runs on that one machine alone: no outside services, accounts or keys.
  It works over plain HTTP.

## 6. Out of scope

Editing notes, sharing, search, password reset, email.
