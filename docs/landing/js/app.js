/* ═══════════════════════════════════════════════════════════════════════════
   JiveDB — Landing v2 · i18n + theme system + animated app simulations
   ═══════════════════════════════════════════════════════════════════════════ */
(() => {
  "use strict";
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const root = document.documentElement;
  const store = {
    get: (k, d) => {
      try {
        return localStorage.getItem(k) || d;
      } catch {
        return d;
      }
    },
    set: (k, v) => {
      try {
        localStorage.setItem(k, v);
      } catch {
        /* ignore */
      }
    },
  };

  // ── i18n dictionary ───────────────────────────────────────────────────────
  const D = {
    en: {
      nav_editor: "Editor",
      nav_grid: "Data grid",
      nav_customize: "Customize",
      nav_export: "Export",
      nav_feedback: "Feedback",
      nav_engines: "Engines",
      nav_download: "Download free",
      hero_pill: "One native binary · PostgreSQL · MySQL · SQLite · Redis",
      hero_title:
        'One client for <span class="ink">all your <em>databases</em></span>.',
      hero_sub:
        "Browse, query and design across <b>PostgreSQL</b>, <b>MySQL</b>, <b>SQLite</b> and <b>Redis</b> — with a real SQL editor, a fast data grid, live ERD diagrams and a built-in AI assistant.",
      hero_cta1: "Download free",
      hero_cta2: "See it in action ↓",
      stat_engines: "DB engines",
      stat_native: "Native binary",
      stat_kbd: "Keyboard-driven",
      stat_tel: "Telemetry",
      s01_h: "A real <em>SQL editor</em>, not a textarea",
      s01_p:
        "Syntax highlighting, smart autocomplete and multi-statement execution. Run the whole script or just the selection, then read results in a grid that never blocks the UI.",
      s01_t1: "Dialect-aware completion for every engine",
      s01_t2: "Format, explain & optimize in one click",
      s01_t3: "Query history with favorites you can re-run",
      s02_h: "A data grid that <em>flies</em>",
      s02_p:
        "Virtualized rendering keeps millions of rows smooth. Edit inline, copy cells, and commit changes as reviewable SQL — no surprises.",
      s02_t1: "Inline editing with generated UPDATE preview",
      s02_t2: "Sort, filter and paginate instantly",
      s02_t3: "NULL-aware, big-number safe rendering",
      s03_h: "See your schema as an <em>ERD</em>",
      s03_p:
        "Relationships drawn live from your foreign keys. Drag tables, edit structure, and export the diagram as SVG to share with the team.",
      s03_t1: "Auto-layout from real foreign keys",
      s03_t2: "Edit columns, indexes & FKs visually",
      s03_t3: "One-click SVG export",
      s04_h: "An <em>AI assistant</em> that speaks SQL",
      s04_p:
        "Describe what you need in plain language; get back ready-to-run SQL. Explain, fix or optimize a query — bring your own provider and keys.",
      s04_t1: "Natural language → SQL",
      s04_t2: "Explain, fix & optimize inline",
      s04_t3: "Multi-provider, keys encrypted at rest",
      s05_h: "Four engines, <em>one workflow</em>",
      s05_p: "Same tree, same grid, same shortcuts — across every connection.",
      eng_pg: "Schemas, types, JSONB and full metadata tree.",
      eng_my: "Databases, tables, indexes and triggers.",
      eng_lite: "Open a file and go. Pure-Go, zero setup.",
      eng_redis: "Keys, TTLs and value inspection.",
      s06_h: "Make it <em>yours</em>",
      s06_p:
        "Two languages, seven color tones and light or dark — switch live, your choice is remembered.",
      s06_t1: "English & Vietnamese (i18n)",
      s06_t2: "7 accent themes",
      s06_t3: "Light & dark mode",
      s06_try: "Try it — these controls change this page:",
      ctl_lang: "Language",
      ctl_accent: "Accent",
      ctl_light: "Light",
      ctl_dark: "Dark",
      s07_h: "Export <em>anything</em>",
      s07_p:
        "Take your work with you. Diagrams as SVG, result sets as CSV or JSON — one click, native save dialog.",
      s07_t1: "ERD diagram → SVG",
      s07_t2: "Data → CSV",
      s07_t3: "Data → JSON",
      s07_saved: "Saved",
      s08_h: "We're <em>listening</em>",
      s08_p:
        "A rich, built-in feedback system. Reach out for support, share a suggestion, send feedback or ask a question — with screenshots attached.",
      s08_t1: "Support & help",
      s08_t2: "Suggestions",
      s08_t3: "Feedback",
      s08_t4: "Questions",
      type_support: "Support",
      type_suggestion: "Suggestion",
      type_feedback: "Feedback",
      type_question: "Question",
      fb_title_support: "Get support",
      fb_title_suggestion: "Share a suggestion",
      fb_title_feedback: "Send feedback",
      fb_title_question: "Ask a question",
      fb_ph: "Describe it here…",
      fb_attach: "📎 Attach screenshot",
      fb_send: "Send",
      chat_q: "Top 5 customers by total spend this month",
      flow_deliver: "Delivered to you",
      flow_you: "You",
      flow_hub_sub: "One workflow",
      flow_to: "→ JiveDB",
      f1t: "Keyboard-first",
      f1d: "Command palette and shortcuts for everything.",
      f2t: "Native & fast",
      f2d: "One small binary. No Electron, no bloat.",
      f3t: "Private by default",
      f3d: "Local-first. Credentials encrypted at rest.",
      f4t: "Dark & light",
      f4d: "Themes that match your system, instantly.",
      f5t: "Import & export",
      f5d: "CSV, SQL and SVG diagrams in a click.",
      f6t: "Multi-tab",
      f6d: "Run many queries across connections at once.",
      cta_h: "Ready to query?",
      cta_p:
        "One download. PostgreSQL, MySQL, SQLite and Redis — out of the box.",
      cta_b1: "Get JiveDB",
      cta_b2: "Other request",
      dl_title: "Download JiveDB",
      dl_sub: "Free, no sign-up. Choose your platform.",
      dl_mac: "Universal · Apple Silicon & Intel",
      dl_win: "64-bit · Windows 10/11",
      dl_linux: "AppImage · x86_64 & ARM64",
      ct_title: "Get in touch",
      ct_sub: "Questions, partnerships or anything else — send us a note.",
      ct_name: "Your name",
      ct_email: "Email address",
      ct_msg: "How can we help?",
      ct_send: "Send message",
      footer_note:
        "One fast, native client for every database — free, private, and a joy to use.",
    },
    vi: {
      nav_editor: "Trình soạn",
      nav_grid: "Bảng dữ liệu",
      nav_customize: "Tuỳ biến",
      nav_export: "Xuất",
      nav_feedback: "Phản hồi",
      nav_engines: "CSDL",
      nav_download: "Tải miễn phí",
      hero_pill: "Một tệp chạy gốc · PostgreSQL · MySQL · SQLite · Redis",
      hero_title:
        'Một ứng dụng cho <span class="ink">mọi <em>cơ sở dữ liệu</em></span>.',
      hero_sub:
        "Duyệt, truy vấn và thiết kế trên <b>PostgreSQL</b>, <b>MySQL</b>, <b>SQLite</b> và <b>Redis</b> — với trình soạn SQL thực thụ, bảng dữ liệu nhanh, sơ đồ ERD trực tiếp và trợ lý AI tích hợp.",
      hero_cta1: "Tải miễn phí",
      hero_cta2: "Xem thử ↓",
      stat_engines: "Loại CSDL",
      stat_native: "Tệp chạy gốc",
      stat_kbd: "Dùng bàn phím",
      stat_tel: "Theo dõi",
      s01_h: "Trình soạn <em>SQL</em> thực thụ",
      s01_p:
        "Tô màu cú pháp, gợi ý thông minh và chạy nhiều câu lệnh. Chạy cả script hoặc chỉ phần bôi đen, rồi xem kết quả trong bảng không treo giao diện.",
      s01_t1: "Gợi ý theo từng loại CSDL",
      s01_t2: "Format, giải thích & tối ưu một chạm",
      s01_t3: "Lịch sử truy vấn + câu yêu thích chạy lại được",
      s02_h: "Bảng dữ liệu <em>siêu mượt</em>",
      s02_p:
        "Kết xuất ảo giữ hàng triệu dòng mượt mà. Sửa trực tiếp, sao chép ô, và lưu thay đổi dưới dạng SQL xem lại được — không bất ngờ.",
      s02_t1: "Sửa trực tiếp kèm xem trước câu UPDATE",
      s02_t2: "Sắp xếp, lọc và phân trang tức thì",
      s02_t3: "An toàn NULL và số lớn",
      s03_h: "Xem cấu trúc dạng <em>ERD</em>",
      s03_p:
        "Quan hệ vẽ trực tiếp từ khoá ngoại. Kéo bảng, sửa cấu trúc, và xuất sơ đồ ra SVG để chia sẻ cho nhóm.",
      s03_t1: "Tự bố cục từ khoá ngoại thật",
      s03_t2: "Sửa cột, index & khoá ngoại trực quan",
      s03_t3: "Xuất SVG một chạm",
      s04_h: "Trợ lý <em>AI</em> hiểu SQL",
      s04_p:
        "Mô tả nhu cầu bằng ngôn ngữ thường; nhận lại SQL chạy được ngay. Giải thích, sửa hay tối ưu — tự chọn nhà cung cấp và khoá của bạn.",
      s04_t1: "Ngôn ngữ tự nhiên → SQL",
      s04_t2: "Giải thích, sửa & tối ưu ngay",
      s04_t3: "Đa nhà cung cấp, khoá mã hoá khi lưu",
      s05_h: "Bốn CSDL, <em>một quy trình</em>",
      s05_p: "Cùng cây, cùng bảng, cùng phím tắt — trên mọi kết nối.",
      eng_pg: "Schema, kiểu, JSONB và cây metadata đầy đủ.",
      eng_my: "Database, bảng, index và trigger.",
      eng_lite: "Mở một tệp là chạy. Pure-Go, không cấu hình.",
      eng_redis: "Key, TTL và xem giá trị.",
      s06_h: "Tuỳ biến <em>theo bạn</em>",
      s06_p:
        "Hai ngôn ngữ, bảy tông màu và sáng hoặc tối — đổi trực tiếp, lựa chọn được ghi nhớ.",
      s06_t1: "Tiếng Anh & Tiếng Việt (i18n)",
      s06_t2: "7 tông màu nhấn",
      s06_t3: "Chế độ sáng & tối",
      s06_try: "Thử ngay — các nút này đổi chính trang này:",
      ctl_lang: "Ngôn ngữ",
      ctl_accent: "Màu nhấn",
      ctl_light: "Sáng",
      ctl_dark: "Tối",
      s07_h: "Xuất <em>mọi thứ</em>",
      s07_p:
        "Mang theo công việc của bạn. Sơ đồ ra SVG, kết quả ra CSV hoặc JSON — một chạm, hộp lưu gốc.",
      s07_t1: "Sơ đồ ERD → SVG",
      s07_t2: "Dữ liệu → CSV",
      s07_t3: "Dữ liệu → JSON",
      s07_saved: "Đã lưu",
      s08_h: "Chúng tôi <em>lắng nghe</em>",
      s08_p:
        "Hệ thống phản hồi tích hợp phong phú. Liên hệ hỗ trợ, gửi đề xuất, góp ý hoặc đặt câu hỏi — kèm ảnh chụp màn hình.",
      s08_t1: "Hỗ trợ",
      s08_t2: "Đề xuất",
      s08_t3: "Góp ý",
      s08_t4: "Câu hỏi",
      type_support: "Hỗ trợ",
      type_suggestion: "Đề xuất",
      type_feedback: "Góp ý",
      type_question: "Câu hỏi",
      fb_title_support: "Nhận hỗ trợ",
      fb_title_suggestion: "Gửi đề xuất",
      fb_title_feedback: "Gửi góp ý",
      fb_title_question: "Đặt câu hỏi",
      fb_ph: "Mô tả tại đây…",
      fb_attach: "📎 Đính kèm ảnh",
      fb_send: "Gửi",
      chat_q: "Top 5 khách hàng chi tiêu nhiều nhất tháng này",
      flow_deliver: "Trả về cho bạn",
      flow_you: "Bạn",
      flow_hub_sub: "Một quy trình",
      flow_to: "→ JiveDB",
      f1t: "Ưu tiên bàn phím",
      f1d: "Command palette và phím tắt cho mọi thứ.",
      f2t: "Gốc & nhanh",
      f2d: "Một tệp nhỏ. Không Electron, không nặng nề.",
      f3t: "Riêng tư mặc định",
      f3d: "Local-first. Thông tin đăng nhập mã hoá khi lưu.",
      f4t: "Tối & sáng",
      f4d: "Giao diện khớp hệ thống, tức thì.",
      f5t: "Nhập & xuất",
      f5d: "CSV, SQL và sơ đồ SVG chỉ một chạm.",
      f6t: "Nhiều tab",
      f6d: "Chạy nhiều truy vấn trên nhiều kết nối cùng lúc.",
      cta_h: "Sẵn sàng truy vấn?",
      cta_p:
        "Một lần tải. PostgreSQL, MySQL, SQLite và Redis — dùng được ngay.",
      cta_b1: "Tải JiveDB",
      cta_b2: "Yêu cầu khác",
      dl_title: "Tải JiveDB",
      dl_sub: "Miễn phí, không cần đăng ký. Chọn hệ điều hành.",
      dl_mac: "Universal · Apple Silicon & Intel",
      dl_win: "64-bit · Windows 10/11",
      dl_linux: "AppImage · x86_64 & ARM64",
      ct_title: "Liên hệ",
      ct_sub:
        "Câu hỏi, hợp tác hay bất cứ điều gì — gửi lời nhắn cho chúng tôi.",
      ct_name: "Tên của bạn",
      ct_email: "Địa chỉ email",
      ct_msg: "Chúng tôi có thể giúp gì?",
      ct_send: "Gửi lời nhắn",
      footer_note:
        "Một trình khách gốc, nhanh cho mọi cơ sở dữ liệu — miễn phí, riêng tư và cực dễ dùng.",
    },
  };

  // ── State (persisted) ─────────────────────────────────────────────────────
  let lang = D[store.get("jdb-lp-lang", "en")]
    ? store.get("jdb-lp-lang", "en")
    : "en";
  let mode = store.get("jdb-lp-theme", "dark");
  let accent = store.get("jdb-lp-accent", "violet");
  const ACCENTS = {
    indigo: "#6366f1",
    violet: "#8b5cf6",
    emerald: "#10b981",
    rose: "#f43f5e",
    amber: "#f59e0b",
    sky: "#0ea5e9",
    fuchsia: "#d946ef",
  };

  // Apply stored attributes immediately to avoid flash.
  root.setAttribute("data-theme", mode);
  root.setAttribute("data-accent", accent);

  // ── i18n apply ────────────────────────────────────────────────────────────
  function applyLang(l) {
    lang = l;
    root.setAttribute("lang", l);
    const dict = D[l] || D.en;
    $$("[data-i18n]").forEach((el) => {
      const v = dict[el.dataset.i18n];
      if (v != null) el.textContent = v;
    });
    $$("[data-i18n-html]").forEach((el) => {
      const v = dict[el.dataset.i18nHtml];
      if (v != null) el.innerHTML = v;
    });
    $$("[data-i18n-ph]").forEach((el) => {
      const v = dict[el.dataset.i18nPh];
      if (v != null) el.setAttribute("placeholder", v);
    });
    const lb = $("#langBtn");
    if (lb) lb.textContent = l.toUpperCase();
    syncSeg("#langSeg", "lang", l);
    refreshFbTitle();
  }
  const t = (k) => (D[lang] || D.en)[k] || k;

  // ── Theme controls ────────────────────────────────────────────────────────
  function setMode(m) {
    mode = m;
    root.setAttribute("data-theme", m);
    store.set("jdb-lp-theme", m);
    syncSeg("#modeSeg", "mode", m);
  }
  function setAccent(a) {
    accent = a;
    root.setAttribute("data-accent", a);
    store.set("jdb-lp-accent", a);
    $$(".swatch").forEach((s) =>
      s.classList.toggle("is-active", s.dataset.accent === a),
    );
  }
  function setLang(l) {
    store.set("jdb-lp-lang", l);
    applyLang(l);
  }
  function syncSeg(sel, attr, val) {
    $$(sel + " button").forEach((b) =>
      b.classList.toggle("is-active", b.dataset[attr] === val),
    );
  }

  // Build swatches into a container
  function buildSwatches(container, big) {
    if (!container) return;
    container.innerHTML = Object.keys(ACCENTS)
      .map(
        (a) =>
          '<button class="swatch' +
          (big ? "" : "") +
          '" data-accent="' +
          a +
          '" title="' +
          a +
          '" aria-label="' +
          a +
          '" style="background:' +
          ACCENTS[a] +
          '"></button>',
      )
      .join("");
    $$(".swatch", container).forEach((s) =>
      s.addEventListener("click", () => setAccent(s.dataset.accent)),
    );
  }
  buildSwatches($("#swatchesNav"), false);
  buildSwatches($("#swatchesPanel"), true);
  $$(".swatch").forEach((s) =>
    s.classList.toggle("is-active", s.dataset.accent === accent),
  );

  $("#langBtn")?.addEventListener("click", () =>
    setLang(lang === "en" ? "vi" : "en"),
  );
  $("#modeBtn")?.addEventListener("click", () =>
    setMode(mode === "dark" ? "light" : "dark"),
  );
  $$("#langSeg button").forEach((b) =>
    b.addEventListener("click", () => setLang(b.dataset.lang)),
  );
  $$("#modeSeg button").forEach((b) =>
    b.addEventListener("click", () => setMode(b.dataset.mode)),
  );
  syncSeg("#modeSeg", "mode", mode);

  // ── Year + sticky nav + mobile menu ───────────────────────────────────────
  const yr = $("#year");
  if (yr) yr.textContent = new Date().getFullYear();
  const nav = $("#nav");
  const onScroll = () => nav.classList.toggle("is-stuck", window.scrollY > 8);
  onScroll();
  addEventListener("scroll", onScroll, { passive: true });
  const toggle = $("#navToggle"),
    links = $("#navLinks");
  toggle?.addEventListener("click", () => {
    const open = links.classList.toggle("open");
    toggle.setAttribute("aria-expanded", String(open));
  });
  const closeMenu = () => {
    links.classList.remove("open");
    toggle?.setAttribute("aria-expanded", "false");
  };
  $$('#navLinks a[href^="#"]:not([data-open])').forEach((a) =>
    a.addEventListener("click", closeMenu),
  );

  // ── Modals (download · contact) ───────────────────────────────────────────
  function openModal(id) {
    const m = $("#" + id);
    if (!m) return;
    closeMenu();
    m.hidden = false;
    requestAnimationFrame(() => m.classList.add("show"));
    document.body.style.overflow = "hidden";
  }
  function closeModal(m) {
    if (!m) return;
    m.classList.remove("show");
    document.body.style.overflow = "";
    setTimeout(() => {
      m.hidden = true;
    }, 250);
  }
  $$("[data-open]").forEach((b) =>
    b.addEventListener("click", (e) => {
      e.preventDefault();
      openModal(b.dataset.open);
    }),
  );
  $$("[data-close]").forEach((el) =>
    el.addEventListener("click", () => closeModal(el.closest(".modal"))),
  );
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape")
      $$(".modal:not([hidden])").forEach((m) => closeModal(m));
  });
  const ctForm = $("#ctForm");
  ctForm?.addEventListener("submit", (e) => {
    e.preventDefault();
    closeModal($("#contactModal"));
    ctForm.reset();
  });

  // ── SQL highlighter (demo) ────────────────────────────────────────────────
  const KW =
    /\b(select|from|where|order by|group by|left join|join|on|and|or|as|insert|into|values|update|set|create|table|limit|desc|asc|count|sum|avg|distinct)\b/gi;
  function hl(sql) {
    return sql
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/'[^']*'/g, (m) => '<span class="s">' + m + "</span>")
      .replace(/\b(\d+)\b/g, '<span class="n">$1</span>')
      .replace(KW, (m) => '<span class="k">' + m + "</span>");
  }

  // ── Reveal + counters ─────────────────────────────────────────────────────
  const revObs = new IntersectionObserver(
    (es) => {
      es.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add("in");
          revObs.unobserve(e.target);
        }
      });
    },
    { threshold: 0.14 },
  );
  function observeReveals() {
    $$(".reveal").forEach((el) => revObs.observe(el));
  }

  function countUp(el) {
    const to = +el.dataset.count,
      suf = el.dataset.suffix || "";
    if (reduce || to === 0) {
      el.textContent = to + suf;
      return;
    }
    const dur = 1100,
      t0 = performance.now();
    const step = (ts) => {
      const p = Math.min(1, (ts - t0) / dur);
      el.textContent = Math.round(to * (1 - Math.pow(1 - p, 3))) + suf;
      if (p < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }
  const statObs = new IntersectionObserver(
    (es) => {
      es.forEach((e) => {
        if (e.isIntersecting) {
          countUp(e.target);
          statObs.unobserve(e.target);
        }
      });
    },
    { threshold: 0.6 },
  );
  $$(".stats b").forEach((b) => statObs.observe(b));

  // ── Table helpers ─────────────────────────────────────────────────────────
  function tableHTML(cols, rows) {
    const head = cols.map((c) => "<th>" + c + "</th>").join("");
    const body = rows.map((r) => "<tr>" + r.join("") + "</tr>").join("");
    return (
      '<table class="dtable"><thead><tr>' +
      head +
      "</tr></thead><tbody>" +
      body +
      "</tbody></table>"
    );
  }
  function staggerRows(scope) {
    $$("tbody tr", scope).forEach((tr, i) =>
      setTimeout(() => tr.classList.add("show"), reduce ? 0 : 60 * i),
    );
  }

  // ── Hero mini grid ────────────────────────────────────────────────────────
  const heroGrid = $("#heroGrid");
  if (heroGrid) {
    const rows = [
      [
        '<td class="num-cell">1</td>',
        "<td>Ava Chen</td>",
        '<td><span class="pill-tag pill-tag--pro">pro</span></td>',
      ],
      [
        '<td class="num-cell">2</td>',
        "<td>Liam Ng</td>",
        '<td><span class="pill-tag pill-tag--pro">pro</span></td>',
      ],
      [
        '<td class="num-cell">3</td>',
        "<td>Mia Tran</td>",
        '<td><span class="pill-tag pill-tag--pro">pro</span></td>',
      ],
    ];
    heroGrid.innerHTML = tableHTML(["id", "name", "plan"], rows);
    const o = new IntersectionObserver(
      (es) => {
        es.forEach((e) => {
          if (e.isIntersecting) {
            $("#heroApp .win__body")?.classList.add("is-in");
            staggerRows(heroGrid);
            o.disconnect();
          }
        });
      },
      { threshold: 0.3 },
    );
    o.observe($("#heroApp"));
  }

  // ── 01 · Editor ───────────────────────────────────────────────────────────
  const typed = $("#typed"),
    gutter = $("#gutter"),
    runBtn = $("#runBtn"),
    runStatus = $("#runStatus"),
    editorResult = $("#editorResult");
  const SQL =
    "select id, name, email, plan\nfrom users\nwhere plan = 'pro'\norder by created_at desc\nlimit 5;";
  function setGutter(text) {
    const n = text.split("\n").length;
    gutter.innerHTML = Array.from(
      { length: Math.max(1, n) },
      (_, i) => i + 1,
    ).join("<br>");
  }
  async function typeSQL() {
    if (reduce) {
      typed.innerHTML = hl(SQL);
      setGutter(SQL);
      return;
    }
    typed.textContent = "";
    setGutter("");
    for (let i = 0; i <= SQL.length; i++) {
      const slice = SQL.slice(0, i);
      typed.textContent = slice;
      setGutter(slice);
      await sleep(SQL[i - 1] === "\n" ? 90 : 18 + Math.random() * 30);
    }
    typed.innerHTML = hl(SQL);
  }
  async function runQuery() {
    runBtn.classList.add("is-running");
    runStatus.textContent = "running…";
    editorResult.innerHTML = '<div class="result__empty">Executing…</div>';
    await sleep(reduce ? 0 : 620);
    const rows = [
      [
        '<td class="num-cell">1</td>',
        "<td>Ava Chen</td>",
        "<td>ava@acme.io</td>",
        '<td><span class="pill-tag pill-tag--pro">pro</span></td>',
      ],
      [
        '<td class="num-cell">2</td>',
        "<td>Liam Ng</td>",
        "<td>liam@acme.io</td>",
        '<td><span class="pill-tag pill-tag--pro">pro</span></td>',
      ],
      [
        '<td class="num-cell">3</td>',
        "<td>Mia Tran</td>",
        "<td>mia@acme.io</td>",
        '<td><span class="pill-tag pill-tag--pro">pro</span></td>',
      ],
      [
        '<td class="num-cell">4</td>',
        "<td>Noah Le</td>",
        '<td class="null-cell">NULL</td>',
        '<td><span class="pill-tag pill-tag--pro">pro</span></td>',
      ],
      [
        '<td class="num-cell">5</td>',
        "<td>Zoe Pham</td>",
        "<td>zoe@acme.io</td>",
        '<td><span class="pill-tag pill-tag--pro">pro</span></td>',
      ],
    ];
    editorResult.innerHTML = tableHTML(["id", "name", "email", "plan"], rows);
    staggerRows(editorResult);
    runStatus.textContent = "5 rows · 12 ms";
    runBtn.classList.remove("is-running");
  }
  if (typed) {
    runBtn.addEventListener("click", runQuery);
    let played = false;
    const o = new IntersectionObserver(
      async (es) => {
        for (const e of es) {
          if (e.isIntersecting && !played) {
            played = true;
            o.disconnect();
            await typeSQL();
            await sleep(300);
            runQuery();
          }
        }
      },
      { threshold: 0.4 },
    );
    o.observe($("#editor"));
  }

  // ── 02 · Big data grid ────────────────────────────────────────────────────
  const bigrid = $("#bigrid");
  if (bigrid) {
    const names = [
      "Ava Chen",
      "Liam Ng",
      "Mia Tran",
      "Noah Le",
      "Zoe Pham",
      "Eli Vo",
      "Ivy Do",
      "Kai Bui",
      "Lia Ho",
      "Max Ly",
      "Nia Vu",
      "Sam Ha",
    ];
    const plans = ["free", "pro", "team", "pro", "free", "team"];
    const rows = [];
    for (let i = 0; i < 24; i++) {
      const plan = plans[i % plans.length];
      const cls = plan === "free" ? "" : "pill-tag--pro";
      rows.push([
        '<td class="num-cell">' + (1001 + i) + "</td>",
        "<td>" + names[i % names.length] + "</td>",
        "<td>" + (((12 + i * 7) % 90) + 18) + "</td>",
        '<td><span class="pill-tag ' + cls + '">' + plan + "</span></td>",
        "<td>" + (Math.random() * 9000 + 100).toFixed(2) + "</td>",
      ]);
    }
    bigrid.innerHTML = tableHTML(
      ["id", "name", "age", "plan", "balance"],
      rows,
    );
    const o = new IntersectionObserver(
      (es) => {
        es.forEach((e) => {
          if (e.isIntersecting) {
            staggerRows(bigrid);
            o.disconnect();
            if (!reduce)
              setTimeout(() => {
                const cell = $$("tbody tr", bigrid)[2]?.children[1];
                if (cell) {
                  cell.classList.add("cell-edit");
                  cell.textContent = "Mia Tran ✎";
                }
              }, 1900);
          }
        });
      },
      { threshold: 0.25 },
    );
    o.observe(bigrid);
  }

  // ── 03 · ERD (single responsive SVG) ──────────────────────────────────────
  const erd = $("#erdCanvas");
  if (erd) {
    const table = (cls, x, y, title, cols) => {
      let s = '<g class="erd__node ' + cls + '">';
      s +=
        '<rect class="erd-card" x="' +
        x +
        '" y="' +
        y +
        '" width="150" height="96" rx="10"/>';
      s +=
        '<rect x="' +
        (x + 12) +
        '" y="' +
        (y + 12) +
        '" width="9" height="9" rx="2" fill="#10b981"/>';
      s +=
        '<text class="erd-title" x="' +
        (x + 28) +
        '" y="' +
        (y + 21) +
        '">' +
        title +
        "</text>";
      s +=
        '<line class="erd-div" x1="' +
        x +
        '" y1="' +
        (y + 30) +
        '" x2="' +
        (x + 150) +
        '" y2="' +
        (y + 30) +
        '"/>';
      cols.forEach((c, i) => {
        const by = y + 47 + i * 22;
        const tag = c[1];
        const tcls =
          tag === "pk" ? "erd-key" : tag === "fk" ? "erd-fk" : "erd-col";
        s +=
          '<text class="erd-col" x="' +
          (x + 14) +
          '" y="' +
          by +
          '">' +
          c[0] +
          "</text>";
        s +=
          '<text class="' +
          tcls +
          '" x="' +
          (x + 138) +
          '" y="' +
          by +
          '" text-anchor="end">' +
          tag +
          "</text>";
      });
      return s + "</g>";
    };
    erd.innerHTML =
      '<svg viewBox="0 0 520 300" preserveAspectRatio="xMidYMid meet">' +
      '<path class="erd__edge e1" d="M156 104 C 173 104, 173 112, 185 112" />' +
      '<path class="erd__edge e2" d="M335 90 C 350 90, 350 110, 364 110" />' +
      table("n1", 6, 60, "users", [
        ["id", "pk"],
        ["name", "text"],
        ["email", "text"],
      ]) +
      table("n2", 185, 46, "orders", [
        ["id", "pk"],
        ["user_id", "fk"],
        ["total", "num"],
      ]) +
      table("n3", 364, 66, "products", [
        ["id", "pk"],
        ["name", "text"],
        ["price", "num"],
      ]) +
      "</svg>";
    const o = new IntersectionObserver(
      (es) => {
        es.forEach((e) => {
          if (e.isIntersecting) {
            erd.classList.add("is-in");
            o.disconnect();
          }
        });
      },
      { threshold: 0.3 },
    );
    o.observe(erd);
  }

  // ── 04 · AI chat ──────────────────────────────────────────────────────────
  const chat = $("#chat");
  if (chat) {
    async function play() {
      const aiSQL = hl(
        "select c.name, sum(o.total) as spend\nfrom orders o\njoin customers c on c.id = o.user_id\nwhere o.created_at >= date_trunc('month', now())\ngroup by c.name\norder by spend desc\nlimit 5;",
      );
      const add = (cls, html) => {
        const m = document.createElement("div");
        m.className = "msg " + cls;
        m.innerHTML = html;
        chat.appendChild(m);
        requestAnimationFrame(() => m.classList.add("show"));
        return m;
      };
      add("msg--user", t("chat_q"));
      await sleep(reduce ? 0 : 500);
      const tp = add(
        "msg--ai show",
        '<span class="typing"><i></i><i></i><i></i></span>',
      );
      await sleep(reduce ? 0 : 1100);
      tp.remove();
      add(
        "msg--ai",
        '<div class="lbl">✦ JiveDB AI</div>' +
          (lang === "vi" ? "Câu truy vấn:" : "Here is the query:") +
          "<pre>" +
          aiSQL +
          "</pre>",
      );
    }
    const o = new IntersectionObserver(
      (es) => {
        es.forEach((e) => {
          if (e.isIntersecting) {
            play();
            o.disconnect();
          }
        });
      },
      { threshold: 0.4 },
    );
    o.observe(chat);
  }

  // ── 07 · Export demo ──────────────────────────────────────────────────────
  const exportFiles = $("#exportFiles");
  if (exportFiles) {
    const sizes = { svg: "8.4 KB", csv: "2.1 KB", json: "3.6 KB" };
    const seen = new Set();
    function addFile(name, kind) {
      if (seen.has(name)) return;
      seen.add(name);
      const el = document.createElement("div");
      el.className = "xfile";
      el.innerHTML =
        '<span class="xfile__ic xfile__ic--' +
        kind +
        '">' +
        kind.toUpperCase() +
        "</span>" +
        '<span><span class="xfile__name">' +
        name +
        '</span><br><span class="xfile__meta">' +
        sizes[kind] +
        "</span></span>" +
        '<span class="xfile__ok">✓ ' +
        t("s07_saved") +
        "</span>";
      exportFiles.appendChild(el);
      requestAnimationFrame(() => el.classList.add("show"));
    }
    $$(".xbtn").forEach((b) =>
      b.addEventListener("click", () =>
        addFile(b.dataset.file, b.dataset.kind),
      ),
    );
    const o = new IntersectionObserver(
      async (es) => {
        for (const e of es) {
          if (e.isIntersecting) {
            o.disconnect();
            const btns = $$(".xbtn");
            for (const b of btns) {
              addFile(b.dataset.file, b.dataset.kind);
              await sleep(reduce ? 0 : 600);
            }
          }
        }
      },
      { threshold: 0.4 },
    );
    o.observe(exportFiles);
  }

  // ── 08 · Feedback demo ────────────────────────────────────────────────────
  const fbTypes = $("#fbTypes"),
    fbTitle = $("#fbTitle");
  let fbType = "support";
  function refreshFbTitle() {
    if (fbTitle) fbTitle.textContent = t("fb_title_" + fbType);
  }
  if (fbTypes) {
    function setType(type) {
      fbType = type;
      $$("button", fbTypes).forEach((b) =>
        b.classList.toggle("is-active", b.dataset.type === type),
      );
      refreshFbTitle();
    }
    $$("button", fbTypes).forEach((b) =>
      b.addEventListener("click", () => {
        setType(b.dataset.type);
        cycleStop = true;
      }),
    );
    let cycleStop = false;
    const order = ["support", "suggestion", "feedback", "question"];
    let idx = 0;
    const o = new IntersectionObserver(
      (es) => {
        es.forEach((e) => {
          if (e.isIntersecting && !reduce) {
            o.disconnect();
            const tick = () => {
              if (cycleStop) return;
              idx = (idx + 1) % order.length;
              setType(order[idx]);
              setTimeout(tick, 2200);
            };
            setTimeout(tick, 2200);
          }
        });
      },
      { threshold: 0.4 },
    );
    o.observe(fbTypes);
  }

  // ── Features strip ────────────────────────────────────────────────────────
  const featureGrid = $("#featureGrid");
  if (featureGrid) {
    const ic = (p) =>
      '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
      p +
      "</svg>";
    const icons = [
      '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 9h0M11 9h0M15 9h0M7 13h10"/>',
      '<path d="M13 2 3 14h7l-1 8 10-12h-7z"/>',
      '<rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
      '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2"/>',
      '<path d="M12 3v12m0 0 4-4m-4 4-4-4M5 21h14"/>',
      '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 9h18"/>',
    ];
    let html = "";
    for (let i = 1; i <= 6; i++) {
      html +=
        '<div class="fcard reveal"><div class="fcard__ic">' +
        ic(icons[i - 1]) +
        '</div><h3 data-i18n="f' +
        i +
        't"></h3><p data-i18n="f' +
        i +
        'd"></p></div>';
    }
    featureGrid.innerHTML = html;
  }

  // ── 08 · Engines flow (4 drivers → JiveDB → user, with running pointer) ────
  const flow = $("#flowDiagram");
  if (flow) {
    const drivers = [
      { name: "PostgreSQL", cx: 100 },
      { name: "MySQL", cx: 287 },
      { name: "SQLite", cx: 473 },
      { name: "Redis", cx: 660 },
    ];
    // Consistent line icons (inherit accent via .flow-ico stroke)
    const DB_ICO =
      '<ellipse cx="18" cy="8" rx="13" ry="5"/><path d="M5 8 V28 a13 5 0 0 0 26 0 V8"/><path d="M5 18 a13 5 0 0 0 26 0"/>';
    const USER_ICO =
      '<circle cx="18" cy="12" r="7"/><path d="M5 33 a13 12 0 0 1 26 0"/>';
    // JiveDB brand mark (drawn inside the hub)
    const MARK =
      '<path d="M161 165 V347 A95 34 0 0 0 351 347 V165 Z" fill="url(#hubGrad)"/>' +
      '<ellipse cx="256" cy="165" rx="95" ry="34" fill="url(#hubGrad)"/>' +
      '<g fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="6" stroke-linecap="round"><path d="M161 226 A95 34 0 0 0 351 226"/><path d="M161 287 A95 34 0 0 0 351 287"/></g>' +
      '<path d="M372 82 C376 106 388 118 412 122 C388 126 376 138 372 162 C368 138 356 126 332 122 C356 118 368 106 372 82 Z" fill="#FBBF24"/>';

    const driverNode = (d, i) =>
      '<g class="flow-node fn' +
      i +
      '">' +
      '<g class="flow-ico" transform="translate(' +
      (d.cx - 18) +
      ',40)">' +
      DB_ICO +
      "</g>" +
      '<text class="flow-name" x="' +
      d.cx +
      '" y="100" text-anchor="middle">' +
      d.name +
      "</text>" +
      "</g>";

    let svg =
      '<svg viewBox="0 0 760 480" preserveAspectRatio="xMidYMid meet" class="flow-svg">';
    svg +=
      '<defs><linearGradient id="hubGrad" x1="146" y1="110" x2="366" y2="402" gradientUnits="userSpaceOnUse"><stop stop-color="#6366F1"/><stop offset="1" stop-color="#8B5CF6"/></linearGradient></defs>';
    drivers.forEach((d, i) => {
      svg +=
        '<path class="flow-edge e' +
        (i + 1) +
        '" d="M' +
        d.cx +
        " 82 C " +
        d.cx +
        ' 155, 380 185, 380 220"/>';
    });
    svg += '<path class="flow-edge e5" d="M380 336 L380 396" />';
    drivers.forEach((d, i) => {
      svg += driverNode(d, i);
    });
    svg +=
      '<g class="flow-node hub">' +
      '<circle class="flow-hub-glow" cx="380" cy="274" r="54"/>' +
      '<g transform="translate(349,235) scale(0.121)">' +
      MARK +
      "</g>" +
      '<text class="flow-hub-name" x="380" y="310" text-anchor="middle">JiveDB</text>' +
      '<text class="flow-hub-sub" x="380" y="325" text-anchor="middle"><tspan data-i18n="flow_hub_sub">one workflow</tspan></text>' +
      "</g>";
    svg +=
      '<g class="flow-node user">' +
      '<g class="flow-ico" transform="translate(362,398)">' +
      USER_ICO +
      "</g>" +
      '<text class="flow-user" x="380" y="455" text-anchor="middle"><tspan data-i18n="flow_you">You</tspan></text>' +
      "</g>";
    svg += "</svg>";
    flow.innerHTML = svg;

    // Wrap a label in a measured pill badge.
    const SVGNS = "http://www.w3.org/2000/svg";
    const addBadge = (txt) => {
      if (!txt) return;
      const bb = txt.getBBox(), px = 11, py = 5;
      const rect = document.createElementNS(SVGNS, "rect");
      rect.setAttribute("class", "flow-badge");
      rect.setAttribute("x", bb.x - px);
      rect.setAttribute("y", bb.y - py);
      rect.setAttribute("width", bb.width + px * 2);
      rect.setAttribute("height", bb.height + py * 2);
      rect.setAttribute("rx", (bb.height + py * 2) / 2);
      txt.parentNode.insertBefore(rect, txt);
    };
    drivers.forEach((_, i) => addBadge($(".flow-name", $(".fn" + i, flow))));
    addBadge($(".flow-user", flow));

    const groups = drivers.map((_, i) => $(".fn" + i, flow));
    const edges = drivers.map((_, i) => $(".e" + (i + 1), flow));
    const edgeOut = $(".e5", flow);
    const hub = $(".hub", flow),
      user = $(".user", flow);

    function clearOn() {
      groups.forEach((g) => g.classList.remove("is-on"));
      edges.forEach((e) => e.classList.remove("lit"));
      hub.classList.remove("is-on");
      user.classList.remove("is-on");
      edgeOut.classList.remove("lit");
    }

    // Light up each database's path in sequence (driver → JiveDB → you).
    function step(i) {
      clearOn();
      groups[i].classList.add("is-on");
      edges[i].classList.add("lit");
      hub.classList.add("is-on");
      edgeOut.classList.add("lit");
      user.classList.add("is-on");
    }

    const o = new IntersectionObserver(
      (es) => {
        es.forEach((e) => {
          if (e.isIntersecting) {
            flow.classList.add("is-in");
            o.disconnect();
            if (!reduce) {
              let si = 0;
              setTimeout(() => {
                step(0);
                setInterval(() => {
                  si = (si + 1) % drivers.length;
                  step(si);
                }, 1400);
              }, 1300);
            }
          }
        });
      },
      { threshold: 0.3 },
    );
    o.observe(flow);
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  applyLang(lang);
  observeReveals();
})();
