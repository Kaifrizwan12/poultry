const {
  asRequiredString, asNullableString, asNumber, asDateString,
  requireSettingsRef, requirePoultryRef, poultryCollection,
} = require('../poultry.validators');

module.exports = {
  entity: 'flockFeeds',

  async sanitize({ uid, body }) {
    const errors = [];

    const flockId = asRequiredString(body.flockId, 'flockId', errors);
    await requirePoultryRef(uid, 'flocks', flockId, 'flockId', errors);

    const feedScheduleId = asNullableString(body.feedScheduleId);
    if (feedScheduleId) await requirePoultryRef(uid, 'feedSchedules', feedScheduleId, 'feedScheduleId', errors);

    const productId = asRequiredString(body.productId, 'productId', errors);
    await requireSettingsRef(uid, 'products', productId, 'productId', errors);

    const birdsCount      = asNumber(body.birdsCount, 'birdsCount', errors, { required: true, min: 1, integer: true });
    const mortalityCount  = asNumber(body.mortalityCount, 'mortalityCount', errors, { min: 0, integer: true, defaultValue: 0 });
    const feedConsumedKg  = asNumber(body.feedConsumedKg, 'feedConsumedKg', errors, { required: true, min: 0 });
    const averageWeightKg = asNumber(body.averageWeightKg, 'averageWeightKg', errors, { min: 0, defaultValue: 0 });

    // Auto-calc standardFeedKg from schedule
    let standardFeedKg = null;
    let feedVarianceKg = null;
    if (feedScheduleId && birdsCount) {
      try {
        const snap = await poultryCollection(uid, 'feedSchedules').doc(feedScheduleId).get();
        if (snap.exists) {
          const gramsPer = snap.data().dailyFeedPerBirdGrams || 0;
          standardFeedKg = (gramsPer * birdsCount) / 1000;
        }
      } catch (_) { /* ignore */ }
    }
    if (standardFeedKg !== null && feedConsumedKg !== null) {
      feedVarianceKg = feedConsumedKg - standardFeedKg;
    }

    const data = {
      flockId,
      feedScheduleId,
      date:           asDateString(body.date, 'date', errors, { required: true }),
      ageDays:        asNumber(body.ageDays, 'ageDays', errors, { required: true, min: 0, integer: true }),
      birdsCount,
      mortalityCount,
      feedConsumedKg,
      standardFeedKg,
      feedVarianceKg,
      averageWeightKg,
      productId,
      batchNo:  asNullableString(body.batchNo),
      notes:    asNullableString(body.notes),
    };

    return { data, errors };
  },
};
