module.exports = {
  // ... other config options ...
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  // Add this line
  solidity: {
    compilers: [{ version: "0.8.24" }],
  },
};
