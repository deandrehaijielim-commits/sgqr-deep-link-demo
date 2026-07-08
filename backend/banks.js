// Shared bank config — these must match the Flutter flavors' custom URL schemes
// (see flutter_bank_template/flavors.md) and Android intent-filter hosts.
const BANKS = [
  { id: "bankA", name: "Bank A", scheme: "bankademo", color: "#e63946" },
  { id: "bankB", name: "Bank B", scheme: "bankbdemo", color: "#1d3557" },
  { id: "bankC", name: "Bank C", scheme: "bankcdemo", color: "#2a9d8f" },
];

module.exports = { BANKS };
