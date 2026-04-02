import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "searchPanel"];

  toggle() {
    const menu = this.menuTarget;
    this.closeSearch();

    if (menu.classList.contains("hidden")) {
      menu.classList.remove("hidden");
      menu.classList.add("flex");
      setTimeout(() => {
        menu.classList.remove("opacity-0", "scale-95");
        menu.classList.add("opacity-100", "scale-100");
      }, 10);
    } else {
      menu.classList.remove("opacity-100", "scale-100");
      menu.classList.add("opacity-0", "scale-95");
      setTimeout(() => {
        menu.classList.add("hidden");
        menu.classList.remove("flex");
      }, 200);
    }
  }

  toggleSearch() {
    if (!this.hasSearchPanelTarget) return;
    const panel = this.searchPanelTarget;

    // Close burger menu if open
    const menu = this.menuTarget;
    if (!menu.classList.contains("hidden")) {
      menu.classList.remove("opacity-100", "scale-100");
      menu.classList.add("opacity-0", "scale-95");
      setTimeout(() => {
        menu.classList.add("hidden");
        menu.classList.remove("flex");
      }, 200);
    }

    if (panel.classList.contains("hidden")) {
      panel.classList.remove("hidden");
      setTimeout(() => panel.querySelector("input")?.focus(), 50);
    } else {
      this.closeSearch();
    }
  }

  closeSearch() {
    if (this.hasSearchPanelTarget) {
      this.searchPanelTarget.classList.add("hidden");
    }
  }
}
