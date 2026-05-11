const express = require('express');

const unitsRoutes = require('./units');
const packingsRoutes = require('./packings');
const companiesRoutes = require('./companies');
const productGroupsRoutes = require('./productGroups');
const productSubGroupsRoutes = require('./productSubGroups');
const productsRoutes = require('./products');
const discountSchemesRoutes = require('./discountSchemes');
const vendorsRoutes = require('./vendors');
const townsRoutes = require('./towns');
const sectorsRoutes = require('./sectors');
const customersRoutes = require('./customers');
const salesmenRoutes = require('./salesmen');
const accountsRoutes = require('./accounts');
const openingsRoutes = require('./openings');

const router = express.Router();

router.use('/units', unitsRoutes);
router.use('/packings', packingsRoutes);
router.use('/companies', companiesRoutes);
router.use('/product-groups', productGroupsRoutes);
router.use('/product-sub-groups', productSubGroupsRoutes);
router.use('/products', productsRoutes);
router.use('/discount-schemes', discountSchemesRoutes);
router.use('/vendors', vendorsRoutes);
router.use('/towns', townsRoutes);
router.use('/sectors', sectorsRoutes);
router.use('/customers', customersRoutes);
router.use('/salesmen', salesmenRoutes);
router.use('/accounts', accountsRoutes);
router.use('/openings', openingsRoutes);

module.exports = router;
