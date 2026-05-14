const {
  asRequiredString, asNullableString, asNumber, asBoolean, asEnum,
  requireSettingsRef, requireInvoicingRef, nextBusinessId, invoicingCollection,
} = require('../invoicing.validators');

module.exports = {
  entity: 'stockIssues',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const issueType = asEnum(body.issueType, 'issueType', errors, ['issue', 'return'], 'issue');

    const issueId = id
      ? asNullableString(body.issueId)
      : await nextBusinessId(uid, 'stockIssues', issueType === 'issue' ? 'STI' : 'STR');

    const salesmanId = asRequiredString(body.salesmanId, 'salesmanId', errors);
    await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const originalIssueId = asNullableString(body.originalIssueId);
    let originalItems = [];
    if (issueType === 'return' && originalIssueId) {
      await requireInvoicingRef(uid, 'stockIssues', originalIssueId, 'originalIssueId', errors);
      // Load original issue quantities for validation
      const origSnap = await invoicingCollection(uid, 'stockIssues').doc(originalIssueId).get();
      if (origSnap.exists) originalItems = origSnap.data().items || [];
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

      // Validate return qty ≤ original issue qty
      if (issueType === 'return' && originalItems.length) {
        const origItem = originalItems.find(it => it.productId === productId);
        if (origItem) {
          if (qtyPacks > (origItem.qtyPacks || 0) + 0.001) {
            errors.push(`items[${i}]: return ${qtyPacks} packs exceeds original issue ${origItem.qtyPacks} packs for product ${productId}`);
          }
          if (qtyLoose > (origItem.qtyLoose || 0) + 0.001) {
            errors.push(`items[${i}]: return ${qtyLoose} loose exceeds original issue ${origItem.qtyLoose} loose for product ${productId}`);
          }
        }
      }

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
