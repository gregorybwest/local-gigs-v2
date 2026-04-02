import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results"];

  connect() {
    this.timeout = null;
    this.latitude = null;
    this.longitude = null;
    this.requestGeolocation();
    this.handleClickOutside = this.handleClickOutside.bind(this);
    document.addEventListener("click", this.handleClickOutside);
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside);
  }

  requestGeolocation() {
    if (!navigator.geolocation) return;

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.latitude = position.coords.latitude;
        this.longitude = position.coords.longitude;
      },
      () => {} // silently ignore denial
    );
  }

  search() {
    clearTimeout(this.timeout);
    const query = this.inputTarget.value.trim();

    if (query.length < 2) {
      this.hideResults();
      return;
    }

    this.timeout = setTimeout(() => {
      this.fetchResults(query);
    }, 300);
  }

  async fetchResults(query) {
    try {
      let url = `/search?q=${encodeURIComponent(query)}`;
      if (this.latitude && this.longitude) {
        url += `&lat=${this.latitude}&lng=${this.longitude}`;
      }

      const response = await fetch(url, {
        headers: { Accept: "application/json" },
      });
      const results = await response.json();
      this.displayResults(results);
    } catch (error) {
      console.error("Search error:", error);
    }
  }

  displayResults(results) {
    if (results.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500 dark:text-gray-400">No results found</div>
      `;
      this.showResults();
      return;
    }

    const resultHtml = results.map((result) => this.renderResult(result)).join("");
    const showMoreHtml = this.renderShowMoreLink();
    this.resultsTarget.innerHTML = resultHtml + showMoreHtml;
    this.showResults();
  }

  renderResult(result) {
    if (result.type === "event") {
      return this.renderEvent(result);
    }
    return this.renderVenue(result);
  }

  renderEvent(result) {
    const showTime = new Date(result.show_time_iso);
    const today = new Date();
    const isToday =
      showTime.getFullYear() === today.getFullYear() &&
      showTime.getMonth() === today.getMonth() &&
      showTime.getDate() === today.getDate();

    const timeDisplay = isToday
      ? showTime.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
      : showTime.toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' });

    const venuePart = result.venue_name ? ` · ${this.escapeHtml(result.venue_name)}` : "";

    return `
      <a href="${result.url}"
         class="flex items-start gap-3 px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer border-b border-gray-100 dark:border-gray-700 last:border-0 no-underline"
         data-turbo-frame="_top">
        <div class="flex-shrink-0 mt-0.5">
          <span class="inline-flex items-center justify-center w-7 h-7 rounded-full" style="background-color: #006D77;">
            <svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
            </svg>
          </span>
        </div>
        <div class="flex-1 min-w-0">
          <div class="font-medium text-gray-900 dark:text-white truncate">${this.escapeHtml(result.name)}</div>
          <div class="text-xs text-gray-500 dark:text-gray-400 truncate">${timeDisplay}${venuePart}</div>
        </div>
        <span class="flex-shrink-0 text-xs px-1.5 py-0.5 rounded font-medium bg-teal-50 text-teal-700 dark:bg-teal-900/40 dark:text-teal-300">Event</span>
      </a>
    `;
  }

  renderVenue(result) {
    return `
      <a href="${result.url}"
         class="flex items-start gap-3 px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer border-b border-gray-100 dark:border-gray-700 last:border-0 no-underline"
         data-turbo-frame="_top">
        <div class="flex-shrink-0 mt-0.5">
          <span class="inline-flex items-center justify-center w-7 h-7 rounded-full bg-indigo-500">
            <svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
            </svg>
          </span>
        </div>
        <div class="flex-1 min-w-0">
          <div class="font-medium text-gray-900 dark:text-white truncate">${this.escapeHtml(result.name)}</div>
          <div class="text-xs text-gray-500 dark:text-gray-400 truncate">${this.escapeHtml(result.city || "")}</div>
        </div>
        <span class="flex-shrink-0 text-xs px-1.5 py-0.5 rounded font-medium bg-indigo-100 text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-300">Venue</span>
      </a>
    `;
  }

  renderShowMoreLink() {
    const query = encodeURIComponent(this.inputTarget.value.trim());
    let url = `/search/results?q=${query}`;
    if (this.latitude && this.longitude) {
      url += `&lat=${this.latitude}&lng=${this.longitude}`;
    }

    return `
      <a href="${url}"
         class="flex items-center justify-center gap-1 px-4 py-2.5 text-sm font-medium text-blue-600 dark:text-blue-400 hover:bg-gray-50 dark:hover:bg-gray-700 no-underline transition-colors"
         data-turbo-frame="_top">
        Show more results
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
      </a>
    `;
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden");
    this.resultsTarget.innerHTML = "";
  }

  showResults() {
    this.resultsTarget.classList.remove("hidden");
  }

  dismiss(event) {
    if (event.key === "Escape") {
      this.hideResults();
      this.inputTarget.blur();
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults();
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text || "";
    return div.innerHTML;
  }
}
