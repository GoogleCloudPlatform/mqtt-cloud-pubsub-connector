module.exports = {
  // Overrides for specific file types
  overrides: [
    {
      files: ["**/*.md"],
      options: {
        proseWrap: "always",
        // As recommended by the Google Markdown Style Guide
        // https://google.github.io/styleguide/docguide/style.html
        tabWidth: 4,
      },
    },
  ],
};
