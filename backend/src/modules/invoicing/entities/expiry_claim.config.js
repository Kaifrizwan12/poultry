const {
  asRequiredString, asNullableString, asNumber, asBoolean, asEnum,
  requireSettingsRef, nextSequentialId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'expiryClaims',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const claimId = id
      ? asNullableString(body.claimId)
      : await nextSequentialId(uid, 'expiryClaims', 'EC');

    const direction = asEnum(body.direction, 'direction', errors, ['from_customer', 'to_vendor'], 'from_customer');

    const customerId = asNullableString(body.customerId);
    if (direction === 'from_customer') {
      if (!customerId) errors.push('customerId is required for from_customer direction');
      else await requireSettingsRef(uid, 'customers', customerId, 'customerId', errors);
    }

    const vendorId = asNullableString(body.vendorId);
    if (direction === 'to_vendor') {
      if (!vendorId) errors.push('vendorId is required for to_vendor direction');
      else await requireSettingsRef(uid, 'vendors', vendorId, 'vendorId', errors);
    }

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
      const costPerUnit = asNumber(r.costPerUnit, `items[${i}].costPerUnit`, errors, { min: 0, defaultValue: 0 });
      const price       = asNumber(r.price, `items[${i}].price`, errors, { min: 0, defaultValue: 0 });
      const value       = (expQtyPacks * pack + expQtyLoose + damQtyPacks * pack + damQtyLoose) * price;

      items.push({
        productId,
        productName: asNullableString(r.productName),
        packingName: asNullableString(r.packingName),
        pack,
        expQtyPacks, expQtyLoose, damQtyPacks, damQtyLoose,
        costPerUnit, price, value,
      });
    }

    const netValue = items.reduce((s, l) => s + l.value, 0);

    // Reply section
    const rawReplyItems = Array.isArray(body.replyItems) ? body.replyItems : [];
    const replyItems = [];
    for (let i = 0; i < rawReplyItems.length; i++) {
      const r = rawReplyItems[i];
      if (!r.productId) continue;
      const productId = asRequiredString(r.productId, `replyItems[${i}].productId`, errors);
      if (productId) await requireSettingsRef(uid, 'products', productId, `replyItems[${i}].productId`, errors);

      const qtyPacks = asNumber(r.qtyPacks, `replyItems[${i}].qtyPacks`, errors, { min: 0, defaultValue: 0 });
      const qtyLoose = asNumber(r.qtyLoose, `replyItems[${i}].qtyLoose`, errors, { min: 0, defaultValue: 0 });
      const pack     = asNumber(r.pack, `replyItems[${i}].pack`, errors, { min: 0, defaultValue: 1 });
      const price    = asNumber(r.price, `replyItems[${i}].price`, errors, { min: 0, defaultValue: 0 });
      const value    = (qtyPacks * pack + qtyLoose) * price;

      replyItems.push({
        productId,
        productName: asNullableString(r.productName),
        packingName: asNullableString(r.packingName),
        pack,
        qtyPacks, qtyLoose, price, value,
      });
    }

    const replyNetValue = replyItems.reduce((s, l) => s + l.value, 0);

    return {
      data: {
        claimId,
        direction,
        claimDate:        asRequiredString(body.claimDate, 'claimDate', errors),
        customerId,
        customerName:     asNullableString(body.customerName),
        vendorId,
        vendorName:       asNullableString(body.vendorName),
        items,
        netValue,
        replyDate:           asNullableString(body.replyDate),
        returnSameProducts:  asBoolean(body.returnSameProducts, false),
        replyItems,
        replyNetValue,
        repliedAmount:       body.repliedAmount != null ? asNumber(body.repliedAmount, 'repliedAmount', errors, { min: 0, defaultValue: 0 }) : null,
      },
      errors,
    };
  },
};
