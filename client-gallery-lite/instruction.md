# Client gallery lite: product brief

Build a web product that lets a photographer deliver photos to clients through private online
galleries, in the style of Pixieset Client Gallery. Photographers have accounts. Clients don't: they
get a private link.

## 1. Photographer

- **Account.** Sign up with an email and a password (at least 8 characters), log in and log out.
  Sign-up takes effect at once: no email confirmation and no CAPTCHA.
- **Galleries.** Create galleries, each with a name. The photographer sees a list of their own
  galleries and opens each one to manage it. A photographer never sees another photographer's
  galleries.
- **Upload.** Pick many photos at once (at least 50 in one go) and upload them. Large photos are
  normal. Uploads show progress. If the connection drops during an upload, the upload carries on by
  itself when the connection returns, without the photographer choosing the files again.
- **Sizes.** For each photo the product makes a thumbnail (long edge at most 800 px) for grids and a
  web size (long edge between 1600 px and 2048 px, or the original size if smaller) for full-screen
  viewing. The original stays available for download.
- **Cover photo.** The photographer chooses any photo as the gallery's cover. Until they choose, the
  cover is the first photo uploaded.
- **Gallery settings.** Each gallery has its own optional password, optional 4-digit download PIN,
  and a switch that turns client downloads on or off (on by default).
- **Sharing.** Each gallery has one private client link, shown in full on the gallery's page.

## 2. Client

- **Open.** The client opens the private link. No account is needed. If the gallery has a password,
  the client must enter it first. Until the right password is entered, the visitor receives no
  photos and no photo names from that gallery.
- **Browse.** The gallery page shows the cover photo first, above a grid of all photos. The grid
  is responsive: at 375 px wide it fits the screen with no sideways scrolling, and at 1280 px wide
  it shows at least three photos per row.
- **Full-screen viewer.** Selecting a photo opens it full-screen at web size, with next, previous
  and close controls. The Escape key also closes it.
- **Favourites.** The client marks and unmarks photos as favourites. Before their first favourite
  or download, the client gives their email; that email identifies them, and the product asks for
  it only once per browser. A client's favourites are still marked when they come back in the
  same browser.
- **Downloads.** If downloads are on, the client downloads single photos and can download all
  photos as one zip file. Downloads are full resolution: the same pixel size as the uploaded photo,
  under the uploaded file name. If the gallery has a download PIN, the client must enter it before
  any download. If downloads are off, the client sees no download controls and gets no originals.

## 3. Photographer dashboard

On each gallery's page, a client activity section lists, for each client email: the photos they
marked as favourite, and their downloads (which photo, or the whole gallery as a zip, and when).

## 4. Safety and privacy requirements

1. **Gallery links can't be guessed.** The client link contains a random secret of at least
   120 bits (for example 22 or more URL-safe characters). A link with any part of the secret
   changed shows "not found".
2. **Gallery IDs can't be enumerated.** No address the product exposes for a gallery or a photo
   contains a counting number. A photographer who opens the address of another photographer's
   gallery gets "not found" or is refused, and sees none of that gallery.
3. **Stored photos aren't public.** No photo file (original, web size or thumbnail) is reachable at
   a permanent public address. A photo address works only with the viewer's session, or with a
   signature that expires within one hour; without that session or signature it returns no image.
4. **No location data in served images.** Thumbnails and web sizes carry no GPS or other location
   metadata, even when the uploaded photo has it.
5. **Oversized images are handled.** The product accepts JPEG photos up to 50 MB and up to
   100 megapixels. It refuses larger files with a message that names the file and says it is
   "too large". The other photos in the same upload carry on, and the product stays responsive.
6. **PIN attempts are limited.** After 5 wrong PIN entries in a gallery, that visitor can't
   download from that gallery for 15 minutes, even with the right PIN, and sees a message saying
   "too many attempts". A new browser session or a different email does not lift the block.

## 5. Interface names

So that any build can be checked the same way, use these visible names. Matching ignores case.
A "button" may also be a link.

| Where | Element | Name |
| --- | --- | --- |
| Home page, logged out | buttons | "Sign up", "Log in" |
| Sign-up and log-in forms | fields; submit buttons | "Email", "Password"; "Sign up", "Log in" |
| Anywhere, logged in | button | "Log out" |
| Gallery list | button; field; submit | "New gallery"; "Gallery name"; "Create gallery" |
| Gallery list | each gallery | a link named with the gallery name |
| Gallery page | heading | the gallery name |
| Gallery page | file picker (several files) | "Upload photos" |
| Gallery page | button, next to each photo | "Set as cover" |
| Gallery page | fields; checkbox; button | "Gallery password", "Download PIN"; "Allow downloads"; "Save settings" |
| Gallery page | read-only text field with the full link | "Client link" |
| Gallery page | section heading | "Client activity" |
| Client, password step | field; button | "Password"; "Open gallery" |
| Client, email step | field; button | "Your email"; "Continue" |
| Client, viewer | dialog with buttons | "Previous", "Next", "Close" |
| Client, viewer | toggle button, pressed when favourited | "Favourite" |
| Client, viewer | button | "Download" |
| Client, gallery page | button | "Download all" |
| Client, PIN step | field; button | "Download PIN"; "Confirm" |

Every photo shown, to the photographer or the client, has its uploaded file name as its text
alternative. Messages use these words: a wrong password or PIN says "incorrect"; a bad or unknown
link says "not found"; the others are given in section 4.

## 6. Running it

- **Where to build.** Build the product in `/app` on the machine you're given. Grading copies only
  `/app` onto a fresh copy of that machine and runs `/app/start.sh` there as an ordinary user (not
  root) who owns `/app`. Anything installed or changed outside `/app` is lost, and while running
  the product can write only inside `/app` and the temporary folder.
- **Start command.** `/app/start.sh` is executable. Run with no arguments, it starts the whole
  product. Within 2 minutes the product serves everything on port
  3000, on all network interfaces, and keeps serving until stopped. Grading starts the product with
  this command, so nothing left running beforehand counts.
- **Self-contained.** The product runs on that one machine alone: no outside services, accounts or
  keys.
- **Address.** The product works fully over plain HTTP. Addresses it shows, such as the client
  link, use the address it was reached at.
- **Rate limits.** Other than the PIN limit, rate limits allow at least 200 sign-ups and log-ins per
  hour from one network address.

## 7. Out of scope

Watermarks, comments, branding themes, video, translations, Lightroom sync, print store and
payments, email campaigns.
