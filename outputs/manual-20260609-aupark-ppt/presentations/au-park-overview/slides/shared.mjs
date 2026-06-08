export const C = {
  ink: "#17202A",
  muted: "#5F6C7B",
  line: "#DDE4EC",
  surface: "#FFFFFF",
  soft: "#F5F7FA",
  paper: "#EEF2F6",
  brand: "#0B4F8A",
  brandDark: "#083B68",
  green: "#159A82",
  warn: "#9A6B00",
  code: "#102033",
  navy: "#0F1B2A",
};

export function base(slide, ctx, options = {}) {
  ctx.addShape(slide, { x: 0, y: 0, w: ctx.W, h: ctx.H, fill: options.fill || C.paper });
  ctx.addShape(slide, { x: 0, y: 0, w: ctx.W, h: 18, fill: C.brandDark });
  ctx.addShape(slide, { x: 0, y: 18, w: ctx.W * 0.68, h: 5, fill: C.brand });
  ctx.addShape(slide, { x: ctx.W * 0.68, y: 18, w: ctx.W * 0.32, h: 5, fill: C.green });
}

export function footer(slide, ctx, n) {
  ctx.addText(slide, {
    text: "Au-Park Project Overview",
    x: 56,
    y: 680,
    w: 420,
    h: 24,
    fontSize: 12,
    color: C.muted,
  });
  ctx.addText(slide, {
    text: String(n).padStart(2, "0"),
    x: 1170,
    y: 678,
    w: 54,
    h: 28,
    fontSize: 14,
    bold: true,
    color: C.brand,
    align: "right",
  });
}

export function title(slide, ctx, kicker, heading, sub = "") {
  ctx.addText(slide, {
    text: kicker,
    x: 56,
    y: 58,
    w: 420,
    h: 22,
    fontSize: 12,
    bold: true,
    color: C.green,
  });
  ctx.addText(slide, {
    text: heading,
    x: 56,
    y: 86,
    w: 1040,
    h: 96,
    fontSize: 34,
    bold: true,
    color: C.ink,
    typeface: "Apple SD Gothic Neo",
  });
  if (sub) {
    ctx.addText(slide, {
      text: sub,
      x: 58,
      y: 184,
      w: 880,
      h: 42,
      fontSize: 16,
      color: C.muted,
      typeface: "Apple SD Gothic Neo",
    });
  }
}

export function panel(slide, ctx, x, y, w, h, options = {}) {
  return ctx.addShape(slide, {
    x,
    y,
    w,
    h,
    fill: options.fill || C.surface,
    line: ctx.line(options.line || C.line, options.lineWidth || 1),
  });
}

export function label(slide, ctx, text, x, y, w, h, options = {}) {
  return ctx.addText(slide, {
    text,
    x,
    y,
    w,
    h,
    fontSize: options.fontSize || 16,
    color: options.color || C.ink,
    bold: options.bold || false,
    align: options.align || "left",
    valign: options.valign || "top",
    fill: options.fill || "#00000000",
    insets: options.insets || { left: 0, right: 0, top: 0, bottom: 0 },
    typeface: "Apple SD Gothic Neo",
  });
}

export function pill(slide, ctx, text, x, y, w, options = {}) {
  panel(slide, ctx, x, y, w, 30, {
    fill: options.fill || "#E4EEF8",
    line: options.line || "#D5E5F5",
  });
  label(slide, ctx, text, x + 10, y + 6, w - 20, 18, {
    fontSize: 11,
    bold: true,
    color: options.color || C.brand,
  });
}

export function card(slide, ctx, x, y, w, h, heading, body, tags = [], options = {}) {
  panel(slide, ctx, x, y, w, h, options);
  label(slide, ctx, heading, x + 18, y + 17, w - 36, 28, {
    fontSize: 18,
    bold: true,
    color: options.headingColor || C.ink,
  });
  label(slide, ctx, body, x + 18, y + 52, w - 36, h - 90, {
    fontSize: 14,
    color: options.bodyColor || C.muted,
  });
  let tagX = x + 18;
  for (const tag of tags) {
    const tagW = Math.max(52, tag.length * 9 + 22);
    pill(slide, ctx, tag, tagX, y + h - 42, tagW, options.tag || {});
    tagX += tagW + 8;
  }
}

export function metric(slide, ctx, x, y, w, h, value, caption, options = {}) {
  panel(slide, ctx, x, y, w, h, { fill: options.fill || C.surface, line: options.line || C.line });
  label(slide, ctx, value, x + 18, y + 15, w - 36, 42, {
    fontSize: options.valueSize || 31,
    bold: true,
    color: options.color || C.brand,
  });
  label(slide, ctx, caption, x + 18, y + 60, w - 36, 36, {
    fontSize: 13,
    color: C.muted,
  });
}

export function node(slide, ctx, text, x, y, w, h, options = {}) {
  panel(slide, ctx, x, y, w, h, {
    fill: options.fill || C.surface,
    line: options.line || C.line,
    lineWidth: options.lineWidth || 1,
  });
  label(slide, ctx, text, x + 12, y + 12, w - 24, h - 24, {
    fontSize: options.fontSize || 15,
    bold: options.bold || true,
    color: options.color || C.ink,
    align: "center",
    valign: "middle",
  });
}

export function arrowText(slide, ctx, text, x, y, w = 52) {
  label(slide, ctx, text || "→", x, y, w, 30, {
    fontSize: 22,
    bold: true,
    color: C.brand,
    align: "center",
    valign: "middle",
  });
}

export function bullets(slide, ctx, items, x, y, w, options = {}) {
  const gap = options.gap || 38;
  items.forEach((item, index) => {
    const top = y + index * gap;
    ctx.addShape(slide, { x, y: top + 8, w: 8, h: 8, fill: options.dot || C.green });
    label(slide, ctx, item, x + 18, top, w - 18, gap - 2, {
      fontSize: options.fontSize || 15,
      color: options.color || C.ink,
    });
  });
}

export function code(slide, ctx, text, x, y, w, h) {
  panel(slide, ctx, x, y, w, h, { fill: C.navy, line: C.navy });
  label(slide, ctx, text, x + 18, y + 15, w - 36, h - 30, {
    fontSize: 13,
    color: "#EAF2FF",
    typeface: "Menlo",
  });
}

export function tableRow(slide, ctx, y, cells, widths, options = {}) {
  let x = options.x || 56;
  cells.forEach((cell, index) => {
    const w = widths[index];
    panel(slide, ctx, x, y, w, options.h || 50, {
      fill: options.fill || C.surface,
      line: C.line,
    });
    label(slide, ctx, cell, x + 12, y + 11, w - 24, (options.h || 50) - 16, {
      fontSize: options.fontSize || 13,
      bold: options.bold || false,
      color: options.color || C.ink,
    });
    x += w;
  });
}
