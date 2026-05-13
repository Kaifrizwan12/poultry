const {
  asRequiredString, asNullableString, asNumber, asBoolean,
  requireSettingsRef, requireInvoicingRef, nextSequentialId, invoicingCollection,
} = require('../invoicing.validators');

function calcLineValues(item) {
  const qtyPacks = item.qtyPacks || 0;
  const qtyLoose = item.qtyLoose || 0;
  const pack     = item.pack     || 1;
  const price    = item.price    || 0;
  const discPct  = item.discPercent || 0;
  const taxPct   = item.salesTaxPercent || 0;

  const lineGross      = (qtyPacks * pack + qtyLoose) * price;
  const lineDisc       = lineGross * (discPct / 100);
  const lineNet        = lineGross - lineDisc;
  const lineTax        = lineNet * (taxPct / 100);
  const lineValueIncST = lineNet + lineTax;
  return { lineGross, lineDisc, lineNet, lineTax, lineValueIncST };
}

module.exports = {
  entity: 'sendOrders',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const sendOrderId = id
      ? asNullableString(body.sendOrderId)
      : await nextSequentialId(uid, 'sendOrders', 'SO');

    const orderId = asRequiredString(body.orderId, 'orderId', errors);
    await requireInvoicingRef(uid, 'purchaseOrders', orderId, 'orderId', errors);

    const bankAccountId = asNullableString(body.bankAccountId);
    if (bankAccountId) await requireSettingsRef(uid, 'accounts', bankAccountId, 'bankAccountId', errors);

    const rawItems = Array.isArray(body.items) ? body.items : [];
    const items = [];
    for (let i = 0; i < rawItems.length; i++) {
      const r = rawItems[i];
      const productId = asRequiredString(r.productId, `items[${i}].productId`, errors);
      if (productId) await requireSettingsRef(uid, 'products', productId, `items[${i}].productId`, errors);

      const qtyPacks        = asNumber(r.qtyPacks, `items[${i}].qtyPacks`, errors, { min: 0, defaultValue: 0 });
      const qtyLoose        = asNumber(r.qtyLoose, `items[${i}].qtyLoose`, errors, { min: 0, defaultValue: 0 });
      const pack            = asNumber(r.pack, `items[${i}].pack`, errors, { min: 0, defaultValue: 1 });
      const price           = asNumber(r.price, `items[${i}].price`, errors, { min: 0, defaultValue: 0 });
      const discPercent     = asNumber(r.discPercent, `items[${i}].discPercent`, errors, { min: 0, max: 100, defaultValue: 0 });
      const salesTaxPercent = asNumber(r.salesTaxPercent, `items[${i}].salesTaxPercent`, errors, { min: 0, defaultValue: 0 });
      const calc = calcLineValues({ qtyPacks, qtyLoose, pack, price, discPercent, salesTaxPercent });

      items.push({
        sNo:          asNumber(r.sNo, `items[${i}].sNo`, errors, { defaultValue: i + 1 }),
        productId,
        productName:  asNullableString(r.productName),
        packingName:  asNullableString(r.packingName),
        pack,
        size:         asNumber(r.size, `items[${i}].size`, errors, { min: 0, defaultValue: 0 }),
        unit:         asNullableString(r.unit),
        qtyPacks,
        qtyLoose,
        bonus:        asNumber(r.bonus, `items[${i}].bonus`, errors, { min: 0, defaultValue: 0 }),
        price,
        discPercent,
        salesTaxPercent,
        ...calc,
      });
    }

    const totalOrderValue = items.reduce((s, l) => s + l.lineValueIncST, 0);

    return {
      data: {
        sendOrderId,
        orderId,
        vendorId:          asNullableString(body.vendorId),
        vendorName:        asNullableString(body.vendorName),
        draftNo:           asNullableString(body.draftNo),
        draftDate:         asNullableString(body.draftDate),
        draftAmount:       asNumber(body.draftAmount, 'draftAmount', errors, { min: 0, defaultValue: 0 }),
        bankAccountId,
        bankAcNo:          asNullableString(body.bankAcNo),
        bankAccountName:   asNullableString(body.bankAccountName),
        description:       asNullableString(body.description),
        includeAllProductsWhenPrinting: asBoolean(body.includeAllProductsWhenPrinting, false),
        items,
        totalOrderValue,
      },
      errors,
    };
  },
};
