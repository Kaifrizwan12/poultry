const {
  asRequiredString, asNullableString, asNumber, asEnum, asDateString,
  requireSettingsRef, nextSequentialId,
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
  entity: 'purchaseOrders',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const orderId = id
      ? asNullableString(body.orderId)
      : await nextSequentialId(uid, 'purchaseOrders', 'PO');

    const vendorId = asRequiredString(body.vendorId, 'vendorId', errors);
    await requireSettingsRef(uid, 'vendors', vendorId, 'vendorId', errors);

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

    const gross        = items.reduce((s, l) => s + l.lineGross, 0);
    const disc2Percent = asNumber(body.disc2Percent, 'disc2Percent', errors, { min: 0, max: 100, defaultValue: 0 });
    const discounts    = gross * (disc2Percent / 100) + items.reduce((s, l) => s + l.lineDisc, 0);
    const invoiceValue = gross - discounts;
    const salesTax     = items.reduce((s, l) => s + l.lineTax, 0);
    const fTaxPercent  = asNumber(body.fTaxPercent, 'fTaxPercent', errors, { min: 0, defaultValue: 0 });
    const furtherTaxValue = invoiceValue * (fTaxPercent / 100);
    const netValue     = invoiceValue + salesTax + furtherTaxValue;

    return {
      data: {
        orderId,
        entryDate:   asRequiredString(body.entryDate, 'entryDate', errors),
        vendorId,
        vendorName:  asNullableString(body.vendorName),
        city:        asNullableString(body.city),
        status:      asEnum(body.status, 'status', errors, ['pending', 'saved'], 'pending'),
        items,
        gross, disc2Percent, discounts, invoiceValue, salesTax,
        fTaxPercent, furtherTaxValue, netValue,
      },
      errors,
    };
  },
};
