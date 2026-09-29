<!-- gf-brief source=5863f8d0cec1c94980f516b1373e917888695973e9ab3ff855b974ab136a792b written=2026-09-29T18:17:04+03:00 -->
# Periplus

## What it is

Periplus is a one-book reading log. You put a book on the shelf, open a voyage with a finish day, and log the pages you read so a single route line advances toward that day. It is for readers who want schedule slip shown as a curl off the true bearing, not a percentage bar or a shelf of genres.

## Launch and onboarding

Cold launch is a dark system launch screen. There is no wordmark on that screen.

On a physical device, or on the Simulator after a reset that cleared the introduction flag, the first screen is the introduction. A page-dot strip sits under three swipeable pages. **Skip** is always at the top trailing corner and ends the introduction on any page.

1. Headline: **A route for one volume.** Body: **Periplus keeps a cyanotype line toward the day you mean to finish the book.** Bottom button: **Next**.
2. Headline: **Log the pages you read today.** Body: **Each log advances the route. A day with no log curls the line off the true bearing.** Bottom button: **Next**.
3. Headline: **Set when the curl reaches its cap.** Body: **Set moves landfall forward so the drift returns to zero, and the next log is allowed.** Bottom button: **Continue**.

**Skip** and **Continue** both go to the map. The introduction does not ask for a name, account, or permission.

On the Simulator only, the first run can skip the introduction and open the map already filled with the starter voyage described under Starter content. A physical device does not get that starter voyage.

Later launches open the map with the last saved shelf, voyage, legs, and curl. The introduction does not return unless the reader chose **Replay introduction**.

## Screens

There is no tab bar. The map stays on screen. **Catalogue**, **Voyage**, **Stats**, and **Settings** arrive as sheets you swipe down to close.

### Map

Navigation title is the open book's title, or **Log pages** when no book is on a voyage.

Toolbar, left to right (icon-only; spoken names): **Catalogue**, **Voyage**, **Stats**, **Settings**. Each opens the matching sheet.

**Empty (no voyage ever opened)**

- Art, then **No voyage yet. Open a book.**
- **The route appears after you choose a book and a finish day.**
- **Open a book** opens Catalogue.

**Voyage underway**

- **Log pages on this voyage.**
- When logging is allowed: **Log today's pages. Idle days curl this line off the true bearing.**
- When the curl is at the cap: **The route has curled to the cap. Set pushes the finish day forward, then you can log again.**
- A wide route plate labeled **True bearing** (spoken: **Route on this voyage**). A faint straight line is the bearing. A thicker line is the route and rotates off that bearing as curl grows. Dots appear on the line at each quartile the voyage has crossed.
- **Today's pages**, default **1**. **Fewer pages** steps down, not below 1. **More pages** steps up.
- Primary button **Log 1 pages** (the number matches today's pages). While the save is in flight the label is **Logging** and the button will not take a second tap. A successful log flashes a brief confirmation mark, then today's pages return to **1**.
- When the curl is at forty-five degrees, **Log** is replaced by **The curl has reached forty five degrees. Set the finish day before the next log.** and **Set finish day**. That control moves the finish day forward until the curl is zero, then **Log** returns.
- **Curl** with the angle in degrees (one decimal, device locale).
- **Along the route** with pages logged so far, then **of {total} pages**.
- Dock: **No legs are on this route yet.** after a new voyage, or **{n} legs are logged. Today holds {n} pages, and the latest leg is {n} pages on {abbreviated date}.** Same-day logs add to today's total and grow the leg count.
- If the last save could not be read: **The last file could not be read, so this route started empty.**

**Voyage landed**

- **Log pages on this voyage.**
- **The route has arrived and the curl is clear.**
- **This book has landed. Open another from the catalogue when you are ready.**
- **Open a book** opens Catalogue.
- Curl, along-the-route figures, and the dock stay visible.

Refusals that can appear on this screen:

- **Enter the pages you read today as a whole number.**
- **Open a voyage before you log a leg.**
- **The curl has reached forty five degrees. Set the finish day before the next log.**
- **Set is refused while the curl is already zero.**
- **Enter a page count greater than zero.**
- **That count runs past the end of the book.**
- **The book for this route is missing.**
- **Set needs some pages already logged before it can move the finish day.**
- **This voyage has already landed.**

### Catalogue

Title: **Catalogue**.

**Empty shelf** (no saved book, search blank, not entering by hand)

- **The shelf is empty.**
- **Search a title or scan an ISBN to put a book on this device.**
- Field **Search a title**.
- **Scan ISBN** opens the ISBN sheet.
- **Enter a book** shows the manual form on this sheet.

**Filled shelf or any search / manual entry**

- **Search a title**. Typing filters books already on the device at once. A non-empty query also searches **Open Library**. A blank query does not search the network.
- **Scan ISBN** and **Enter a book**.
- Spinner **Searching Open Library** if the search is still running.
- Search failures, with **Try the search again**:
  - **Open Library did not answer. You can still save a volume by hand.**
  - **That ISBN is not in Open Library. Enter the volume yourself.**
  - **The catalogue reply could not be read. Enter the volume yourself.**
  - **The search was cancelled.**
- Section **Open Library**: each hit shows title, author or **Author unknown**, and **Save**. **Save** puts the book on the device when a page count is present. If the page count is missing, the manual form opens with **Open Library did not include a page count. Add the total, then save.**
- Section **On this device**: each saved row is title plus **{author}, {n} pages** (or **Author unknown**). Rows are not buttons. They do not open a voyage.
- If the search matches no saved book: **No saved book matches that search. The shelf still filters without a network.**
- After a save: **Saved {title} on this device.**
- If title or pages are missing: **A volume needs a title and a page count.**
- Saving the same ISBN again updates that book instead of adding a second row.

**Manual form**

- **Save the book on this device. Page count is required.**
- Fields: **Title**, **Author**, **ISBN**, **Total pages**.
- **Save book** is dimmed until Title is non-empty and Total pages is a whole number of at least 1. A bad page count shows **Enter the total pages as a whole number.**

### ISBN

Title: **ISBN**. **Close** dismisses without saving.

- **Point the camera at the ISBN barcode, or type the digits.**
- Before the system camera ask: **The next step asks the system for the camera.** then **Continue**. **Continue** is the only control that leads to the system camera alert. The alert is the only place that says Allow.
- After access is granted, a live finder with a rectangular frame. Point it at an ISBN barcode. A code of 8 to 14 digits is taken and the sheet closes. A 12-digit retail code is treated as an ISBN by adding a leading 0. A QR code is accepted only when it contains an 8-to-14-digit run.
- If the camera was refused or is off: **The camera is off. You can still type the ISBN, or open Settings to change camera access.** and **Open Settings**.
- Field **ISBN digits**. Keyboard **Done**.
- **Use these digits** is dimmed until at least 8 digits are present. If the run is not 8 to 14 digits: **Enter 8 to 14 digits from the ISBN.**
- On the Simulator only: **Simulator samples**, **Use 9780141439518**, **Use 9780000000002**. These buttons are not on a physical device.

A captured or typed code returns to Catalogue and looks the book up. A miss opens the manual form.

### Voyage

Title: **Open a voyage** when nothing is underway or landed. Once a voyage exists, the title is that book's name.

**No book on the shelf**

- **No book is on the shelf yet.**
- **Add a book in the catalogue, then choose the day you mean to finish it.**
- **Open the catalogue** replaces this sheet with Catalogue.

**Moored (books saved, no open voyage)**

- **Pick a book and the day you intend to finish it. That day is the finish day.**
- **Book**, then a **Volume** menu of saved titles.
- **Finish day**, a date that cannot be today or earlier. The first value offered is twenty-one days from now.
- **Open voyage**. Success: **The expedition is open from today.** The sheet stays; **Log pages** then appears and closes the sheet back to the map.
- Failures can show the error page **The voyage could not be opened.** / **Check the finish day and try again.** / **Try again**, or an inline line:
  - **Choose a volume first.**
  - **A voyage is already underway.**
  - **The finish day has to fall on a later day than today.**
  - **The book for this route is missing.**
  - **This voyage has already landed.**

**Underway**

- **This book's route.**
- **Opened {date}. Finish day {date}. {n} of {n} pages are on the line.**
- The same route plate as the map.
- **Log pages** closes the sheet so you can log on the map.
- **Finish the book** logs every remaining page in one step. Success: **The remaining pages are on the route.** It is dimmed when no pages remain, or when the curl is at the cap.

**Landed**

- **The last voyage has landed. You can open the next book.**
- The finished title, then the same **Book** / **Volume** / **Finish day** / **Open voyage** controls as when moored.

Only one voyage can be open. A new voyage is allowed after the current one has landed, or after the route is deleted.

### Stats

Title: **Stats**.

**Empty** (no legs, no landfalls, no set marks)

- **No landfalls yet.**
- **Legs, buoys, and set marks collect here after you log the route.**
- **Back to the route** closes the sheet.

**Filled**

- Hero **Landfalls** and the count.
- **Legs** count and **Set marks** count.
- If a prior save was recovered: **A backup of the route was restored.**
- List **Legs**: each row is an abbreviated date and **{n} pages**, newest first. Same-day logs are separate rows.
- List **Buoys** when any exist: **Quartile 25**, **Quartile 50**, **Quartile 75** as each mark is crossed (one quarter, one half, three quarters of the book).
- List **Recalibrations** when any exist: **On {date}, the finish day moved from {date} to {date}.**

Error page: **The history could not be counted.** and **Try again**.

### Settings

Title: **Settings**.

**Nothing stored**

- **Nothing is stored yet.**
- **You can still replay the introduction or write to the contact page.** (or the delete confirmation line if the reader just wiped the route).
- The same three controls as below.

**Route on the device**

- **The route named {book title} stays on this device.** If no title exists, the name is **the open route**.
- If the last save failed: **The last save did not reach disk.** and **Save again**.

**Controls on both states**

- **Replay introduction** leaves Settings and shows the three introduction pages again. Saved books and the voyage stay. **Skip** or **Continue** returns to the map.
- **Delete the route** opens **Delete {book title}?** (or **Delete the open route?**). Body: **Legs, buoys, set marks, and landfalls for this route leave this device.** **Delete the route** wipes the shelf and voyage. **Keep the route** cancels. After a wipe: **{name} was removed from this device.** The map then shows **No voyage yet. Open a book.**
- **Contact** (spoken: **Contact Periplus**) opens the support page.

Error page: **The route could not be written to disk.** and **Try again**.

## Features

- One cyanotype route on the map for the open voyage.
- Catalogue of books on this device.
- Title search, including **Open Library** results.
- ISBN scan or typed ISBN digits.
- Manual **Enter a book** / **Save book** when a lookup misses or omits pages.
- Open a voyage with a **Finish day**.
- **Log** today's pages as a leg.
- Same-day legs stack; today's total is shown on the map dock.
- Idle days curl the route off **True bearing**. **Curl** is shown in degrees, capped at forty-five.
- **Set finish day** when the curl is at the cap, which moves the finish day and clears the curl.
- Buoys at quartile crossings, listed in Stats.
- Landfall when the last page is logged and the curl is already zero.
- **Finish the book** logs the remaining pages in one tap.
- Stats for **Landfalls**, **Legs**, **Set marks**, **Buoys**, and **Recalibrations**.
- **Replay introduction**.
- Confirmed **Delete the route**.
- **Contact**.

## Behaviours that can look like bugs

- **Open a book** / empty map **No voyage yet. Open a book.** The route does not appear until a book is saved and **Open voyage** has run.
- **Open the catalogue** on Voyage when the shelf is empty. Add a book first.
- **Save book** stays dim until **Title** is filled and **Total pages** is at least 1.
- **Use these digits** stays dim until 8 digits are entered.
- **Search a title** with a blank field never queries **Open Library**. Type something, or use **Scan ISBN** / **Enter a book**.
- A failed or empty lookup opens the manual form on purpose. Fill **Total pages** and tap **Save book**.
- Catalogue rows do not start a voyage. Open **Voyage**, pick the **Volume**, set **Finish day**, tap **Open voyage**.
- **Open voyage** will not accept today or an earlier **Finish day**. Choose a later day. Default is twenty-one days ahead.
- Only one voyage at a time. **A voyage is already underway.** Wait until the book has landed, or **Delete the route**.
- **Fewer pages** will not go below 1. **Log {n} pages** stays dim if the page count is not a positive whole number.
- **Log** is refused at forty-five degrees of curl. Tap **Set finish day**, then log. The same refusal text appears as a caption.
- **Set finish day** is refused while curl is already zero: **Set is refused while the curl is already zero.**
- **Set finish day** with no pages logged yet: **Set needs some pages already logged before it can move the finish day.** If the reader opened a voyage, logged nothing, and waited until the curl hit the cap, both **Log** and **Set finish day** refuse. The way out is **Settings** → **Delete the route**, then open a new voyage and log before the curl caps.
- **That count runs past the end of the book.** Lower today's pages so they fit the remaining pages, or use **Finish the book**.
- **Finish the book** is dim when no pages remain, or when the curl is at the cap. Use **Set finish day** first if the curl is at the cap.
- Logging the last pages while curl is still above zero does not land the voyage. **Log** then fails with **That count runs past the end of the book.** and **Finish the book** stays dim. Wait until curl reaches forty-five degrees, tap **Set finish day** (which can land the book once curl is cleared), or **Delete the route**.
- Same-day **Log** taps add more legs; Stats grows. That is intended. Today's dock total is the sum.
- **Replay introduction** is a loop back to the three pages on purpose. **Skip** or **Continue** returns to the map with data intact.
- **Delete the route** asks first. **Keep the route** leaves everything as it was.
- **Logging** ignores a second tap until the first log finishes.
- Stats **No landfalls yet.** until the first leg, landfall, or set mark exists, even if a voyage is already open.
- **The expedition is open from today.** does not close Voyage by itself. Tap **Log pages** or swipe the sheet down.
- Camera: **Continue** only starts the system ask. If the reader declines, the finder never appears. Type the ISBN or tap **Open Settings**, grant camera there, return, and tap **Continue** again.
- Simulator **Simulator samples** buttons are missing on a device. Use the camera or **ISBN digits**.

## Starter content and resume

On the Simulator only, the first run can open already underway on **Northwater Atlas** by **I. Marlow**, 200 pages, ISBN **9780000000002**, with four legs (20, 20, 15, and 15 pages), one quartile buoy, pages already along the route, and curl below forty-five degrees so **Log** is enabled. Finish day is twenty days after the voyage was opened, and the opening day is ten days before today. A physical device has no starter book.

Unfinished work resumes. Relaunch returns to the map with the same shelf, voyage, legs, buoys, curl, and finish day. Today's pages stepper itself starts at **1** again. Force-quitting after a log, save, or set keeps that work.

## Permissions

Camera, only after **Continue** on the ISBN sheet, and only if the reader uses the finder instead of typing digits.

Usage string: **Periplus uses the camera to read the ISBN barcode printed on a book so that volume can be added to the catalogue on this device.**

No other permission is asked.

## Absent

Genuinely absent: login or accounts, in-app purchase, ads, analytics, user-generated content shared with other people, an account deletion flow, and an App Tracking Transparency prompt.

## Data and support

Books, voyages, legs, buoys, set marks, and landfalls stay on this device. Title and ISBN lookup can use **Open Library**; a saved book remains available when the network does not. Settings says **The route named {title} stays on this device.**

On-screen support control: **Contact** (spoken **Contact Periplus**). It opens the support page.

## Scanning and health

The ISBN sheet reads ISBN barcodes. It also accepts a QR code when that code contains an 8-to-14-digit run, and it accepts typed digits in that same length. It is looking for the printed ISBN, not a store QR campaign or a boarding pass.

No health, medical, or product-health information. Citations: none.

## Platform

The interface is English. Dates and page counts follow the device locale and calendar. There is no region switch and no country lock in the app.

Portrait only, on iPhone and iPad. Dark appearance only. Minimum iOS version: 17.0.

## Category

Books
