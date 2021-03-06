// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";
import Alpine from "alpinejs";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import { Socket } from "phoenix";
import NProgress from "nprogress";
import { LiveSocket } from "phoenix_live_view";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const maxDelay = 1500;
let chillers = {};
let hooks = {};
hooks.ContentEditable = {
  mounted() {
    let form = this.el.closest("form");
    let targetInput = form.querySelector(`[name="${this.el.dataset.name}"]`);
    this.el.addEventListener("input", () => {
      targetInput.innerText = this.el.innerText;
      if (chillers[this.el.dataset.name] != undefined) {
        window.clearTimeout(chillers[this.el.dataset.name]);
      }
      chillers[this.el.dataset.name] = window.setTimeout(() => {
        targetInput.dispatchEvent(new Event("input", { bubbles: true }));
      }, maxDelay);
    });
  },
};
hooks.PushEvent = {
  mounted() {
    window.pushEventHook = this;
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        Alpine.clone(from.__x, to);
      }
    },
  },
  hooks: hooks,
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", (info) => NProgress.start());
window.addEventListener("phx:page-loading-stop", (info) => NProgress.done());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
