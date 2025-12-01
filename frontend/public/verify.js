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

<<<<<<< HEAD
=======
async function fetchProduct(productId) {
  // const url = `https://api.cse540project.com/${encodeURIComponent(productId)}`;
  // const response = await fetch(url, {
  //   method: "GET",
  //   headers: {
  //     Accept: "application/json",
  //   },
  // });
  // if (!response.ok) {
  //   throw new Error(`Server responded with status ${response.status}`);
  // }
  // return response.json();
  const mockResponse = {
    status: "verified",
    owner: "John Doe",
    ipfsHash: "QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco",
    date: new Date().toISOString(),
  };
  return mockResponse;
}

>>>>>>> a876da6 (Added verification page and web server.)
function showElement(id, show) {
  const el = document.getElementById(id);
  if (!el) return;
  el.style.display = show ? "" : "none";
}

function setText(id, text) {
  const el = document.getElementById(id);
  if (el) {
<<<<<<< HEAD
    el.textContent = text != null && text !== "" ? String(text) : "—";
  }
}

function applyStatusStyle(statusIndex, isAuthentic) {
=======
    el.textContent = text || "—";
  }
}

function applyStatusStyle(statusText) {
>>>>>>> a876da6 (Added verification page and web server.)
  const el = document.getElementById("statusValue");
  if (!el) return;

  el.classList.remove("status-ok", "status-pending", "status-error");

<<<<<<< HEAD
  if (isAuthentic === false) {
    el.classList.add("status-error");
    return;
  }

  const cls = PRODUCT_STATUS_CLASS[statusIndex];
  if (cls) {
    el.classList.add(cls);
  } else {
    el.classList.add("status-pending");
=======
  if (!statusText) {
    return;
  }

  const s = statusText.toLowerCase();

  if (
    s.includes("valid") ||
    s.includes("verified") ||
    s.includes("authentic")
  ) {
    el.classList.add("status-ok");
  } else if (s.includes("pending")) {
    el.classList.add("status-pending");
  } else if (
    s.includes("invalid") ||
    s.includes("fraud") ||
    s.includes("revoked") ||
    s.includes("error")
  ) {
    el.classList.add("status-error");
>>>>>>> a876da6 (Added verification page and web server.)
  }
}

document.addEventListener("DOMContentLoaded", async () => {
  const productIdDisplay = document.getElementById("productIdDisplay");
  const loadingEl = document.getElementById("loading");
  const errorEl = document.getElementById("error");
  const errorMessageEl = document.getElementById("errorMessage");
  const resultEl = document.getElementById("result");

<<<<<<< HEAD
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
=======
  const path = window.location.pathname;
  const productId = path.split("/")[2]; // "ABC123"

  productIdDisplay.textContent = productId || "Unknown";

  try {
    const verifyData = await fetchProduct(productId);

    const statusValue = document.getElementById("statusValue");

    statusValue.textContent = verifyData.status;

    // status pill class
    statusValue.classList.remove("status-ok", "status-pending", "status-error");
    if (verifyData.status === "verified") {
      statusValue.classList.add("status-ok");
    } else if (verifyData.status === "Pending") {
      statusValue.classList.add("status-pending");
    } else {
      statusValue.classList.add("status-error");
    }

    await loadProductFromFirestore(productId);

    loadingEl.style.display = "none";
    errorEl.style.display = "none";
    resultEl.style.display = "block";
  } catch (err) {
    console.error(err);
    loadingEl.style.display = "none";
    resultEl.style.display = "none";
    errorEl.style.display = "block";
    errorMessageEl.textContent =
      err.message || "There was a problem verifying this product.";
>>>>>>> a876da6 (Added verification page and web server.)
  }
});
