const {
  asRequiredString, asNullableString, asNumber, asBoolean, asEnum,
  requireSettingsRef,
} = require('../poultry.validators');

const VACCINE_TYPES = ['newcastle', 'infectious_bronchitis', 'gumboro', 'mareks', 'avian_influenza', 'fowl_pox', 'other'];
const ADMIN_ROUTES  = ['drinking_water', 'eye_drop', 'spray', 'injection', 'wing_stab'];

module.exports = {
  entity: 'vaccineSchedules',

  async sanitize({ uid, body }) {
    const errors = [];

    const productId = asRequiredString(body.productId, 'productId', errors);
    await requireSettingsRef(uid, 'products', productId, 'productId', errors);

    const boosterRequired = asBoolean(body.boosterRequired, false);
    const boosterIntervalDays = boosterRequired
      ? asNumber(body.boosterIntervalDays, 'boosterIntervalDays', errors, { required: true, min: 1, integer: true })
      : null;

    const data = {
      name:                 asRequiredString(body.name, 'name', errors),
      vaccineType:          asEnum(body.vaccineType, 'vaccineType', errors, VACCINE_TYPES),
      targetAgeDays:        asNumber(body.targetAgeDays, 'targetAgeDays', errors, { required: true, min: 0, integer: true }),
      administrationRoute:  asEnum(body.administrationRoute, 'administrationRoute', errors, ADMIN_ROUTES),
      dosePerBird:          asNumber(body.dosePerBird, 'dosePerBird', errors, { required: true, min: 0.0001 }),
      productId,
      boosterRequired,
      boosterIntervalDays,
      description: asNullableString(body.description),
    };

    return { data, errors };
  },
};
