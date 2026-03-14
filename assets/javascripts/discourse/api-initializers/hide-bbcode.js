import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.1", (api) => {
  api.decorateCookedElement(
    (element) => {
      element.querySelectorAll(".bbcode-hide-placeholder").forEach((el) => {
        if (el.dataset.hideProcessed) return;
        el.dataset.hideProcessed = "true";

        el.setAttribute("role", "note");
        el.setAttribute("aria-label", "此内容已隐藏，回复本帖后可见");

        el.innerHTML = `
          <div class="hide-placeholder-inner">
            <svg class="hide-lock-icon" viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
            </svg>
            <span class="hide-placeholder-text">此内容已隐藏，回复本帖后可见</span>
          </div>
        `;
      });

      element.querySelectorAll(".bbcode-hide-revealed").forEach((el) => {
        if (el.dataset.hideProcessed) return;
        el.dataset.hideProcessed = "true";
      });
    },
    { id: "hide-bbcode" }
  );

  api.onAppEvent("post:created", () => {
    const appEvents = api.container.lookup("service:app-events");
    if (appEvents) {
      setTimeout(() => {
        appEvents.trigger("post-stream:refresh");
      }, 1000);
    }
  });
});
