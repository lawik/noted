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
};
