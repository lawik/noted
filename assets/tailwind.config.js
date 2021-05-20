const colors = require('tailwindcss/colors')

module.exports = {
  mode: 'jit',
  purge: [
    "../lib/**/*.ex",
    "../lib/**/*.leex",
    "../lib/**/*.eex",
    "./js/**/*.js",
  ],
  darkMode: false,
  theme: {
    extend: {},
  },
  plugins: [],
  theme: {
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      black: colors.black,
      white: colors.white,
      gray: colors.gray,
      turquoise: {
        DEFAULT: '#1dceaf'
      },
      purple: {
        DEFAULT: '#7552ec'
      },
      pink: {
        DEFAULT: '#d139c8'
      }
    }
  }
};
