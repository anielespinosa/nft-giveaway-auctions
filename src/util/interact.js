require('dotenv').config();
const alchemyKey = process.env.REACT_APP_ALCHEMY_KEY_WSS;
const admin_address = process.env.PUBLIC_KEY;
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const web3 = createAlchemyWeb3(alchemyKey);
