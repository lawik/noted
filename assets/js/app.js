import "../../priv/static/assets/style.css";
import "../node_modules/nprogress/nprogress.css";
import "../node_modules/simplemde/dist/simplemde.min.css";
import Alpine from "alpinejs";
import SimpleMDE from "simplemde";

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

hooks.MarkdownEditor = {
    mounted() {
        let current = this;
        var editor = new SimpleMDE({
            element: this.el,
            autoDownloadFontAwesome: false,
            toolbar: false,
            status: false,
            spellChecker: false
        });
        let form = this.el.closest("form");
        let targetInput = form.querySelector(`[name="${this.el.dataset.name}"]`);
        let el = this.el;
        editor.codemirror.on("change", function () {
            var text = editor.value();
            if (chillers[el.dataset.name] != undefined) {
                window.clearTimeout(chillers[el.dataset.name]);
            }
            chillers[el.dataset.name] = window.setTimeout(() => {
                current.pushEvent("save-note", text);
            }, maxDelay);
        });
    }
}


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
