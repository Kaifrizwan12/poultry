const {
  asRequiredString, asNullableString, asNumber, asEnum,
  requireSettingsRef, requirePoultryRef, poultryCollection,
} = require('../poultry.validators');

const FEED_TYPES = ['pre_starter', 'starter', 'grower', 'finisher', 'layer_mash', 'breeder'];

module.exports = {
  entity: 'feedSchedules',

  async sanitize({ uid, body }) {
    const errors = [];

    const ageFromDays = asNumber(body.ageFromDays, 'ageFromDays', errors, { required: true, min: 0, integer: true });
    // ageToDays is optional — omit or pass null for an open-ended (last) schedule
    const ageToDays = body.ageToDays != null
      ? asNumber(body.ageToDays, 'ageToDays', errors, { required: false, min: 0, integer: true })
      : null;

    if (ageFromDays !== null && ageToDays !== null && ageToDays < ageFromDays) {
      errors.push('ageToDays must be >= ageFromDays');
    }

    const feedType = asEnum(body.feedType, 'feedType', errors, FEED_TYPES);
    const productId = asRequiredString(body.productId, 'productId', errors);
    const packingId = asNullableString(body.packingId);

    await requireSettingsRef(uid, 'products', productId, 'productId', errors);
    if (packingId) await requireSettingsRef(uid, 'packings', packingId, 'packingId', errors);

    const data = {
      name: asRequiredString(body.name, 'name', errors),
      feedType,
      ageFromDays,
      ageToDays,
      dailyFeedPerBirdGrams: asNumber(body.dailyFeedPerBirdGrams, 'dailyFeedPerBirdGrams', errors, { required: true, min: 0.001 }),
      productId,
      packingId,
      description: asNullableString(body.description),
    };

    return { data, errors };
  },
};
