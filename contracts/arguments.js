module.exports = {
  XCounter: [],
  Gateway: {
    base: ["0x5F0Eb0b2913Af7878A09f955249804630F3e28c2"],
    optimism: ["0xf8aAeFefCf789e1df5c48760c64D52ECd25265cf"],
  },
  ERC20Token: ["Polymer USD", "USD.P", 10000],
  // Add your contract types here, along with the list of custom constructor arguments
  // DO NOT ADD THE DISPATCHER OR UNIVERSAL CHANNEL HANDLER ADDRESSES HERE!!!
  // These will be added in the deploy script at $ROOT/scripts/deploy.js
};
