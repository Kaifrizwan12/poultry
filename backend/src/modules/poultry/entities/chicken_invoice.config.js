const {
  asRequiredString, asNullableString, asNumber, asEnum, asDateString,
  requireSettingsRef, requirePoultryRef, poultryCollection,
} = require('../poultry.validators');

const SALE_TYPES       = ['live_weight', 'dressed_weight', 'per_bird'];
const PAYMENT_STATUSES = ['unpaid', 'partial', 'paid'];

module.exports = {
  entity: 'chickenInvoices',

  async sanitize({ uid, body, id }) {
    const errors = [];

    // Unique invoiceNo check
    const invoiceNo = asRequiredString(body.invoiceNo, 'invoiceNo', errors);
    if (invoiceNo) {
      const snap = await poultryCollection(uid, 'chickenInvoices')
        .where('invoiceNo', '==', invoiceNo)
        .limit(1)
        .get();
      if (!snap.empty && snap.docs[0].id !== id) {
        errors.push('invoiceNo must be unique');
      }
    }

    const flockId = asRequiredString(body.flockId, 'flockId', errors);
    await requirePoultryRef(uid, 'flocks', flockId, 'flockId', errors);

    const customerId = asRequiredString(body.customerId, 'customerId', errors);
    await requireSettingsRef(uid, 'customers', customerId, 'customerId', errors);

    const salesmanId = asNullableString(body.salesmanId);
    if (salesmanId) await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const saleType         = asEnum(body.saleType, 'saleType', errors, SALE_TYPES);
    const birdsCount       = asNumber(body.birdsCount,       'birdsCount',       errors, { required: true, min: 1, integer: true });
    const totalLiveWeightKg = asNumber(body.totalLiveWeightKg, 'totalLiveWeightKg', errors, { required: true, min: 0.001 });
    const dressedWeightKg   = asNumber(body.dressedWeightKg,   'dressedWeightKg',   errors, { min: 0, defaultValue: 0 });
    const pricePerKg        = asNumber(body.pricePerKg,        'pricePerKg',        errors, { required: true, min: 0.001 });

    // Auto-calc amounts
    const grossAmount    = saleType === 'per_bird'
      ? (birdsCount || 0) * (pricePerKg || 0)
      : (totalLiveWeightKg || 0) * (pricePerKg || 0);
    const discountPercent  = asNumber(body.discountPercent, 'discountPercent', errors, { min: 0, defaultValue: 0 });
    const discountAmount   = grossAmount * (discountPercent || 0) / 100;
    const netAmount        = grossAmount - discountAmount;
    const taxPercent       = asNumber(body.taxPercent, 'taxPercent', errors, { min: 0, defaultValue: 0 });
    const taxAmount        = netAmount * (taxPercent || 0) / 100;
    const totalAmount      = netAmount + taxAmount;
    const advanceReceived  = asNumber(body.advanceReceived, 'advanceReceived', errors, { min: 0, defaultValue: 0 });
    const balanceDue       = totalAmount - (advanceReceived || 0);

    let paymentStatus = 'unpaid';
    if (balanceDue <= 0)                   paymentStatus = 'paid';
    else if (balanceDue < totalAmount)     paymentStatus = 'partial';

    const data = {
      invoiceNo,
      flockId,
      customerId,
      invoiceDate:        asDateString(body.invoiceDate, 'invoiceDate', errors, { required: true }),
      saleType,
      birdsCount,
      totalLiveWeightKg,
      dressedWeightKg,
      pricePerKg,
      grossAmount,
      discountPercent,
      discountAmount,
      netAmount,
      taxPercent,
      taxAmount,
      totalAmount,
      advanceReceived,
      balanceDue,
      paymentStatus,
      vehicleNo:   asNullableString(body.vehicleNo),
      driverName:  asNullableString(body.driverName),
      salesmanId,
      notes:       asNullableString(body.notes),
    };

    return { data, errors };
  },
};
