let qrCodeInstance = null;

function generateQR() {
  const productId = document.getElementById("productId").value.trim();

  if (!productId) {
    alert("Please enter a product ID");
    return;
  }

  const qrcodeDiv = document.getElementById("qrcode");
  qrcodeDiv.innerHTML = "";

  const baseUrl = window.location.origin;
  const verifyUrl = `${baseUrl}/verify/${encodeURIComponent(productId)}`;

  qrCodeInstance = new QRCode(qrcodeDiv, {
    text: verifyUrl,
    width: 256,
    height: 256,
    colorDark: "#000000",
    colorLight: "#ffffff",
    correctLevel: QRCode.CorrectLevel.H,
  });

  // Show download button
  document.getElementById("downloadBtn").style.display = "inline-block";
}

// Download QR code as image
function downloadQR() {
  // Get the QR code canvas
  const canvas = document.querySelector("#qrcode canvas");

  if (!canvas) {
    alert("Please generate a QR code first");
    return;
  }

  // Get product ID for filename
  const productId = document.getElementById("productId").value.trim();

  // Convert canvas to image and download
  const url = canvas.toDataURL("image/png");
  const link = document.createElement("a");
  link.download = `qr-${productId}.png`;
  link.href = url;
  link.click();
}

// Allow Enter key to generate QR
document.addEventListener("DOMContentLoaded", function () {
  document
    .getElementById("productId")
    .addEventListener("keypress", function (e) {
      if (e.key === "Enter") {
        generateQR();
      }
    });
});
