"use strict";
const VueLoaderPlugin = require("vue-loader/lib/plugin");
const path = require("path");

module.exports = {
  output: {
    path: path.join(__dirname, "assets/javascripts/easy_vue"),
    filename: "bundle.js"
  },
  entry: ["./app/javascripts/src/main.js"],
  resolve: {
    extensions: ["*", ".js", ".vue", ".json", ".scss"]
  },
  module: {
    rules: [
      {
        enforce: "pre",
        test: /\.(js|vue)$/,
        exclude: /node_modules/,
        loader: "eslint-loader",
        options: {
          formatter: require("eslint/lib/formatters/codeframe")
        }
      },
      {
        test: /\.vue$/,
        loader: "vue-loader"
      },
      // this will apply to both plain `.js` files
      // AND `<script>` blocks in `.vue` files
      {
        test: /\.js$/,
        exclude: /node_modules(?!\/@easy)/,
        loader: "babel-loader",
        options: {
          plugins: ["transform-es2015-modules-commonjs", "lodash"],
          presets: [
            [
              "@babel/preset-env",
              {
                targets: {
                  esmodules: true,
                  node: 6
                }
              }
            ]
          ]
        }
      },
      {
        test: /\.scss$/,
        use: [
          "style-loader", // creates style nodes from JS strings
          "css-loader", // translates CSS into CommonJS
          "sass-loader" // compiles Sass to CSS, using Node Sass by default
        ]
      },
      {
        test: /\.less$/,
        use: [{
          loader: "style-loader"
        }, {
          loader: "css-loader"
        }, {
          loader: "less-loader",
          options: {
            lessOptions: {
              javascriptEnabled: true
            }
          }
        }]
      },

      // this will apply to both plain `.css` files
      // AND `<style>` blocks in `.vue` files
      {
        test: /\.css$/,
        use: ["vue-style-loader", "css-loader"]
      },
      {
        test: /\.xml$/,
        use: "xml-loader"
      },
      {
        test: /\.(png|svg|jpg|gif|eot|ttf|woff|woff2)$/,
        loader: "url-loader"
      }
    ]
  },
  devServer: {
    publicPath: "/assets/easy_vue/"
  },
  plugins: [new VueLoaderPlugin()]
};
