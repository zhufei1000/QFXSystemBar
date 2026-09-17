// Rasterizes the WebIconSets source SVGs for gen_micromenu_icons.py.
//
//   node tools/rasterize_svg.js <jobs.json>
//
// jobs.json = [{ "svg": "<path>", "out": "<png path>", "size": 96 }, ...]
// Requires @resvg/resvg-js: install it next to this file (npm i @resvg/resvg-js)
// or point RESVG_PATH at an existing installation.
const fs = require("fs");
const { Resvg } = require(process.env.RESVG_PATH || "@resvg/resvg-js");

const jobs = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
for (const job of jobs) {
  const svg = fs.readFileSync(job.svg, "utf8");
  const resvg = new Resvg(svg, {
    fitTo: { mode: "width", value: job.size },
    background: "rgba(0,0,0,0)",
  });
  fs.writeFileSync(job.out, resvg.render().asPng());
}
console.log(JSON.stringify({ rendered: jobs.length }));
