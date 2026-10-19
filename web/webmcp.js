// WebMCP tool registration for Temida. Loaded by auth.js only after a real
// session exists, so the tools can never expose case prose to a signed-out page.
//
// ponytail: read tools read the same globals the renderers read, and the one
// write tool clicks the real checklist row. Deliberately no delete tools --
// case data is never removed from this app, by anything.
(function () {
  const mc = document.modelContext;
  if (!mc?.registerTool) return; // browser without WebMCP support

  const CASE_IDS = ['rcmp', 'family', 'muni', 'bylaw'];
  const CASE_ID = { type: 'string', enum: CASE_IDS, description: 'Case to read; defaults to the one currently open' };

  // The renderers keep case state in module scope; these are the accessors
  // script.js exposes for exactly this reason.
  const cases = () => window.briefCases();
  const active = () => window.briefActiveCase();
  const pick = (id) => cases()[id && CASE_IDS.includes(id) ? id : active()];

  const TOOLS = [
    // ---- read-only -------------------------------------------------------
    {
      name: 'list_cases',
      description: 'List the cases in this brief with their file numbers and titles.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => ({
        active: active(),
        cases: Object.entries(cases()).map(([id, c]) => ({ id, file: c.file, title: c.title })),
      }),
    },
    {
      name: 'get_case',
      description: 'Get one case: its grounds, settlement scenarios, damage heads, timeline and counsel.',
      inputSchema: { type: 'object', properties: { caseId: CASE_ID } },
      execute: async ({ caseId } = {}) => {
        const c = pick(caseId);
        return {
          file: c.file, title: c.title,
          grounds: c.grounds, scenarios: c.scenarios, stack: c.stack,
          timeline: c.timeline, lawyers: c.lawyers,
        };
      },
    },
    {
      name: 'get_call_script',
      description: 'Get the prepared call script for a case.',
      inputSchema: { type: 'object', properties: { caseId: CASE_ID } },
      execute: async ({ caseId } = {}) => ({ script: pick(caseId).script }),
    },
    {
      name: 'get_checklist',
      description: 'Get the evidence checklist for the open case, with each item\'s completion state, leverage value and priority.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => ({ caseId: active(), items: window.briefChecklist() }),
    },
    {
      name: 'get_leverage',
      description: 'Get the current leverage projection: evidence gathered, counsel status and the projected total.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => window.briefLeverage(),
    },

    // ---- reversible state changes ----------------------------------------
    {
      name: 'set_checklist_item',
      description: 'Mark an evidence checklist item done or not done. Recomputes the leverage projection.',
      inputSchema: {
        type: 'object',
        properties: {
          index: { type: 'number', description: 'Item index from get_checklist' },
          done: { type: 'boolean', description: 'true to mark gathered' },
        },
        required: ['index', 'done'],
      },
      execute: async ({ index, done }) => window.briefSetChecklistItem(index, done),
    },
    {
      name: 'open_case',
      description: 'Switch the app to a different case so the user is looking at it.',
      inputSchema: { type: 'object', properties: { caseId: { ...CASE_ID, description: 'Case to open' } }, required: ['caseId'] },
      execute: async ({ caseId }) => {
        if (!CASE_IDS.includes(caseId)) return { error: `Unknown case "${caseId}"` };
        window.briefOpenCase(caseId);
        return { opened: caseId };
      },
    },
  ];

  (async () => {
    for (const tool of TOOLS) {
      try { await mc.registerTool(tool); }
      catch (err) { console.warn('[webmcp] failed to register', tool.name, err?.message); }
    }
  })();
})();
