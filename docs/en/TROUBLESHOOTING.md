# Troubleshooting — Dumbhanengue ERP

A practical guide to solving the most common day-to-day app problems. To learn how to use the system, see the [User Guide](USER_GUIDE.md).

---

## How to use this guide

1. Find your symptom below (sign-in, sales, stock, photos...).
2. Follow the steps in order — always start with the simplest.
3. If the problem persists, check **Common error messages** and, finally, **When to contact support**.

> **Warning:** **Golden rule**: before anything else, check that your phone has **internet** and that the app is **up to date** (app store). Many "errors" are just a missing connection or an old version.

---

## 1. Sign-in and account problems

### "I can't sign in"
1. Double-check your **e-mail** (no spaces, correct) and **password**.
2. Tap **"Forgot password?"** if you don't remember — the link arrives by e-mail (also check **spam/junk**).
3. If you're a new user: the account must be **approved** (up to 24h). Pending approval = can't sign in.
4. Close the app completely and reopen it (sessions sometimes get stuck).

### "My account was deactivated"
- The **owner** can deactivate employees — if that's your case, access is blocked immediately.
- Talk to the store owner to be reactivated.

### "I typed the wrong e-mail when registering"
- There's no way to change the registration e-mail from the app: contact **support** with the correct e-mail and business name.

---

## 2. Product photo problems

### "The product photo doesn't show in the list"
1. The product may have been saved **without a photo** (the upload failed — e.g., no internet). Open the product → **Edit product** → tap the photo area → add it again.
2. Make sure the photo was actually selected (the preview shows before saving).

### "Nothing happens when I take/pick a photo"
1. The phone asks for **camera/storage permission** — accept it. If you declined earlier: **Phone settings → Apps → Dumbhanengue → Permissions** and enable Camera/Files.
2. Close and reopen the app and try again.

### "Product added! (photo not uploaded...)" appears
- The product was saved ✓ — only the photo didn't upload (no internet or temporary error).
- You can add the photo **later**, through product edit.
- If it always happens, even with internet, contact **support** (it may be a server configuration).

---

## 3. Sales problems

### "The sale won't confirm / 'Could not register the sale'"
1. Check your **internet**.
2. Make sure you filled in **all fields** (product, quantity, payment method).
3. Make sure the **quantity isn't zero** and the **total matches** the items.
4. If the sale is for a **deactivated** product, reactivate it (Products → Edit → **Active product**).

### "I sold by mistake / the customer didn't take it"
- Open the sale → **Cancel sale** (owner/manager only). Stock returns and the cash is reversed.
- **Employees don't see the Cancel button** — it's a managerial operation; ask the owner/manager.

### "Stock wasn't deducted / deducted too much"
1. Check the sale **details** to confirm the items are correct.
2. **Cancelled** sales return stock — if you cancelled, the stock comes back.
3. Check for **purchases** (increase stock) or **manual adjustments** in product edit.
4. If there's still a discrepancy, use the stock adjustment in product edit (owner/manager) to fix it.

### "The label scale can't find the product"
- Check the **barcode (PLU)** registered on the product (up to 5 digits, format `20PPPPPWWWWW`).
- Make sure the product is **active** and in the correct **active store**.

---

## 4. Product and stock problems

### "The product doesn't show in the list / checkout"
1. Pull down to **refresh** the list.
2. Make sure you're on the correct **active store** (Stores → Settings → Active store).
3. Check the product isn't **deactivated** (Products → Edit → Active product).

### "Stock is negative or wrong"
- The system won't let you sell more than exists — the "insufficient stock" error is the system protecting you.
- Fix discrepancies with the **manual stock adjustment** (product edit, owner/manager).

### "The expiry alert doesn't appear"
- The alert appears when the product has an **expiry date** set (registration or purchase with a lot).
- Products without an expiry date never trigger an alert.

---

## 5. Money and finances problems

### "The cash balance doesn't match"
1. Check for **pending** items (receive/pay) not yet confirmed — they only count once **Receive/Pay** is confirmed.
2. **Cancelled** sales generate a reversal — the pair (sale + reversal) closes at zero.
3. Purchases and expenses leave the cash — check for a forgotten expense.
4. Check the **active store** — each store has separate cash.

### "The cash closing shows surplus/shortage"
- The **expected in the drawer** only considers **physical cash** (card, M-Pesa, E-Mola, transfer don't count).
- **Surplus**: there may be extra cash (e.g., a customer paid more, or an under-registered payment).
- **Shortage**: check whether a cash payment wasn't registered or money was taken from the drawer.
- Typed it wrong? You can **redo the day's closing** — it updates without duplicating.

### "I can't close the cash / register a purchase"
- These are **managerial** operations (owner/manager). Employees don't have the button — ask the owner/manager.

### "The pending item doesn't enter the cash when received"
- When you confirm **Receive/Pay**, the transaction starts counting in the **realized cash**. If it doesn't, refresh the screen (pull down) and check the active store.

---

## 6. Connection and sync problems

### "Data looks old / doesn't update"
1. **Pull down** on lists to refresh.
2. Switch tabs and come back (the app reloads when entering the screen).
3. Check your phone's internet.

### "Can I use the app without internet?"
- In **online** mode (default), the app needs a connection to register sales, products, etc. Without internet, operations fail — try again when the connection returns.
- **Sign-in** also requires internet.

### "The app keeps 'loading' forever"
1. Check your internet (try opening another page/app).
2. Close and reopen the app.
3. If it's the **first launch** after an update, wait — it may be syncing.

---

## 7. App problems (freeze, white screen, slow)

### "The app freezes or closes by itself"
1. Close the app (swipe it out of recent apps) and reopen it.
2. **Restart your phone** if it persists.
3. Check your phone's **storage** (very full → slow app).
4. **Update the app** in the app store — old versions may have fixed bugs.

### "White screen / won't open"
1. Close and reopen the app.
2. Check your internet (the sign-in screen needs it).
3. If it persists, **uninstall and reinstall** — your data stays on the server and returns when you sign in. Warning: Uninstalling **doesn't delete** your business data (it's in the cloud), but make sure you know your e-mail/password first.

### "The app suddenly changed language / currency"
- **Currency** and **language** are set by the owner in **Stores → Settings** and apply to the **whole business**, instantly. If it changed suddenly, a setting was changed (or on another device with the same owner account) — just go back to **Stores → Settings** and choose again.

---

## 8. Common error messages

> The messages below are **approximate** — the exact wording may vary slightly by app version. Look for the main idea.

| Message you see (e.g.) | What it means | What to do |
|-----------------|---------------|------------|
| **"Could not sign in. Check your credentials."** | Wrong e-mail or password | Recover the password ("Forgot password?") or check the e-mail |
| **"Access pending approval"** | Account not yet approved | Wait for approval (up to 24h) or contact support |
| **"Could not add the product. Try again."** | Error saving the product | Check internet, required fields, and try again |
| **"Product added! (photo not uploaded...)"** | Product saved, but the photo didn't upload | Add the photo later through product edit |
| **"Insufficient stock"** | Not enough stock for the quantity | Reduce the quantity, buy more, or adjust stock |
| **"The sale total doesn't match the items"** | Sum of items ≠ total | Review items and total before confirming |
| **"Could not cancel the sale. Try again."** | Error cancelling | Check internet and that the sale is still active (not cancelled) |
| **"Only the owner or a manager can..."** | Operation restricted to owner/manager | Ask the owner/manager to do it |
| **"Could not share the receipt"** | Error sharing | Check you have sharing apps (WhatsApp) installed |
| **"Could not export the report"** | Error generating the CSV/PDF | Try again; if it persists, contact support |
| **"Session expired / sign in again"** | Old session ended | Sign in again |

---

## 9. When to contact support

Contact support when:

- The error message **persists** after trying the steps above.
- The error involves **money** (cash, closing, sales) and the difference can't be explained.
- You suspect **wrong data on the server** (e.g., a sale that doesn't appear on another device).
- The app shows a **new** error or **strange behaviour** after an update.

**To help support, have ready:**
1. The **exact message** on the screen (or a screenshot).
2. What you were doing when the error happened (e.g., "registering a 3-item sale").
3. Your **phone/model** and the **app version** (Phone settings → Apps → Dumbhanengue).
4. The **store** and the approximate **time** of the problem.

---

*Based on the User Guide — to learn how to use the app, see the [User Guide](USER_GUIDE.md).*
