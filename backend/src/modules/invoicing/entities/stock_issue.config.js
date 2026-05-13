const {
  asRequiredString, asNullableString, asNumber, asBoolean, asEnum,
  requireSettingsRef, requireInvoicingRef, nextSequentialId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'stockIssues',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const issueType = asEnum(body.issueType, 'issueType', errors, ['issue', 'return'], 'issue');

    const issueId = id
      ? asNullableString(body.issueId)
      : await nextSequentialId(uid, 'stockIssues', issueType === 'issue' ? 'STI' : 'STR');

    const salesmanId = asRequiredString(body.salesmanId, 'salesmanId', errors);
    await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const originalIssueId = asNullableString(body.originalIssueId);
    if (issueType === 'return' && originalIssueId) {
      await requireInvoicingRef(uid, 'stockIssues', originalIssueId, 'originalIssueId', errors);
    }

    const rawItems = Array.isArray(body.items) ? body.items : [];
    const items = [];
    for (let i = 0; i < rawItems.length; i++) {
      const r = rawItems[i];
      const productId = asRequiredString(r.productId, `items[${i}].productId`, errors);
      if (productId) await requireSettingsRef(uid, 'products', productId, `items[${i}].productId`, errors);

      const packingId = asNullableString(r.packingId);
      if (packingId) await requireSettingsRef(uid, 'packings', packingId, `items[${i}].packingId`, errors);

      const qtyPacks = asNumber(r.qtyPacks, `items[${i}].qtyPacks`, errors, { min: 0, defaultValue: 0 });
      const qtyLoose = asNumber(r.qtyLoose, `items[${i}].qtyLoose`, errors, { min: 0, defaultValue: 0 });
      const pack     = asNumber(r.pack, `items[${i}].pack`, errors, { min: 0, defaultValue: 1 });
      const cost     = asNumber(r.cost, `items[${i}].cost`, errors, { min: 0, defaultValue: 0 });
      const value    = (qtyPacks * pack + qtyLoose) * cost;

      items.push({
        productId,
        productName:  asNullableString(r.productName),
        packingId,
        packingName:  asNullableString(r.packingName),
        pack,
        qtyPacks,
        qtyLoose,
        cost,
        value,
      });
    }

    const netValue = items.reduce((s, l) => s + l.value, 0);

    return {
      data: {
        issueId,
        issueType,
        date:            asRequiredString(body.date, 'date', errors),
        salesmanId,
        salesmanName:    asNullableString(body.salesmanName),
        originalIssueId,
        returnAll:       asBoolean(body.returnAll, false),
        items,
        netValue,
      },
      errors,
    };
  },
};
