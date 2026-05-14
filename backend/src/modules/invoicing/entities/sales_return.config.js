const {
  asRequiredString, asNullableString, asNumber, asBoolean, asEnum,
  requireSettingsRef, requireInvoicingRef, nextBusinessId, invoicingCollection,
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
  entity: 'salesReturns',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const returnId = id
      ? asNullableString(body.returnId)
      : await nextBusinessId(uid, 'salesReturns', 'SR');

    const returnType = asEnum(body.returnType, 'returnType', errors, ['with_invoice', 'without_invoice'], 'without_invoice');

    const saleId = asNullableString(body.saleId);
    if (returnType === 'with_invoice') {
      if (!saleId) errors.push('saleId is required for with_invoice return type');
      else await requireInvoicingRef(uid, 'salesInvoices', saleId, 'saleId', errors);
    }

    const customerId = asRequiredString(body.customerId, 'customerId', errors);
    await requireSettingsRef(uid, 'customers', customerId, 'customerId', errors);

    const salesmanId = asNullableString(body.salesmanId);
    if (salesmanId) await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const rawItems = Array.isArray(body.items) ? body.items : [];
    const items = [];
    for (let i = 0; i < rawItems.length; i++) {
      const r = rawItems[i];
      const productId = asRequiredString(r.productId, `items[${i}].productId`, errors);
      if (productId) await requireSettingsRef(uid, 'products', productId, `items[${i}].productId`, errors);

      const pack            = asNumber(r.pack, `items[${i}].pack`, errors, { min: 0, defaultValue: 1 });
      const price           = asNumber(r.price, `items[${i}].price`, errors, { min: 0, defaultValue: 0 });
      const discPercent     = asNumber(r.discPercent, `items[${i}].discPercent`, errors, { min: 0, max: 100, defaultValue: 0 });
      const salesTaxPercent = asNumber(r.salesTaxPercent, `items[${i}].salesTaxPercent`, errors, { min: 0, defaultValue: 0 });

      let lineItem = {
        sNo:          asNumber(r.sNo, `items[${i}].sNo`, errors, { defaultValue: i + 1 }),
        productId,
        productName:  asNullableString(r.productName),
        packingName:  asNullableString(r.packingName),
        pack,
        price,
        discPercent,
        salesTaxPercent,
      };

      if (returnType === 'with_invoice') {
        const currentReturnQtyPacks = asNumber(r.currentReturnQtyPacks, `items[${i}].currentReturnQtyPacks`, errors, { min: 0, defaultValue: 0 });
        const currentReturnQtyLoose = asNumber(r.currentReturnQtyLoose, `items[${i}].currentReturnQtyLoose`, errors, { min: 0, defaultValue: 0 });
        const saleQtyPacks   = asNumber(r.saleQtyPacks, `items[${i}].saleQtyPacks`, errors, { min: 0, defaultValue: 0 });
        const saleQtyLoose   = asNumber(r.saleQtyLoose, `items[${i}].saleQtyLoose`, errors, { min: 0, defaultValue: 0 });

        // Server-side: compute cumulative previous returns for this saleId + productId
        let prevReturnedQtyPacks = 0;
        let prevReturnedQtyLoose = 0;
        if (saleId && productId && !errors.length) {
          const prevSnap = await invoicingCollection(uid, 'salesReturns')
            .where('saleId', '==', saleId).get();
          prevSnap.docs.forEach(doc => {
            if (doc.id === id) return; // skip current doc on update
            const docItems = doc.data().items || [];
            const match = docItems.find(it => it.productId === productId);
            if (match) {
              prevReturnedQtyPacks += match.currentReturnQtyPacks || 0;
              prevReturnedQtyLoose += match.currentReturnQtyLoose || 0;
            }
          });
        }

        const totalReturnPacks = prevReturnedQtyPacks + currentReturnQtyPacks;
        const totalReturnLoose = prevReturnedQtyLoose + currentReturnQtyLoose;
        if (totalReturnPacks > saleQtyPacks + 0.001) {
          errors.push(`items[${i}]: return qty (${totalReturnPacks} packs) exceeds original sale qty (${saleQtyPacks} packs) for product ${productId}`);
        }
        if (totalReturnLoose > saleQtyLoose + 0.001) {
          errors.push(`items[${i}]: return loose qty (${totalReturnLoose}) exceeds original sale loose qty (${saleQtyLoose}) for product ${productId}`);
        }

        const calc = calcLineValues({ qtyPacks: currentReturnQtyPacks, qtyLoose: currentReturnQtyLoose, pack, price, discPercent, salesTaxPercent });
        lineItem = {
          ...lineItem,
          saleQtyPacks,
          saleQtyLoose,
          saleBns:               asNumber(r.saleBns, `items[${i}].saleBns`, errors, { min: 0, defaultValue: 0 }),
          prevReturnedQtyPacks, // server-computed, not trusted from client
          prevReturnedQtyLoose,
          currentReturnQtyPacks,
          currentReturnQtyLoose,
          ...calc,
        };
      } else {
        const qtyPacks = asNumber(r.qtyPacks, `items[${i}].qtyPacks`, errors, { min: 0, defaultValue: 0 });
        const qtyLoose = asNumber(r.qtyLoose, `items[${i}].qtyLoose`, errors, { min: 0, defaultValue: 0 });
        const calc = calcLineValues({ qtyPacks, qtyLoose, pack, price, discPercent, salesTaxPercent });
        lineItem = { ...lineItem, qtyPacks, qtyLoose, ...calc };
      }

      items.push(lineItem);
    }

    const lineNetValues = items.map(l => l.lineNet || 0);
    const invoiceValue  = lineNetValues.reduce((s, v) => s + v, 0);
    const disc2Percent  = asNumber(body.disc2Percent, 'disc2Percent', errors, { min: 0, max: 100, defaultValue: 0 });
    const salesTax      = items.reduce((s, l) => s + (l.lineTax || 0), 0);
    const fTaxPercent   = asNumber(body.fTaxPercent, 'fTaxPercent', errors, { min: 0, defaultValue: 0 });
    const furtherTaxValue = invoiceValue * (fTaxPercent / 100);
    const sed           = asNumber(body.sed, 'sed', errors, { min: 0, defaultValue: 0 });
    const specialDiscount = asNumber(body.specialDiscount, 'specialDiscount', errors, { min: 0, defaultValue: 0 });
    const netValue      = invoiceValue + salesTax + furtherTaxValue + sed - specialDiscount;
    const prevCredit    = asNumber(body.prevCredit, 'prevCredit', errors, { defaultValue: 0 });
    const totalPayable  = netValue + prevCredit;
    const paidAmount    = asNumber(body.paidAmount, 'paidAmount', errors, { min: 0, defaultValue: 0 });
    const remBalance    = totalPayable - paidAmount;

    return {
      data: {
        returnId,
        returnType,
        returnDate:   asRequiredString(body.returnDate, 'returnDate', errors),
        saleId,
        saleDate:     asNullableString(body.saleDate),
        isFullReturn: asBoolean(body.isFullReturn, false),
        customerId,
        customerName: asNullableString(body.customerName),
        townId:       asNullableString(body.townId),
        sectorId:     asNullableString(body.sectorId),
        salesmanId,
        salesmanName: asNullableString(body.salesmanName),
        toMainStore:  asBoolean(body.toMainStore, true),
        items,
        disc2Percent, invoiceValue, salesTax,
        fTaxPercent, furtherTaxValue, sed, specialDiscount,
        netValue, prevCredit, totalPayable, paidAmount, remBalance,
        description:  asNullableString(body.description),
      },
      errors,
    };
  },
};
