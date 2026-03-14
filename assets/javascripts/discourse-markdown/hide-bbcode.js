export function setup(helper) {
  helper.registerOptions((opts, siteSettings) => {
    opts.features["hide-bbcode"] = siteSettings.discourse_hide_enabled;
  });

  helper.allowList(["div.bbcode-hide-content"]);

  helper.registerPlugin((md) => {
    md.block.bbcode.ruler.push("hide", {
      tag: "hide",
      wrap: "div.bbcode-hide-content",
    });
  });
}
