// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

document.addEventListener("turbo:load", () => {
  const notice = document.getElementById("notice");
  if (notice) {
    setTimeout(() => {
      notice.style.transition = "opacity 0.5s ease";
      notice.style.opacity = "0";
      setTimeout(() => notice.remove(), 500);
    }, 2000);
  }
});
