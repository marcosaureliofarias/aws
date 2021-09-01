module.exports = {
  presets: ["@vue/app"],
  env: {
    test: {
      "presets": [["@babel/preset-env"]],
      "plugins": ["@babel/plugin-transform-runtime"]
    },
    development: {
      "plugins": ["@babel/plugin-transform-modules-commonjs"]
    }
  }
};
