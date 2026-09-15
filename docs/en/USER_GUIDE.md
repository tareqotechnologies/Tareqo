# User Guide — TAREQO ERP

A simple and complete guide to using your day-to-day management system: stock, sales, customers, money and reports — all in one place.

> **Need to fix something?** Check the [Troubleshooting guide](TROUBLESHOOTING.md).

---

## 1. Signing in

1. Open the **TAREQO** app on your phone.
2. Type your **e-mail** and **password**.
3. Tap **Sign in**.

> **First time?** Tap **Sign up**, fill in your details (name, e-mail, password, business name) and wait for your access to be **approved** — usually within 24h. You can only sign in after approval.

> **Forgot your password?** Tap **"Forgot password?"** on the sign-in screen and follow the link sent to your e-mail.

### Two-Factor Authentication (2FA)

If two-step verification is enabled for your account, after typing your password the app asks for the **code from your authenticator app** (e.g., Google Authenticator). Type the 6-digit code to sign in.

- To enable or manage 2FA: **Menu → Security → Two-Factor Authentication**. Keep the backup key shown during setup — it lets you sign in if you lose your phone.
- In SaaS mode, the owner can **require** 2FA for money operations: **Stores → Settings**.

---

## 2. Home screen (Home)

The home screen shows your business summary **for the active store**, with a **period pill** at the top (**Today** by default — tap for Week, Month or All) and the **active store** switcher:

- **Sales** of the period (with a % comparison against the previous period)
- **Cash** of the period
- **To receive (credit)** — with a count of owing customers
- **Today's activity**: sales, stock intake, credit payments, expenses and alerts — tap an event to see the details.

### Expiry alerts

- **Yellow** = product is **about to expire** (less than 30 days of shelf life).
- **Red** = product **has already expired** and still has stock.
- Tap the alert to see which product and lot are involved.

### Quick actions

The **+** button (corner of the screen) opens the action menu: **New sale**, **Add expense**, **Add product**, **Add customer** and **Register credit**.

### Navigation

The bottom bar has 4 tabs: **Home**, **Sales**, **Wallet** and **Menu**. On wide screens (tablet/desktop) navigation becomes a side rail. The **Products**, **Credit** and **Customers** modules live inside **Menu** (the tab stays highlighted when you open them). Purchases and Reports open from the Menu — **owner/manager** only.

---

## 3. Stores — which store am I viewing?

The system can have **multiple stores** (e.g., Central Store, Neighbourhood Store). Each store has its **own stock, sales and cash**.

- **Quick switch:** tap the **pill with the store name** at the top of Home (and on the app bars of Products, Sales, Wallet and Customers) and pick the store — everything shows that store's data instantly.
- You can also switch in **Menu → Stores → Settings tab → "Active store"** section.

> With a single store, the switcher doesn't appear — there is nothing to choose.

---

## 4. Products

### Adding a product

1. Open **Menu → Products** → tap **New product**.
2. Fill in the **name** and, if you want, the **description**.
3. Enter the **purchase price** and the **sale price**.
4. **Stock quantity**: enter how many units you have (e.g., `50`).
5. **Photo (optional)**: tap the photo area to **take a picture** or **pick from gallery**. The photo shows in the product list and helps at checkout.
6. **Expiry date (optional)**: tap **Set expiry date** and pick the due date. The system warns you when it's about to expire.
7. **Sold by weight?** Turn on **"Sold by weight (fraction)"** for products sold per kilo/litre (e.g., bulk rice, bulk oil) and choose the unit (kg, g, l, ml). Checkout then accepts quantities like `1.75 kg`.
8. **Code/PLU**: optional — used by label scales (up to 5 digits) and the barcode reader.
9. Tap **Add product**.

### Editing / deactivating a product

- Tap a product in the list → **Edit product**.
- You can change the name, prices, stock (**manual adjustment**), photo, expiry date and the **Active product** status.
- **Deactivate** (`Active product` off): the product disappears from checkout and purchases but **stays in history** with its stock kept — you can reactivate it later.
- To remove the photo, tap **Remove photo**.

> **Warning:** If the photo can't upload (e.g., no internet), the product is still saved — you'll see a notice and can add the photo later through Edit.

> **Filters:** at the top of the product list, the filter icon opens search by name, status, stock type, availability and price range.

---

## 5. Sales (Checkout)

1. Tap **New sale** (**Sales** tab or the **+** menu).
2. Search for the product or **scan the barcode** (camera or label scale).
3. Adjust the **quantity** (weight products accept decimals: `1.75`).
4. Choose the **payment method**: Cash, Debit card, Credit card, M-Pesa, E-Mola or Bank transfer.
5. Tap **Confirm sale**.

> ✓ Stock is deducted automatically — **oldest lot first** (FIFO), so nothing expires sitting on the shelf.

### Receipt and sharing

- Tap a sale in the list to see its **details** (items, total, payment method).
- **Share receipt**: generate the sale receipt and share it via **WhatsApp** or another app (you can also share it as an **image**).

### Cancelling a sale (owner/manager only)

If a sale was made by mistake:

1. Open the sale **details** → **Cancel sale** → confirm.
2. Stock **returns to the exact lots** that were sold (expiry and cost preserved) and the cash is **reversed**.
3. The sale **stays in history** marked as "Cancelled" (for auditing), but **leaves reports, KPIs and the day summary**.

> In SaaS mode with MFA required, confirming a sale (and other money operations) may ask for the **authenticator code** — that's the server protecting your cash.

---

## 6. Purchases (stock intake) — owner/manager

1. Open **Menu → Purchases** → tap **New purchase**.
2. Enter the **supplier**.
3. Add the purchased products and quantities.
4. **Expiry (optional)**: for perishable products, choose the lot date.
5. Confirm the purchase. Stock increases immediately and the expense leaves the cash.

---

## 7. Customers and Credit

- **Customers**: register your customers with name, phone and e-mail (**Menu → Customers**).
- **Register credit**: when a customer takes goods to pay later, register the amount and due date (**+** menu → **Register credit**).
- On the **Wallet → Credit** tab you see:
  - **Pending** = who still owes (total to receive).
  - **Settled** = history of who already paid.
- When the customer pays, tap **Settle debt** — the money **enters the cash automatically**.

---

## 8. Finances (Wallet)

The **Wallet** tab shows money movements: **income**, **expenses** and the **balance**.

- **Add transaction**: from the **+** → **Add expense** (or from the tab itself, for income).
- **Pending**: leave it checked if the amount hasn't been received/paid yet — it only counts in the **realized cash** once received/paid.
- On pending items:
  - **Receive** (pending income): confirms the money came in → it starts counting in the cash.
  - **Pay** (pending expenses — bills to pay): confirms the payment → it starts counting in the cash.

### Daily cash closing (Z-report) — owner/manager

In the **Wallet**, tap the **Cash closing** card (or the action at the top):

1. The app shows the **day summary**: total sales, the **expected in the drawer** (cash only — card, M-Pesa, E-Mola and transfer don't go through the physical drawer) and the breakdown **by payment method**.
2. **Count the physical cash** in the drawer and enter it in **Counted cash**.
3. The app shows the **difference** live: **Cash matches**, **Surplus** or **Shortage**.
4. Tap **Confirm closing**.

> Typed it wrong? You can **redo the day's closing** — the value is updated, no duplicates. After closing, the **"Cash closed!"** badge appears in the Wallet.

---

## 9. Reports — owner/manager

Open **Menu → Reports** and see your business performance:

- **Revenue** (how much you sold in the period)
- **Gross profit** and **margin**
- **Best sellers** (the products that sell the most)
- **Sales per day**

Use the filters: **Today**, **7 days**, **This month**, **All**.

### Exporting and sharing

Tap **Export** → choose **Export CSV** or **Export PDF**. The report is generated and you can **share** it via WhatsApp, e-mail or save it on your phone.

---

## 10. Stores and Employees (owner)

Open **Menu → Stores** — there are 4 tabs:

- **Stores**: register your stores. Each store has its own stock and cash.
- **Employees**: create accounts for the people who work with you and choose the role:
  - **Manager**: operates everything, except store/employee management.
  - **Employee**: sells only (can't add products, see reports, make purchases, close the cash or cancel sales).
  - Deactivate an employee any time — they **lose access immediately**.
- **Upgrades**: view and request a plan change.
- **Settings**: change the **Active store**, the **currency** (MZN, BRL, USD, EUR), the **language** (Portuguese/English/French) and **Require MFA for money operations** (SaaS mode).

---

## 11. Security (all accounts)

In **Menu → Security** you'll find:

- **Two-Factor Authentication**: enable/manage the second factor (authenticator app). With 2FA on, signing in and confirming money operations asks for the 6-digit code.
- **Change password**: change your password (asks for the current one to confirm).
- **Biometric Authentication**: unlock the app with fingerprint/face (if the device supports it).

---

## 12. Add-ons (owner)

**Menu → Add-ons** shows the extras active on your plan (managed by the administrator):

- **Custom Invoice**: create invoices with your brand layout (logo, colours), per-store automatic numbering and **WhatsApp** sending.
- **Quotations**: create quotations with a custom template and track status — **draft → sent → accepted/rejected**. Exports to PDF.
- **Advanced Reports**: financial KPIs, products by stock, cash flow and low stock.
- **Employee Management**: attendance log (clock-in/out), **commissions calculated on real sales** per seller and monthly targets with progress.
- **Store Transfers**: move stock between stores of your business — deducted at origin, added at destination, with a traceable history.

---

## 13. Offline sync (SaaS mode)

If the internet drops during a sale, purchase, credit, settlement or cancellation:

1. The operation is **safely stored on the device** (the app warns "saved offline").
2. As soon as the connection returns, the app **re-sends everything automatically** — no duplicates.
3. The **banner on Home** shows how many operations are pending; tap **Sync** to re-send right away.

> Pending operations may also ask for the **2FA code** while syncing, if MFA is required.

---

## 14. Quick tips

- Always double-check the **total** before confirming a sale.
- Warning: Check the **expiry alerts** every week — expired product is lost money.
- Products with a **photo** are much easier to identify at checkout.
- The app keeps your session secure — you only sign in once (and can use biometrics to unlock).
- Need a connection to sell? In online mode yes — but if the connection drops, the sale **isn't lost**: it goes to the offline queue (section 13) and uploads by itself.

---

## 15. Frequently asked questions (FAQ)

**I forgot my password.**
Tap **"Forgot password?"** on the sign-in screen and follow the link sent by e-mail.

**I registered but can't sign in.**
Your access needs to be **approved** by the administrator (up to 24h). Also double-check your e-mail/password. If more than 24h have passed, contact support.

**It asked for a 6-digit code after my password.**
That's **Two-Factor Authentication**. Open your authenticator app and type the current code. Lost your phone? Use the backup key you saved when enabling 2FA.

**Can a deactivated employee still sign in?**
Not for long: access is **revoked instantly** when the owner deactivates them. If an old session is still open, close and reopen the app.

**I sold by mistake. How do I undo it?**
Open the sale → **Cancel sale** (owner/manager only). Stock returns to the exact lots and the cash is reversed. The sale stays in history marked as **Cancelled**.

**My stock doesn't match what I counted.**
Check for un-cancelled sales, purchases, or manual stock adjustments made in product edit. For a small discrepancy, use the **stock adjustment** in product edit (owner/manager).

**A product photo doesn't show up.**
The photo may have failed to upload due to lack of internet at the time (the product is still saved). Open the product → **Edit product** → add the photo again. If it persists, see the [Troubleshooting guide](TROUBLESHOOTING.md).

**The cash closing shows a "shortage".**
The "expected in the drawer" only considers **cash sales** — card, M-Pesa, E-Mola and transfers don't count. Check whether any cash payment wasn't registered or money was taken from the drawer.

**Can I have more than one store?**
Yes — the number of stores depends on your **plan** (see **Menu → Stores → Upgrades**). Each store has separate stock, sales and cash.

**Do cancelled sales count in reports?**
No. Cancelled sales stay in history (auditing), but **leave** revenue, KPIs and the day summary.

**Can I export reports?**
Yes — **Export CSV** or **Export PDF** on the Reports screen, and share via WhatsApp, e-mail, etc.

**What are Add-ons and how do I activate one?**
Add-ons are extras of your plan (custom invoice, quotations, advanced reports, employee management, transfers). They are **activated by the administrator** — to request one, use **Menu → Stores → Upgrades**. Once active, they appear in **Menu → Add-ons**.

**The app suddenly changed language/currency?**
Currency and language are set by the owner in **Menu → Stores → Settings** and apply to the whole business, instantly. If they changed, a setting was changed — you can change it back there.

**How is the employee commission calculated?**
From their **real sales** (sales registered with the employee's account active), using the rate set by the owner in **Menu → Add-ons → Employee Management** (500 points = 5%).

---

*Questions not answered here? See the [Troubleshooting guide](TROUBLESHOOTING.md) or talk to the store owner / support.*
