const PRODUCT_STATUS_LABELS = {
  0: "Manufactured",
  1: "Quality Checked",
  2: "In Transit to Distributor",
  3: "With Distributor",
  4: "In Transit to Retailer",
  5: "With Retailer",
  6: "Sold",
  7: "Returned",
};

const PRODUCT_STATUS_CLASS = {
  0: "status-pending", // Manufactured
  1: "status-pending", // Quality checked
  2: "status-pending", // Transit to distributor
  3: "status-ok", // With distributor
  4: "status-pending", // Transit to retailer
  5: "status-ok", // With retailer
  6: "status-ok", // Sold
  7: "status-error", // Returned
};

function getProductIdFromPath() {
  // Expecting e.g. /verify/p01
  const parts = window.location.pathname.split("/").filter(Boolean);
  return decodeURIComponent(parts[parts.length - 1] || "");
}

function showElement(id, show) {
  const el = document.getElementById(id);
  if (!el) return;
  el.style.display = show ? "" : "none";
}

function setText(id, text) {
  const el = document.getElementById(id);
  if (el) {
    el.textContent = text != null && text !== "" ? String(text) : "—";
  }
}

function applyStatusStyle(statusIndex, isAuthentic) {
  const el = document.getElementById("statusValue");
  if (!el) return;

  el.classList.remove("status-ok", "status-pending", "status-error");

  if (isAuthentic === false) {
    el.classList.add("status-error");
    return;
  }

  const cls = PRODUCT_STATUS_CLASS[statusIndex];
  if (cls) {
    el.classList.add(cls);
  } else {
    el.classList.add("status-pending");
  }
}

document.addEventListener("DOMContentLoaded", async () => {
  const productIdDisplay = document.getElementById("productIdDisplay");
  const loadingEl = document.getElementById("loading");
  const errorEl = document.getElementById("error");
  const errorMessageEl = document.getElementById("errorMessage");
  const resultEl = document.getElementById("result");

  const productId = getProductIdFromPath();

  if (productIdDisplay) {
    productIdDisplay.textContent = productId || "Unknown";
  }

  showElement("loading", true);
  showElement("error", false);
  showElement("result", false);

  try {
    if (!window.fetchProduct) {
      throw new Error("Blockchain client not initialized.");
    }

    // 1) Fetch on-chain core data
    const core = await window.fetchProduct(productId);
    console.debug("Core product data:", core);

    const statusIndex = core.statusIndex ?? 0;
    const statusLabel =
      PRODUCT_STATUS_LABELS[statusIndex] || `Unknown (${statusIndex})`;

    setText("statusValue", statusLabel);
    setText("authValue", core.isAuthentic ? "Authentic" : "Not authentic");
    setText("manufacturerValue", core.manufacturer);
    setText("ownerValue", core.currentOwner);
    setText("factoryValue", core.factoryId);

    applyStatusStyle(statusIndex, core.isAuthentic);

    // 2) Load metadata (name + images) from Firestore
    if (window.loadProductFromFirestore) {
      await window.loadProductFromFirestore(productId);
    }

    showElement("loading", false);
    showElement("error", false);
    showElement("result", true);
  } catch (err) {
    console.error("Verification error:", err);
    showElement("loading", false);
    showElement("result", false);
    showElement("error", true);
    if (errorMessageEl) {
      errorMessageEl.textContent =
        err && err.message
          ? err.message
          : "There was a problem verifying this product.";
    }
  }
});
