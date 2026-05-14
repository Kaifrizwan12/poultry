const {
  asRequiredString, asNullableString, asNumber,
  requireSettingsRef, nextBusinessId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'stockWastages',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const wastageId = id
      ? asNullableString(body.wastageId)
      : await nextBusinessId(uid, 'stockWastages', 'WAS');

    const rawItems = Array.isArray(body.items) ? body.items : [];
    const items = [];
    for (let i = 0; i < rawItems.length; i++) {
      const r = rawItems[i];
      const productId = asRequiredString(r.productId, `items[${i}].productId`, errors);
      if (productId) await requireSettingsRef(uid, 'products', productId, `items[${i}].productId`, errors);

      const expQtyPacks = asNumber(r.expQtyPacks, `items[${i}].expQtyPacks`, errors, { min: 0, defaultValue: 0 });
      const expQtyLoose = asNumber(r.expQtyLoose, `items[${i}].expQtyLoose`, errors, { min: 0, defaultValue: 0 });
      const damQtyPacks = asNumber(r.damQtyPacks, `items[${i}].damQtyPacks`, errors, { min: 0, defaultValue: 0 });
      const damQtyLoose = asNumber(r.damQtyLoose, `items[${i}].damQtyLoose`, errors, { min: 0, defaultValue: 0 });
      const pack        = asNumber(r.pack, `items[${i}].pack`, errors, { min: 0, defaultValue: 1 });
      const cost        = asNumber(r.cost, `items[${i}].cost`, errors, { min: 0, defaultValue: 0 });
      const value       = (expQtyPacks * pack + expQtyLoose + damQtyPacks * pack + damQtyLoose) * cost;

      items.push({
        productId,
        productName: asNullableString(r.productName),
        packingName: asNullableString(r.packingName),
        pack,
        expQtyPacks, expQtyLoose, damQtyPacks, damQtyLoose,
        cost, value,
      });
    }

    const netValue = items.reduce((s, l) => s + l.value, 0);

    return {
      data: {
        wastageId,
        date: asRequiredString(body.date, 'date', errors),
        items,
        netValue,
      },
      errors,
    };
  },
};
