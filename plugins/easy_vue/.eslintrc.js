module.exports = {
  root: true,
  parserOptions: {
    parser: "babel-eslint",
    sourceType: "module"
  },
  env: {
    browser: true
  },
  extends: [
    "eslint:recommended",
    "plugin:prettier/recommended",
    "plugin:vue/recommended"
  ],
  plugins: ["vue"],
  rules: {
    "max-len": ["warn", { "code": 120 }],
    "no-console": process.env.NODE_ENV === "production" ? "error" : "off",
    "no-debugger": process.env.NODE_ENV === "production" || "development" ? "warn" : "off",
    "no-unused-vars": "warn",
    quotes: "off",
    semi: [2, "always"],
    "no-undef": "off",
    "comma-dangle": "off",
    "vue/require-default-prop": "off",
    "vue/max-attributes-per-line": "off",
    "prettier/prettier": ["error", { semi: true }],
    "prettier/prettier": ["warning", { printWidth: 120 }],
    "vue/no-v-html": "off",
    "vue/html-self-closing": [
      "error",
      {
        html: {
          void: "always",
          normal: "always",
          component: "always"
        },
        svg: "always",
        math: "always"
      }
    ]
  }
};
