module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2020,
  },
  extends: [
    "eslint:recommended",
    // "google", // Google stil kurallarını devre dışı bırakıyorum
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", {"allowTemplateLiterals": true}],
    // Stil hatalarını devre dışı bırakıyorum
    "indent": "off",
    "max-len": "off",
    "no-trailing-spaces": "off",
    "comma-dangle": "off",
    "no-unused-vars": "warn" // Hata yerine uyarı olarak değiştiriyorum
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
