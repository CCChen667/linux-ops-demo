const healthStatus = document.querySelector("#health-status");
const responseTime = document.querySelector("#response-time");
const checkTime = document.querySelector("#check-time");
const healthDot = document.querySelector(".health-dot");

function setCheckTime() {
  checkTime.textContent = new Intl.DateTimeFormat("zh-CN", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).format(new Date());
}

async function checkHealth() {
  const startedAt = performance.now();

  try {
    const response = await fetch(`/health?t=${Date.now()}`, { cache: "no-store" });
    const body = await response.json();
    const elapsed = Math.max(1, Math.round(performance.now() - startedAt));

    if (!response.ok || body.status !== "ok") throw new Error("Unhealthy response");

    healthStatus.textContent = "在线";
    responseTime.textContent = `${elapsed} ms`;
    healthDot.classList.remove("offline");
    healthDot.classList.add("online");
  } catch (_error) {
    healthStatus.textContent = "暂不可用";
    responseTime.textContent = "-- ms";
    healthDot.classList.remove("online");
    healthDot.classList.add("offline");
  }

  setCheckTime();
}

const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.12 },
);

document.querySelectorAll(".reveal").forEach((element) => observer.observe(element));
document.querySelector("#year").textContent = new Date().getFullYear();
checkHealth();
setInterval(checkHealth, 30_000);
