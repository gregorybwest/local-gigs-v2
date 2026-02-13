import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results", "venueId", "selectedVenue"];
  static values = { url: String };

  connect() {
    this.timeout = null;
    console.log("VenueSearch controller connected");
    console.log("URL value:", this.urlValue);
    console.log("Targets found:", {
      input: this.hasInputTarget,
      results: this.hasResultsTarget,
      venueId: this.hasVenueIdTarget,
      selectedVenue: this.hasSelectedVenueTarget,
    });
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
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" },
      });
      const results = await response.json();
      this.displayResults(results);
    } catch (error) {
      console.error("Venue search error:", error);
    }
  }

  displayResults(results) {
    if (results.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500">No venues found</div>
      `;
      this.showResults();
      return;
    }

    this.resultsTarget.innerHTML = results
      .map(
        (result) => `
      <button type="button"
        class="w-full text-left px-4 py-3 hover:bg-blue-50 cursor-pointer border-b border-gray-100 last:border-0"
        data-action="click->venue-search#select"
        data-venue-id="${result.id || ""}"
        data-mapbox-id="${result.mapbox_id}"
        data-name="${this.escapeHtml(result.name)}"
        data-address="${this.escapeHtml(result.address)}"
        data-city="${this.escapeHtml(result.city)}"
        data-latitude="${result.latitude || ""}"
        data-longitude="${result.longitude || ""}"
        data-source="${result.source}">
        <div class="font-medium text-gray-900">${this.escapeHtml(result.name)}</div>
        <div class="text-sm text-gray-500">${this.escapeHtml(result.address)}</div>
        <span class="text-xs px-1.5 py-0.5 rounded ${result.source === "local" ? "bg-green-100 text-green-700" : "bg-blue-100 text-blue-700"}">
          ${result.source === "local" ? "Saved" : "Mapbox"}
        </span>
      </button>
    `
      )
      .join("");

    this.showResults();
  }

  async select(event) {
    const btn = event.currentTarget;
    const source = btn.dataset.source;
    const name = btn.dataset.name;

    if (source === "local" && btn.dataset.venueId) {
      this.setVenue(btn.dataset.venueId, name);
    } else {
      // Create venue from Mapbox result
      const venueData = {
        venue: {
          mapbox_id: btn.dataset.mapboxId,
          name: btn.dataset.name,
          address: btn.dataset.address,
          city: btn.dataset.city,
          latitude: btn.dataset.latitude,
          longitude: btn.dataset.longitude,
        },
      };

      try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        const response = await fetch("/venues", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            "X-CSRF-Token": csrfToken,
          },
          body: JSON.stringify(venueData),
        });

        const venue = await response.json();
        if (venue.id) {
          this.setVenue(venue.id, name);
        } else {
          console.error("Failed to create venue:", venue.errors);
        }
      } catch (error) {
        console.error("Venue creation error:", error);
      }
    }
  }

  setVenue(venueId, name) {
    this.venueIdTarget.value = venueId;
    this.inputTarget.value = name;
    this.selectedVenueTarget.innerHTML = `
      <div class="flex items-center justify-between bg-blue-50 rounded-md px-3 py-2 mt-2">
        <span class="text-sm font-medium text-blue-800">${this.escapeHtml(name)}</span>
        <button type="button" data-action="click->venue-search#clear" class="text-blue-600 hover:text-blue-800 text-sm cursor-pointer">
          Change
        </button>
      </div>
    `;
    this.inputTarget.classList.add("hidden");
    this.hideResults();
  }

  clear() {
    this.venueIdTarget.value = "";
    this.inputTarget.value = "";
    this.inputTarget.classList.remove("hidden");
    this.selectedVenueTarget.innerHTML = "";
    this.inputTarget.focus();
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden");
    this.resultsTarget.innerHTML = "";
  }

  showResults() {
    this.resultsTarget.classList.remove("hidden");
  }

  clickOutside(event) {
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
