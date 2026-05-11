const {
  ensureExists,
  settingsCollection,
} = require('../utils/firestore');

const enums = {
  discountType: ['percentage', 'flat'],
  discountApplicableTo: ['all', 'product_group', 'product'],
  balanceType: ['debit', 'credit'],
  commissionType: ['none', 'percentage', 'flat'],
  accountType: ['asset', 'liability', 'equity', 'income', 'expense'],
};

function trimString(value, fallback) {
  if (value === undefined || value === null) {
    return fallback === undefined ? undefined : fallback;
  }
  return String(value).trim();
}

function asNullableString(value) {
  const next = trimString(value, '');
  return next;
}

function asRequiredString(value, field, errors, options = {}) {
  const next = trimString(value);
  if (!next) {
    errors.push(`${field} is required`);
    return '';
  }
  if (options.maxLength && next.length > options.maxLength) {
    errors.push(`${field} must be at most ${options.maxLength} characters`);
  }
  return next;
}

function asNumber(value, field, errors, options = {}) {
  if (value === undefined || value === null || value == '') {
    if (options.required) {
      errors.push(`${field} is required`);
    }
    return options.defaultValue !== undefined ? options.defaultValue : null;
  }

  const next = Number(value);
  if (Number.isNaN(next)) {
    errors.push(`${field} must be a number`);
    return options.defaultValue !== undefined ? options.defaultValue : null;
  }
  if (options.min !== undefined && next < options.min) {
    errors.push(`${field} must be at least ${options.min}`);
  }
  return next;
}

function asBoolean(value, defaultValue) {
  if (value === undefined || value === null) {
    return defaultValue;
  }
  return Boolean(value);
}

function asEnum(value, field, errors, allowed, defaultValue) {
  const next = trimString(value, defaultValue);
  if (!next) {
    errors.push(`${field} is required`);
    return defaultValue;
  }
  if (!allowed.includes(next)) {
    errors.push(`${field} must be one of: ${allowed.join(', ')}`);
  }
  return next;
}

function asDateString(value, field, errors, options = {}) {
  if (!value) {
    if (options.required) {
      errors.push(`${field} is required`);
    }
    return '';
  }

  const next = new Date(value);
  if (Number.isNaN(next.getTime())) {
    errors.push(`${field} must be a valid date`);
    return '';
  }
  return next.toISOString();
}

function cleanStringList(value) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item) => String(item).trim())
    .filter((item) => item.length > 0);
}

async function requireReference(uid, entity, id, field, errors) {
  if (!id) {
    return;
  }
  const exists = await ensureExists(uid, entity, id);
  if (!exists) {
    errors.push(`${field} does not exist`);
  }
}

async function requireAccountCodeUnique(uid, accountCode, currentId, errors) {
  if (!accountCode) {
    return;
  }

  const snapshot = await settingsCollection(uid, 'accounts')
    .where('accountCode', '==', accountCode)
    .limit(1)
    .get();

  if (!snapshot.empty && snapshot.docs[0].id !== currentId) {
    errors.push('accountCode must be unique');
  }
}

async function validatePhone(value, field, errors, required) {
  const next = trimString(value, '');
  if (!next) {
    if (required) {
      errors.push(`${field} is required`);
    }
    return '';
  }
  if (!/^[0-9+\-()\s]{7,20}$/.test(next)) {
    errors.push(`${field} has invalid format`);
  }
  return next;
}

function nowIso() {
  return new Date().toISOString();
}

const settingsConfigs = {
  units: {
    entity: 'units',
    sanitize: async ({ body }) => {
      const errors = [];
      const data = {
        name: asRequiredString(body.name, 'name', errors),
        abbreviation: asRequiredString(body.abbreviation, 'abbreviation', errors, {
          maxLength: 10,
        }),
        description: asNullableString(body.description),
      };
      return { data, errors };
    },
  },
  packings: {
    entity: 'packings',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const unitId = asRequiredString(body.unitId, 'unitId', errors);
      await requireReference(uid, 'units', unitId, 'unitId', errors);
      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          unitId,
          quantity: asNumber(body.quantity, 'quantity', errors, {
            required: true,
            min: 0.000001,
          }),
          description: asNullableString(body.description),
        },
        errors,
      };
    },
  },
  companies: {
    entity: 'companies',
    sanitize: async ({ body }) => {
      const errors = [];
      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          address: asNullableString(body.address),
          phone: asNullableString(body.phone),
          email: asNullableString(body.email),
          ntn: asNullableString(body.ntn),
          strn: asNullableString(body.strn),
          contactPerson: asNullableString(body.contactPerson),
          notes: asNullableString(body.notes),
        },
        errors,
      };
    },
  },
  productGroups: {
    entity: 'productGroups',
    sanitize: async ({ body }) => {
      const errors = [];
      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          description: asNullableString(body.description),
        },
        errors,
      };
    },
  },
  productSubGroups: {
    entity: 'productSubGroups',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const groupId = asRequiredString(body.groupId, 'groupId', errors);
      await requireReference(uid, 'productGroups', groupId, 'groupId', errors);
      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          groupId,
          description: asNullableString(body.description),
        },
        errors,
      };
    },
  },
  products: {
    entity: 'products',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const groupId = asRequiredString(body.groupId, 'groupId', errors);
      const subGroupId = asNullableString(body.subGroupId);
      const unitId = asNullableString(body.unitId);
      const packingId = asNullableString(body.packingId);

      await requireReference(uid, 'productGroups', groupId, 'groupId', errors);
      await requireReference(uid, 'productSubGroups', subGroupId, 'subGroupId', errors);
      await requireReference(uid, 'units', unitId, 'unitId', errors);
      await requireReference(uid, 'packings', packingId, 'packingId', errors);

      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          code: asNullableString(body.code),
          groupId,
          subGroupId,
          unitId,
          packingId,
          salePrice: asNumber(body.salePrice, 'salePrice', errors, {
            defaultValue: 0,
            min: 0,
          }),
          purchasePrice: asNumber(body.purchasePrice, 'purchasePrice', errors, {
            defaultValue: 0,
            min: 0,
          }),
          taxPercent: asNumber(body.taxPercent, 'taxPercent', errors, {
            defaultValue: 0,
            min: 0,
          }),
          isActive: asBoolean(body.isActive, true),
          description: asNullableString(body.description),
        },
        errors,
      };
    },
  },
  discountSchemes: {
    entity: 'discountSchemes',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const applicableTo = asEnum(
        body.applicableTo,
        'applicableTo',
        errors,
        enums.discountApplicableTo,
        'all'
      );
      const refId = asNullableString(body.refId);

      if (applicableTo === 'product_group') {
        await requireReference(uid, 'productGroups', refId, 'refId', errors);
      } else if (applicableTo === 'product') {
        await requireReference(uid, 'products', refId, 'refId', errors);
      }

      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          type: asEnum(body.type, 'type', errors, enums.discountType, 'percentage'),
          value: asNumber(body.value, 'value', errors, {
            required: true,
            min: 0.000001,
          }),
          applicableTo,
          refId,
          validFrom: asDateString(body.validFrom, 'validFrom', errors),
          validTo: asDateString(body.validTo, 'validTo', errors),
          notes: asNullableString(body.notes),
        },
        errors,
      };
    },
  },
  vendors: {
    entity: 'vendors',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const companyId = asNullableString(body.companyId);
      await requireReference(uid, 'companies', companyId, 'companyId', errors);
      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          companyId,
          phone: await validatePhone(body.phone, 'phone', errors, false),
          email: asNullableString(body.email),
          address: asNullableString(body.address),
          town: asNullableString(body.town),
          openingBalance: asNumber(body.openingBalance, 'openingBalance', errors, {
            defaultValue: 0,
          }),
          balanceType: asEnum(
            body.balanceType,
            'balanceType',
            errors,
            enums.balanceType,
            'credit'
          ),
          notes: asNullableString(body.notes),
        },
        errors,
      };
    },
  },
  towns: {
    entity: 'towns',
    sanitize: async ({ body }) => {
      const errors = [];
      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          district: asNullableString(body.district),
          province: trimString(body.province, 'Sindh'),
        },
        errors,
      };
    },
  },
  sectors: {
    entity: 'sectors',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const townId = asRequiredString(body.townId, 'townId', errors);
      await requireReference(uid, 'towns', townId, 'townId', errors);
      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          townId,
          description: asNullableString(body.description),
        },
        errors,
      };
    },
  },
  customers: {
    entity: 'customers',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const townId = asNullableString(body.townId);
      const sectorId = asNullableString(body.sectorId);
      const salesmanId = asNullableString(body.salesmanId);
      const companyId = asNullableString(body.companyId);
      const discountSchemeId = asNullableString(body.discountSchemeId);

      await requireReference(uid, 'towns', townId, 'townId', errors);
      await requireReference(uid, 'sectors', sectorId, 'sectorId', errors);
      await requireReference(uid, 'salesmen', salesmanId, 'salesmanId', errors);
      await requireReference(uid, 'companies', companyId, 'companyId', errors);
      await requireReference(uid, 'discountSchemes', discountSchemeId, 'discountSchemeId', errors);

      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          code: trimString(body.code, ''),
          phone: await validatePhone(body.phone, 'phone', errors, true),
          altPhone: await validatePhone(body.altPhone, 'altPhone', errors, false),
          email: asNullableString(body.email),
          address: asNullableString(body.address),
          townId,
          sectorId,
          salesmanId,
          companyId,
          creditLimit: asNumber(body.creditLimit, 'creditLimit', errors, {
            defaultValue: 0,
          }),
          openingBalance: asNumber(body.openingBalance, 'openingBalance', errors, {
            defaultValue: 0,
          }),
          balanceType: asEnum(
            body.balanceType,
            'balanceType',
            errors,
            enums.balanceType,
            'credit'
          ),
          discountSchemeId,
          isActive: asBoolean(body.isActive, true),
          notes: asNullableString(body.notes),
        },
        errors,
      };
    },
  },
  salesmen: {
    entity: 'salesmen',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const assignedTowns = cleanStringList(body.assignedTowns);
      for (const townId of assignedTowns) {
        await requireReference(uid, 'towns', townId, 'assignedTowns', errors);
      }
      return {
        data: {
          name: asRequiredString(body.name, 'name', errors),
          code: trimString(body.code, ''),
          phone: await validatePhone(body.phone, 'phone', errors, true),
          email: asNullableString(body.email),
          address: asNullableString(body.address),
          joiningDate: asDateString(body.joiningDate, 'joiningDate', errors),
          baseSalary: asNumber(body.baseSalary, 'baseSalary', errors, {
            defaultValue: 0,
          }),
          commissionType: asEnum(
            body.commissionType,
            'commissionType',
            errors,
            enums.commissionType,
            'none'
          ),
          commissionValue: asNumber(body.commissionValue, 'commissionValue', errors, {
            defaultValue: 0,
            min: 0,
          }),
          assignedTowns,
          isActive: asBoolean(body.isActive, true),
          notes: asNullableString(body.notes),
        },
        errors,
      };
    },
  },
  accounts: {
    entity: 'accounts',
    sanitize: async ({ uid, body, id }) => {
      const errors = [];
      const parentAccountId = asNullableString(body.parentAccountId);
      await requireReference(uid, 'accounts', parentAccountId, 'parentAccountId', errors);

      const accountCode = asRequiredString(body.accountCode, 'accountCode', errors);
      await requireAccountCodeUnique(uid, accountCode, id, errors);

      return {
        data: {
          accountName: asRequiredString(body.accountName, 'accountName', errors),
          accountCode,
          accountType: asEnum(
            body.accountType,
            'accountType',
            errors,
            enums.accountType,
            'asset'
          ),
          parentAccountId,
          openingBalance: asNumber(body.openingBalance, 'openingBalance', errors, {
            defaultValue: 0,
          }),
          balanceType: asEnum(
            body.balanceType,
            'balanceType',
            errors,
            enums.balanceType,
            'debit'
          ),
          isActive: asBoolean(body.isActive, true),
          description: asNullableString(body.description),
        },
        errors,
      };
    },
  },
  openingStock: {
    entity: 'openingStock',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const productId = asRequiredString(body.productId, 'productId', errors);
      await requireReference(uid, 'products', productId, 'productId', errors);
      return {
        data: {
          productId,
          quantity: asNumber(body.quantity, 'quantity', errors, {
            required: true,
            min: 0.000001,
          }),
          rate: asNumber(body.rate, 'rate', errors, {
            required: true,
            min: 0,
          }),
          date: asDateString(body.date, 'date', errors, { required: true }),
        },
        errors,
      };
    },
  },
  openingReceivables: {
    entity: 'openingReceivables',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const customerId = asRequiredString(body.customerId, 'customerId', errors);
      await requireReference(uid, 'customers', customerId, 'customerId', errors);
      return {
        data: {
          customerId,
          amount: asNumber(body.amount, 'amount', errors, {
            required: true,
            min: 0.000001,
          }),
          date: asDateString(body.date, 'date', errors, { required: true }),
          notes: asNullableString(body.notes),
        },
        errors,
      };
    },
  },
  openingPayables: {
    entity: 'openingPayables',
    sanitize: async ({ uid, body }) => {
      const errors = [];
      const vendorId = asRequiredString(body.vendorId, 'vendorId', errors);
      await requireReference(uid, 'vendors', vendorId, 'vendorId', errors);
      return {
        data: {
          vendorId,
          amount: asNumber(body.amount, 'amount', errors, {
            required: true,
            min: 0.000001,
          }),
          date: asDateString(body.date, 'date', errors, { required: true }),
          notes: asNullableString(body.notes),
        },
        errors,
      };
    },
  },
};

function stampNewDocument(uid, data) {
  const timestamp = nowIso();
  return {
    ...data,
    uid,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

function stampUpdatedDocument(existing, data) {
  return {
    ...existing,
    ...data,
    updatedAt: nowIso(),
  };
}

module.exports = {
  enums,
  settingsConfigs,
  stampNewDocument,
  stampUpdatedDocument,
};
