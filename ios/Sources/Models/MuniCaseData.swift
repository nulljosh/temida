import SwiftUI

// MARK: - CASE-0003
//
// Content is fetched at runtime from the Supabase `brief_data` table (key='cases',
// MUNI_* keys) — see Store.loadCaseData() and CaseDataMapper.swift. No hardcoded
// case content lives in source.

@MainActor var muniCaseFacts: [CaseFact] = []
@MainActor var muniCaseGrounds: [Ground] = []
@MainActor var muniCaseWitnesses: [Witness] = []
@MainActor var muniCaseLawyers: [Lawyer] = []
@MainActor var muniCaseTimeline: [TimelineStep] = []
@MainActor var muniCaseChecklist: [ChecklistItem] = []
@MainActor var muniCaseScenarios: [Scenario] = []
@MainActor var muniDamageHeads: [DamageHead] = []
@MainActor var muniCallScript: String = ""
