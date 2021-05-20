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
  plugins: [],
  theme: {
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      black: colors.black,
      white: colors.white,
      gray: colors.gray,
      dark: {
        DEFAULT: '#1c1b1d'
      },
      light: {
        DEFAULT: '#f5efef'
      },
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
