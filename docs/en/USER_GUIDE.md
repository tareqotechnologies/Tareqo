# User Guide — Dumbhanengue ERP

A simple and complete guide to using your day-to-day management system: stock, sales, customers, money and reports — all in one place.

> **Need to fix something?** Check the [Troubleshooting guide](TROUBLESHOOTING.md).

---

## 1. Signing in

1. Open the **Dumbhanengue** app on your phone.
2. Type your **e-mail** and **password**.
3. Tap **Sign in**.

> **First time?** Tap **"No account yet — register"**, fill in your details (name, e-mail, password, business name) and wait for your access to be **approved** — usually within 24h. You can only sign in after approval.

---

## 2. Home screen (Home)

The home screen shows your business summary **for the active store**:

- **Total sales** of the day
- **Cash balance**
- **To receive (credit)**
- **Stock value**
- **Alerts** Warning: (expiry) — see below

### Expiry alerts
- ◔ **Yellow** = product is **about to expire** (less than 30 days of shelf life).
- ● **Red** = product **has already expired** and still has stock.
- Tap the alert to see which product and lot are involved.

### Quick actions
The main buttons live on the home screen: **New sale**, **Add product**, **Add transaction** and **Register credit**.

### Modules
Use the bottom bar (or the cards) to navigate: **Home**, **Sales**, **Products**, **Finances**, **Credit**, **Customers**, **Stores**, **Reports**. Some modules only appear for **owner/manager** (e.g., Purchases and Reports).

---

## 3. Stores — which store am I viewing?

The system can have **multiple stores** (e.g., Central Store, Neighbourhood Store). Each store has its **own stock, sales and cash**.

- **Home** shows the name of the active store.
- To switch: **Stores** → **Settings** tab → **"Active store"** section → tap the desired store.
- Everything (stock, sales, finances, reports) now shows data for the selected store.

> With a single store, this section doesn't appear — there is nothing to choose.

---

## 4. Products

### Adding a product
1. Open **Products** → tap **New product**.
2. Fill in the **name** and, if you want, the **description**.
3. Enter the **purchase price** and the **sale price**.
4. **Stock quantity**: enter how many units you have (e.g., `50`).
5. **Photo (optional)**: tap the photo area to **take a picture** or **pick from gallery**. The photo shows in the product list and helps at checkout.
6. **Expiry date (optional)**: tap **Set expiry date** and pick the due date. The system warns you when it's about to expire.
7. **Sold by weight?** Turn on **"Sold by weight (fraction)"** for products sold per kilo/litre (e.g., bulk rice, bulk oil) and choose the unit (kg, g, l, ml). Checkout then accepts quantities like `1.75 kg`.
8. **Barcode (PLU)**: optional — used by label scales (format `20PPPPPWWWWW`).
9. Tap **Add product**.

### Editing / deactivating a product
- Tap a product in the list → **Edit product**.
- You can change the name, prices, stock (**manual adjustment**), photo, expiry date and the **Active product** status.
- **Deactivate** (`Active product` off): the product disappears from checkout and purchases but **stays in history** with its stock kept — you can reactivate it later.
- To remove the photo, tap **Remove photo**.

> **Warning:** If the photo can't upload (e.g., no internet), the product is still saved — you'll see a notice and can add the photo later through Edit.

---

## 5. Sales (Checkout)

1. Tap **New sale**.
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

---

## 6. Purchases (stock intake) — owner/manager

1. Tap **New purchase**.
2. Enter the **supplier**.
3. Add the purchased products and quantities.
4. **Expiry (optional)**: for perishable products, choose the lot date.
5. Confirm the purchase. Stock increases immediately and the expense leaves the cash.

---

## 7. Customers and Credit

- **Customers**: register your customers with name, phone and e-mail.
- **Register credit**: when a customer takes goods to pay later, register the amount and due date.
- On the **Credit** screen you see:
 - **Pending** = who still owes (total to receive).
 - **Settled** = history of who already paid.
- When the customer pays, tap **Settle debt** — the money **enters the cash automatically**.

---

## 8. Finances

- **Add transaction**: income (money in) and expenses (bills, costs).
- **Pending**: leave it checked if the amount hasn't been received/paid yet — it only counts in the **realized cash** once received/paid.
- The screen shows **income**, **expenses** and the **balance**.
- On pending items:
 - **Receive** (pending income): confirms the money came in → it starts counting in the cash.
 - **Pay** (pending expenses — bills to pay): confirms the payment → it starts counting in the cash.

### Daily cash closing (Z-report) — owner/manager
In **Finances**, tap the **Cash closing** card (or the action at the top):

1. The app shows the **day summary**: total sales, the **expected in the drawer** (cash only — card, M-Pesa, E-Mola and transfer don't go through the physical drawer) and the breakdown **by payment method**.
2. **Count the physical cash** in the drawer and enter it in **Counted cash**.
3. The app shows the **difference** live: **Cash matches**, **Surplus** or **Shortage**.
4. Tap **Confirm closing**.

> Typed it wrong? You can **redo the day's closing** — the value is updated, no duplicates. After closing, the **"Cash closed!"** badge appears in Finances.

---

## 9. Reports — owner/manager

See your business performance:

- **Revenue** (how much you sold in the period)
- **Gross profit** and **margin**
- **Best sellers** (the products that sell the most)
- **Sales per day**

Use the filters: **Today**, **7 days**, **This month**, **All**.

### Exporting and sharing
Tap **Export** → choose **Export CSV** or **Export PDF**. The report is generated and you can **share** it via WhatsApp, e-mail or save it on your phone.

---

## 10. Stores and Employees (owner/manager)

Open **Stores** (card on Home) — there are 4 tabs:

- **Stores**: register your stores. Each store has its own stock and cash.
- **Employees**: create accounts for the people who work with you and choose the role:
 - **Manager**: operates everything, except store/employee management.
 - **Employee**: sells only (can't add products, see reports, make purchases, close the cash or cancel sales).
 - Deactivate an employee any time — they **lose access immediately**.
- **Upgrades**: view and request a plan change.
- **Settings**: change the **Active store**, the **currency** (MZN, BRL, USD, EUR) and the **language** (Portuguese/English).

---

## 11. Quick tips

- Always double-check the **total** before confirming a sale.
- Warning: Check the **expiry alerts** every week — expired product is lost money.
- On any list (sales, products, customers...) **pull down to refresh**.
- Products with a **photo** are much easier to identify at checkout.
- The app keeps your session secure — you only sign in once.
- Need a connection to sell? **Yes** (online mode) — sales are registered instantly.

---

## 12. Frequently asked questions (FAQ)

**I forgot my password.**
Tap **"Forgot password?"** on the sign-in screen and follow the link sent by e-mail.

**I registered but can't sign in.**
Your access needs to be **approved** by the administrator (up to 24h). Also double-check your e-mail/password. If more than 24h have passed, contact support.

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
Yes — the number of stores depends on your **plan** (see **Stores → Upgrades**). Each store has separate stock, sales and cash.

**Do cancelled sales count in reports?**
No. Cancelled sales stay in history (auditing), but **leave** revenue, KPIs and the day summary.

**Can I export reports?**
Yes — **Export CSV** or **Export PDF** on the Reports screen, and share via WhatsApp, e-mail, etc.

**The app suddenly changed language/currency?**
Currency and language are set by the owner in **Stores → Settings** and apply to the whole business, instantly. If they changed, a setting was changed — you can change it back there.

---

*Questions not answered here? See the [Troubleshooting guide](TROUBLESHOOTING.md) or talk to the store owner / support.*
