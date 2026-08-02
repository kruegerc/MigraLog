const STORAGE_KEY = "migralog.web.entries.v1";

const options = {
  painTypes: ["Pulsierend", "Stechend", "Drückend", "Einseitig links", "Einseitig rechts", "Beidseitig"],
  locations: ["Stirn", "Schläfen", "Hinterkopf", "Nacken", "Auge", "Kiefer"],
  symptoms: ["Übelkeit", "Lichtempfindlichkeit", "Lärmempfindlichkeit", "Sehstörung", "Schwindel", "Müdigkeit"],
  triggers: ["Stress", "Schlafmangel", "Wetter", "Unbekannt", "Alkohol", "Zyklus", "Bildschirm", "Ausgelassene Mahlzeit"]
};

const effectTitles = {
  notRecorded: "Nicht erfasst",
  none: "Keine Wirkung",
  slight: "Leichte Wirkung",
  good: "Gute Wirkung",
  complete: "Beschwerdefrei"
};

const state = {
  entries: loadEntries(),
  activeView: "diary",
  editingId: null,
  draft: null
};

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];

const elements = {
  entryList: $("#entryList"),
  historyList: $("#historyList"),
  statsCards: $("#statsCards"),
  entryDialog: $("#entryDialog"),
  entryForm: $("#entryForm"),
  editorTitle: $("#editorTitle"),
  statsPeriod: $("#statsPeriod"),
  statsStart: $("#statsStart"),
  statsEnd: $("#statsEnd"),
  statsCustomRange: $("#statsCustomRange"),
  exportPeriod: $("#exportPeriod"),
  exportStart: $("#exportStart"),
  exportEnd: $("#exportEnd"),
  exportCustomRange: $("#exportCustomRange"),
  exportCount: $("#exportCount")
};

init();

function init() {
  setDefaultDates();
  buildPickers();
  bindEvents();
  render();
  registerServiceWorker();
}

function bindEvents() {
  $("#addEntryTop").addEventListener("click", () => openEditor());
  $("#cancelEntry").addEventListener("click", closeEditor);
  elements.entryForm.addEventListener("submit", saveEditor);
  $("#hasEnded").addEventListener("change", (event) => {
    $("#endedFields").classList.toggle("hidden", !event.target.checked);
  });

  $$(".tab").forEach((button) => {
    button.addEventListener("click", () => switchView(button.dataset.view));
  });

  $$(".segment").forEach((button) => {
    button.addEventListener("click", () => switchEditorTab(button.dataset.editorTab));
  });

  [elements.statsPeriod, elements.statsStart, elements.statsEnd].forEach((element) => {
    element.addEventListener("change", renderStats);
  });
  [elements.exportPeriod, elements.exportStart, elements.exportEnd].forEach((element) => {
    element.addEventListener("change", renderExportCount);
  });

  $("#printReport").addEventListener("click", printReport);
  $("#downloadCsv").addEventListener("click", downloadCsv);
  $("#downloadBackup").addEventListener("click", downloadBackup);
  $("#importBackup").addEventListener("change", importBackup);
  $("#deleteAll").addEventListener("click", deleteAllEntries);
}

function switchView(view) {
  state.activeView = view;
  $$(".view").forEach((section) => section.classList.remove("active"));
  $(`#view-${view}`).classList.add("active");
  $$(".tab").forEach((tab) => tab.classList.toggle("active", tab.dataset.view === view));
  render();
}

function switchEditorTab(tab) {
  $$(".segment").forEach((button) => button.classList.toggle("active", button.dataset.editorTab === tab));
  $$(".editor-page").forEach((page) => page.classList.remove("active"));
  $(`#editor-${tab}`).classList.add("active");
}

function buildPickers() {
  const intensityPicker = $("#intensityPicker");
  intensityPicker.innerHTML = "";
  for (let value = 0; value <= 10; value += 1) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "intensity-button";
    button.textContent = value;
    button.dataset.value = String(value);
    button.style.setProperty("--level-color", intensityColor(value));
    button.addEventListener("click", () => {
      state.draft.intensity = value;
      renderIntensityPicker();
    });
    intensityPicker.append(button);
  }

  buildChoicePicker("#painTypePicker", "painTypes", options.painTypes);
  buildChoicePicker("#locationPicker", "locations", options.locations);
  buildChoicePicker("#symptomPicker", "symptoms", options.symptoms);
  buildChoicePicker("#triggerPicker", "triggers", options.triggers);
}

function buildChoicePicker(selector, draftKey, values) {
  const container = $(selector);
  container.innerHTML = "";
  values.forEach((value) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "choice";
    button.textContent = value;
    button.dataset.value = value;
    button.addEventListener("click", () => {
      toggleDraftValue(draftKey, value);
      renderChoicePicker(selector, draftKey);
    });
    container.append(button);
  });
}

function toggleDraftValue(key, value) {
  const current = new Set(state.draft[key]);
  if (current.has(value)) current.delete(value);
  else current.add(value);
  state.draft[key] = [...current];
}

function openEditor(entry = null) {
  state.editingId = entry?.id ?? null;
  state.draft = entry ? structuredClone(entry) : createDraft();
  elements.editorTitle.textContent = entry ? "Eintrag bearbeiten" : "Neuer Eintrag";
  fillEditorFields();
  switchEditorTab("basic");
  elements.entryDialog.showModal();
}

function closeEditor() {
  elements.entryDialog.close();
  state.editingId = null;
  state.draft = null;
}

function createDraft() {
  const now = new Date();
  return {
    id: crypto.randomUUID(),
    startedAt: now.toISOString(),
    endedAt: null,
    intensity: 5,
    painTypes: [],
    locations: [],
    symptoms: [],
    triggers: [],
    medications: "Rizatriptan 10 mg",
    medicationEffect: "notRecorded",
    notes: "",
    createdAt: now.toISOString(),
    updatedAt: now.toISOString()
  };
}

function fillEditorFields() {
  const started = new Date(state.draft.startedAt);
  $("#startedDate").value = toDateInput(started);
  $("#startedTime").value = toTimeInput(started);
  $("#hasEnded").checked = Boolean(state.draft.endedAt);
  $("#endedFields").classList.toggle("hidden", !state.draft.endedAt);
  const ended = state.draft.endedAt ? new Date(state.draft.endedAt) : new Date();
  $("#endedDate").value = toDateInput(ended);
  $("#endedTime").value = toTimeInput(ended);
  $("#medications").value = state.draft.medications;
  $("#medicationEffect").value = state.draft.medicationEffect;
  $("#notes").value = state.draft.notes;
  renderIntensityPicker();
  renderAllChoicePickers();
}

function readEditorFields() {
  const startedAt = fromDateAndTime($("#startedDate").value, $("#startedTime").value);
  const hasEnded = $("#hasEnded").checked;
  const endedAt = hasEnded ? fromDateAndTime($("#endedDate").value, $("#endedTime").value) : null;
  return {
    ...state.draft,
    startedAt: startedAt.toISOString(),
    endedAt: endedAt?.toISOString() ?? null,
    medications: $("#medications").value.trim(),
    medicationEffect: $("#medicationEffect").value,
    notes: $("#notes").value.trim(),
    updatedAt: new Date().toISOString()
  };
}

function saveEditor(event) {
  event.preventDefault();
  const entry = readEditorFields();
  if (state.editingId) {
    state.entries = state.entries.map((item) => item.id === state.editingId ? entry : item);
  } else {
    state.entries = [entry, ...state.entries];
  }
  persistEntries();
  closeEditor();
  render();
}

function renderIntensityPicker() {
  $$(".intensity-button").forEach((button) => {
    button.classList.toggle("selected", Number(button.dataset.value) === state.draft.intensity);
  });
}

function renderAllChoicePickers() {
  renderChoicePicker("#painTypePicker", "painTypes");
  renderChoicePicker("#locationPicker", "locations");
  renderChoicePicker("#symptomPicker", "symptoms");
  renderChoicePicker("#triggerPicker", "triggers");
}

function renderChoicePicker(selector, key) {
  const selected = new Set(state.draft[key]);
  $$(`${selector} .choice`).forEach((button) => {
    button.classList.toggle("selected", selected.has(button.dataset.value));
  });
}

function render() {
  renderDiary();
  renderHistory();
  renderStats();
  renderExportCount();
}

function renderDiary() {
  const sorted = sortedEntriesDesc(state.entries);
  elements.entryList.innerHTML = "";
  if (!sorted.length) {
    elements.entryList.append(emptyState());
    return;
  }
  sorted.forEach((entry) => elements.entryList.append(entryCard(entry)));
}

function renderHistory() {
  elements.historyList.innerHTML = "";
  const sorted = sortedEntriesDesc(state.entries);
  if (!sorted.length) {
    elements.historyList.append(emptyState("Noch kein Verlauf", "Der Verlauf erscheint nach dem ersten Eintrag."));
    return;
  }

  const months = groupBy(sorted, (entry) => monthKey(entry.startedAt));
  Object.entries(months).forEach(([key, entries]) => {
    const monthTitle = document.createElement("h3");
    monthTitle.className = "month-title";
    monthTitle.textContent = formatMonth(key);
    elements.historyList.append(monthTitle);

    const days = groupBy(entries, (entry) => dateKey(entry.startedAt));
    Object.entries(days).forEach(([day, dayEntries]) => {
      const group = document.createElement("div");
      group.className = "day-group stack small";
      group.innerHTML = `<div class="day-header"><strong>${formatFullDate(day)}</strong><span class="muted">${dayEntries.length} Einträge</span></div>`;
      dayEntries.forEach((entry) => group.append(entryCard(entry)));
      elements.historyList.append(group);
    });
  });
}

function entryCard(entry) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "entry-card";
  const color = intensityColor(entry.intensity);
  button.innerHTML = `
    <span class="intensity-badge" style="--badge-color: ${color}">${entry.intensity}</span>
    <span class="entry-main">
      <span class="entry-title">${formatDateTime(entry.startedAt)}</span>
      <span class="entry-meta">Dauer: ${formatDuration(entry.startedAt, entry.endedAt)}</span>
      <span class="entry-summary">${escapeHtml(summaryText(entry))}</span>
    </span>
    <span class="chevron">›</span>
  `;
  button.addEventListener("click", () => openEditor(entry));
  return button;
}

function emptyState(title = "Noch keine Einträge", text = "Lege die erste Kopfschmerzepisode an.") {
  const node = $("#emptyTemplate").content.firstElementChild.cloneNode(true);
  node.querySelector("strong").textContent = title;
  node.querySelector("p").textContent = text;
  node.querySelector("button").addEventListener("click", () => openEditor());
  return node;
}

function renderStats() {
  elements.statsCustomRange.classList.toggle("hidden", elements.statsPeriod.value !== "custom");
  const entries = filterByPeriod(state.entries, elements.statsPeriod.value, elements.statsStart.value, elements.statsEnd.value);
  const cards = [
    ["Einträge", String(entries.length)],
    ["Kopfschmerztage", String(new Set(entries.map((entry) => dateKey(entry.startedAt))).size)],
    ["Ø Intensität", averageIntensity(entries)],
    ["Ø Dauer", averageDuration(entries)],
    ["Häufigste Schmerzart", mostFrequent(entries.flatMap((entry) => entry.painTypes))],
    ["Häufigste Symptome", mostFrequent(entries.flatMap((entry) => entry.symptoms))],
    ["Häufigste Auslöser", mostFrequent(entries.flatMap((entry) => entry.triggers))],
    ["Zeitraum", periodLabel(elements.statsPeriod.value, elements.statsStart.value, elements.statsEnd.value)]
  ];
  elements.statsCards.innerHTML = cards.map(([label, value]) => `
    <article class="stat-card">
      <p class="stat-label">${label}</p>
      <p class="stat-value">${escapeHtml(value)}</p>
    </article>
  `).join("");
}

function renderExportCount() {
  elements.exportCustomRange.classList.toggle("hidden", elements.exportPeriod.value !== "custom");
  const entries = exportEntries();
  elements.exportCount.textContent = `${entries.length} Einträge im Export`;
}

function exportEntries() {
  return sortedEntriesAsc(filterByPeriod(state.entries, elements.exportPeriod.value, elements.exportStart.value, elements.exportEnd.value));
}

function downloadCsv() {
  const entries = exportEntries();
  if (!entries.length) return;
  const rows = [
    ["MigraLog Export"],
    ["Zeitraum", periodLabel(elements.exportPeriod.value, elements.exportStart.value, elements.exportEnd.value)],
    ["Erstellt am", formatDateTime(new Date().toISOString())],
    ["Anzahl Einträge", String(entries.length)],
    [],
    ["Beginn", "Ende", "Dauer", "Intensität", "Schmerzart", "Lokalisation", "Symptome", "Auslöser", "Medikamente", "Wirkung", "Notiz"],
    ...entries.map((entry) => [
      formatDateTime(entry.startedAt),
      entry.endedAt ? formatDateTime(entry.endedAt) : "Offen",
      formatDuration(entry.startedAt, entry.endedAt),
      `${entry.intensity}/10`,
      entry.painTypes.join(", "),
      entry.locations.join(", "),
      entry.symptoms.join(", "),
      entry.triggers.join(", "),
      entry.medications,
      effectTitles[entry.medicationEffect] ?? "Nicht erfasst",
      entry.notes
    ])
  ];
  downloadText("MigraLog-Rohdaten.csv", rows.map(csvRow).join("\n"), "text/csv;charset=utf-8");
}

function printReport() {
  const entries = exportEntries();
  if (!entries.length) return;
  const report = window.open("", "migralog-report");
  if (!report) return;
  report.document.write(reportHtml(entries));
  report.document.close();
  report.focus();
  setTimeout(() => report.print(), 250);
}

function reportHtml(entries) {
  const rows = entries.map((entry, index) => `
    <tr>
      <td>${index + 1}</td>
      <td>${formatDateTime(entry.startedAt)}</td>
      <td>${entry.endedAt ? formatDateTime(entry.endedAt) : "Offen"}</td>
      <td>${formatDuration(entry.startedAt, entry.endedAt)}</td>
      <td>${entry.intensity}/10</td>
      <td>${escapeHtml(entry.painTypes.join(", ") || "Nicht erfasst")}</td>
      <td>${escapeHtml(entry.locations.join(", ") || "Nicht erfasst")}</td>
      <td>${escapeHtml(entry.symptoms.join(", ") || "Nicht erfasst")}</td>
      <td>${escapeHtml(entry.triggers.join(", ") || "Nicht erfasst")}</td>
      <td>${escapeHtml(effectTitles[entry.medicationEffect] ?? "Nicht erfasst")}</td>
    </tr>`).join("");

  const details = entries.map((entry, index) => `
    <section class="detail">
      <h2>Eintrag ${index + 1}</h2>
      <p><strong>Beginn:</strong> ${formatDateTime(entry.startedAt)}</p>
      <p><strong>Ende:</strong> ${entry.endedAt ? formatDateTime(entry.endedAt) : "Offen"}</p>
      <p><strong>Medikamente:</strong> ${escapeHtml(entry.medications || "Nicht erfasst")}</p>
      <p><strong>Notiz:</strong> ${escapeHtml(entry.notes || "Nicht erfasst")}</p>
    </section>`).join("");

  return `<!doctype html><html lang="de"><head><meta charset="utf-8"><title>MigraLog Arztbericht</title>
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; color: #111; }
      h1 { margin-bottom: 4px; }
      .meta { color: #555; margin-bottom: 18px; }
      table { width: 100%; border-collapse: collapse; font-size: 10px; }
      th, td { border: 1px solid #ccc; padding: 5px; text-align: left; vertical-align: top; }
      th { background: #eee; }
      .detail { page-break-inside: avoid; margin-top: 18px; }
      @page { size: A4 landscape; margin: 12mm; }
    </style></head><body>
    <h1>MigraLog Arztbericht</h1>
    <p class="meta">Zeitraum: ${periodLabel(elements.exportPeriod.value, elements.exportStart.value, elements.exportEnd.value)} | Erstellt am ${formatDateTime(new Date().toISOString())} | Einträge: ${entries.length}</p>
    <table><thead><tr><th>Nr.</th><th>Beginn</th><th>Ende</th><th>Dauer</th><th>Int.</th><th>Art</th><th>Ort</th><th>Symptome</th><th>Auslöser</th><th>Wirkung</th></tr></thead><tbody>${rows}</tbody></table>
    <h1>Detailangaben</h1>${details}</body></html>`;
}

function downloadBackup() {
  const backup = JSON.stringify({ app: "MigraLog Web", version: 1, exportedAt: new Date().toISOString(), entries: state.entries }, null, 2);
  downloadText("MigraLog-Backup.json", backup, "application/json;charset=utf-8");
}

async function importBackup(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  const text = await file.text();
  try {
    const parsed = JSON.parse(text);
    if (!Array.isArray(parsed.entries)) throw new Error("Ungültige Backup-Datei");
    if (!confirm("Bestehende Daten durch dieses Backup ersetzen?")) return;
    state.entries = parsed.entries;
    persistEntries();
    render();
  } catch {
    alert("Das Backup konnte nicht gelesen werden.");
  } finally {
    event.target.value = "";
  }
}

function deleteAllEntries() {
  if (!state.entries.length) return;
  if (!confirm("Alle Einträge endgültig löschen?")) return;
  state.entries = [];
  persistEntries();
  render();
}

function filterByPeriod(entries, period, startValue, endValue) {
  const now = new Date();
  let start = null;
  let end = now;
  if (period === "all") return entries;
  if (["7", "30", "90"].includes(period)) {
    start = startOfDay(addDays(now, -(Number(period) - 1)));
  } else if (period === "year") {
    start = new Date(now.getFullYear(), 0, 1);
  } else if (period === "custom") {
    start = startOfDay(parseDateInput(startValue));
    end = endOfDay(parseDateInput(endValue));
    if (start > end) [start, end] = [end, start];
  }
  return entries.filter((entry) => {
    const date = new Date(entry.startedAt);
    return date >= start && date <= end;
  });
}

function periodLabel(period, startValue, endValue) {
  if (period === "all") return "Alle Einträge";
  if (period === "7") return "Letzte 7 Tage";
  if (period === "30") return "Letzte 30 Tage";
  if (period === "90") return "Letzte 90 Tage";
  if (period === "year") return "Dieses Jahr";
  return `${formatDate(startValue)} - ${formatDate(endValue)}`;
}

function loadEntries() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function persistEntries() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state.entries));
}

function sortedEntriesDesc(entries) {
  return [...entries].sort((a, b) => new Date(b.startedAt) - new Date(a.startedAt));
}

function sortedEntriesAsc(entries) {
  return [...entries].sort((a, b) => new Date(a.startedAt) - new Date(b.startedAt));
}

function averageIntensity(entries) {
  if (!entries.length) return "-";
  const value = entries.reduce((sum, entry) => sum + Number(entry.intensity), 0) / entries.length;
  return value.toFixed(1).replace(".", ",");
}

function averageDuration(entries) {
  const durations = entries.filter((entry) => entry.endedAt).map((entry) => new Date(entry.endedAt) - new Date(entry.startedAt));
  if (!durations.length) return "-";
  const average = durations.reduce((sum, value) => sum + value, 0) / durations.length;
  return formatMinutes(Math.max(0, Math.round(average / 60000)));
}

function mostFrequent(values) {
  if (!values.length) return "-";
  const counts = new Map();
  values.forEach((value) => counts.set(value, (counts.get(value) ?? 0) + 1));
  return [...counts.entries()].sort((a, b) => b[1] - a[1])[0][0];
}

function summaryText(entry) {
  const pain = entry.painTypes.length ? entry.painTypes.join(", ") : "Schmerzart nicht erfasst";
  const triggers = entry.triggers.length ? ` · ${entry.triggers.join(", ")}` : "";
  return `${pain}${triggers}`;
}

function intensityColor(value) {
  if (value <= 2) return "#0f766e";
  if (value <= 5) return "#c2410c";
  if (value <= 8) return "#dc2626";
  return "#7e22ce";
}

function formatDateTime(value) {
  return new Intl.DateTimeFormat("de-DE", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
}

function formatDate(value) {
  return new Intl.DateTimeFormat("de-DE", { dateStyle: "medium" }).format(parseDateInput(value));
}

function formatFullDate(value) {
  return new Intl.DateTimeFormat("de-DE", { dateStyle: "full" }).format(parseDateInput(value));
}

function formatMonth(month) {
  const [year, number] = month.split("-").map(Number);
  return new Intl.DateTimeFormat("de-DE", { month: "long", year: "numeric" }).format(new Date(year, number - 1, 1));
}

function formatDuration(start, end) {
  if (!end) return "Offen";
  const minutes = Math.max(0, Math.round((new Date(end) - new Date(start)) / 60000));
  return formatMinutes(minutes);
}

function formatMinutes(minutes) {
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return hours ? `${hours} h ${rest} min` : `${rest} min`;
}

function dateKey(value) {
  return toDateInput(new Date(value));
}

function monthKey(value) {
  const date = new Date(value);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function toDateInput(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function toTimeInput(date) {
  return `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
}

function fromDateAndTime(date, time) {
  const [year, month, day] = date.split("-").map(Number);
  const [hour, minute] = time.split(":").map(Number);
  return new Date(year, month - 1, day, hour, minute);
}

function parseDateInput(value) {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, month - 1, day);
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function endOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999);
}

function addDays(date, days) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

function groupBy(values, keyFn) {
  return values.reduce((groups, value) => {
    const key = keyFn(value);
    groups[key] = groups[key] ?? [];
    groups[key].push(value);
    return groups;
  }, {});
}

function csvRow(values) {
  return values.map((value) => `"${String(value ?? "").replaceAll('"', '""')}"`).join(";");
}

function downloadText(filename, text, type) {
  const blob = new Blob([text], { type });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

function escapeHtml(value) {
  return String(value).replace(/[&<>'"]/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "'": "&#39;",
    '"': "&quot;"
  })[char]);
}

function setDefaultDates() {
  const now = new Date();
  const start = addDays(now, -30);
  [elements.statsStart, elements.exportStart].forEach((element) => element.value = toDateInput(start));
  [elements.statsEnd, elements.exportEnd].forEach((element) => element.value = toDateInput(now));
}

function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) return;
  navigator.serviceWorker.register("service-worker.js").catch(() => {});
}
