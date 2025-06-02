# My Learning Log Blog

This is my personal blog where I document things I learn.

## Hosting

This blog is built using a custom static site generator and hosted on GitHub Pages. It is accessible via the custom domain [hamishburke.dev](https://hamishburke.dev).

## Building the Blog

To build the blog, run the `build.sh` script from the root of the repository:

```bash
./build.sh
```

This script will process the Markdown files in the `posts/` directory, apply templates, and generate the static HTML site in the `_site/` directory.

## Running Locally

To build the site and serve it locally for development, you can use the `run.sh` script:

```bash
./run.sh
```

This will start a local web server (usually on `http://localhost:8000`) serving the content from the `_site/` directory. You can then open this URL in your web browser to view the blog.
